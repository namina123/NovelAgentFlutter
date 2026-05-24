import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'task_runtime_constants.dart';

class TaskChainViewService {
  JsonMap buildView(List<JsonMap> tasks, {String createdAt = ''}) {
    // 中文注释: 任务链视图服务只做 plan 分组、依赖判断和可读快照，不参与任何任务状态修改。
    final chains = _chainsFromTasks(tasks);
    return <String, Object?>{
      'ok': true,
      'chains': chains,
      'task_count': tasks.length,
      'created_at': createdAt.isEmpty
          ? DateTime.now().toIso8601String()
          : createdAt,
    };
  }

  String renderMarkdown(JsonMap view) {
    // 中文注释: Markdown 视图保留给 GUI 详情、CLI 和追踪文件共用，避免再散落第三套格式化规则。
    final lines = <String>[
      '# 任务链路快照',
      '',
      '- 快照 ID：${ValueReaders.stringValue(view['id'])}',
      '- 任务数：${ValueReaders.intValue(view['task_count'])}',
      '- 创建时间：${ValueReaders.stringValue(view['created_at'])}',
      '',
    ];
    final chains = ValueReaders.mapList(view['chains']);
    if (chains.isEmpty) {
      lines.add('当前项目没有任务。');
      return lines.join('\n');
    }
    for (final chain in chains) {
      final nodes = ValueReaders.mapList(chain['nodes']);
      lines.add('## ${ValueReaders.stringValue(chain['title'])}');
      lines.add('');
      lines.add('- 模式：${ValueReaders.stringValue(chain['mode'])}');
      lines.add('- 计划 ID：${ValueReaders.stringValue(chain['plan_id'])}');
      lines.add('- 任务数：${nodes.length}');
      lines.add(
        '- 下一可运行：${ValueReaders.stringValue(chain['next_runnable_title'], '无')}',
      );
      final blockers = ValueReaders.stringList(chain['blocking_checkpoints']);
      if (blockers.isNotEmpty) {
        lines.add('- 阻塞检查点：${blockers.join('、')}');
      }
      lines.add('');
      lines.add('### 节点');
      for (final node in nodes) {
        lines.add(
          '- ${ValueReaders.intValue(node['sort_order']).toString().padLeft(3, '0')}'
          '｜${ValueReaders.stringValue(node['status'])}'
          '｜${ValueReaders.stringValue(node['task_type'])}'
          '｜${ValueReaders.stringValue(node['title'])}',
        );
        final depends = ValueReaders.stringList(node['depends_on']);
        if (depends.isNotEmpty) {
          lines.add('  依赖：${depends.join('、')}');
        }
      }
      lines.add('');
    }
    return lines.join('\n');
  }

  List<JsonMap> _chainsFromTasks(List<JsonMap> tasks) {
    final byPlan = <String, List<JsonMap>>{};
    for (final task in tasks) {
      final metadata = ValueReaders.mapValue(task['metadata']);
      final planId =
          ValueReaders.stringValue(
            metadata['plan_id'],
            'loose_tasks',
          ).trim().isEmpty
          ? 'loose_tasks'
          : ValueReaders.stringValue(metadata['plan_id']);
      byPlan.putIfAbsent(planId, () => <JsonMap>[]).add(_nodeFromTask(task));
    }
    final chains = byPlan.entries
        .map((entry) => _chainRecord(entry.key, entry.value))
        .toList(growable: false);
    chains.sort((left, right) {
      return ValueReaders.stringValue(
        left['created_at'],
      ).compareTo(ValueReaders.stringValue(right['created_at']));
    });
    return chains;
  }

  JsonMap _nodeFromTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    return <String, Object?>{
      'id': ValueReaders.stringValue(task['id']),
      'title': ValueReaders.stringValue(task['title']),
      'task_type': ValueReaders.stringValue(task['task_type']),
      'mode': ValueReaders.stringValue(task['mode']),
      'status': ValueReaders.stringValue(task['status']),
      'relative_path': ValueReaders.stringValue(task['relative_path']),
      'depends_on': ValueReaders.stringList(task['depends_on']),
      'output_paths': ValueReaders.stringList(task['output_paths']),
      'sort_order': ValueReaders.intValue(metadata['sort_order']),
      'stage': ValueReaders.stringValue(metadata['stage']),
      'manual_checkpoint':
          ValueReaders.boolValue(metadata['manual_checkpoint']) ||
          ValueReaders.stringValue(task['task_type']) == 'checkpoint',
      'created_at': ValueReaders.stringValue(task['created_at']),
    };
  }

  JsonMap _chainRecord(String planId, List<JsonMap> nodes) {
    nodes.sort((left, right) {
      final orderCompare = ValueReaders.intValue(
        left['sort_order'],
      ).compareTo(ValueReaders.intValue(right['sort_order']));
      if (orderCompare != 0) {
        return orderCompare;
      }
      return ValueReaders.stringValue(
        left['created_at'],
      ).compareTo(ValueReaders.stringValue(right['created_at']));
    });
    final succeeded = <String, bool>{};
    for (final node in nodes) {
      if (ValueReaders.stringValue(node['status']) ==
          TaskRuntimeConstants.statusSucceeded) {
        succeeded[ValueReaders.stringValue(node['id'])] = true;
      }
    }
    JsonMap nextNode = const <String, Object?>{};
    final blockingCheckpoints = <String>[];
    for (final node in nodes) {
      if (ValueReaders.boolValue(node['manual_checkpoint']) &&
          ValueReaders.stringValue(node['status']) ==
              TaskRuntimeConstants.statusWaitingUser) {
        blockingCheckpoints.add(ValueReaders.stringValue(node['title']));
      }
      if (nextNode.isEmpty &&
          _isRunnableStatus(ValueReaders.stringValue(node['status'])) &&
          _dependenciesSatisfied(node, succeeded)) {
        nextNode = node;
      }
    }
    final firstNode = nodes.isEmpty ? const <String, Object?>{} : nodes.first;
    return <String, Object?>{
      'plan_id': planId,
      'title': planId == 'loose_tasks' ? '未分组任务' : '长任务计划 $planId',
      'mode': ValueReaders.stringValue(firstNode['mode']),
      'nodes': nodes,
      'next_runnable_id': ValueReaders.stringValue(nextNode['id']),
      'next_runnable_title': ValueReaders.stringValue(nextNode['title'], '无'),
      'blocking_checkpoints': blockingCheckpoints,
      'created_at': ValueReaders.stringValue(firstNode['created_at']),
    };
  }

  bool _dependenciesSatisfied(JsonMap node, Map<String, bool> succeeded) {
    for (final dependency in ValueReaders.stringList(node['depends_on'])) {
      if (succeeded[dependency] != true) {
        return false;
      }
    }
    return true;
  }

  bool _isRunnableStatus(String status) {
    return status == TaskRuntimeConstants.statusQueued ||
        status == TaskRuntimeConstants.statusRetrying;
  }
}
