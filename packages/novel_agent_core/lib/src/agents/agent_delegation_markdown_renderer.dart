import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentDelegationMarkdownRenderer {
  String renderDelegationMarkdown(JsonMap plan) {
    // 中文注释: 这里把委派计划转成统一 Markdown，供 GUI 面板、CLI 和调试记录复用。
    final lines = <String>['# 智能体组委派预览', ''];
    if (!ValueReaders.boolValue(plan['ok'])) {
      lines.add('预览失败：${ValueReaders.stringValue(plan['error'], '未知错误')}');
      return lines.join('\n');
    }
    lines.add(
      '- 组别：${ValueReaders.stringValue(plan['group_name'])}'
      '｜${ValueReaders.stringValue(plan['group_id'])}',
    );
    lines.add(
      '- 编排：${ValueReaders.stringValue(plan['orchestration'], 'supervised')}',
    );
    final policy = ValueReaders.mapValue(plan['context_policy']);
    lines.add('- 上下文边界：${ValueReaders.stringValue(policy['description'])}');

    final warnings = ValueReaders.stringList(plan['warnings']);
    if (warnings.isNotEmpty) {
      lines
        ..add('')
        ..add('## 警告');
      for (final warning in warnings) {
        lines.add('- $warning');
      }
    }

    lines
      ..add('')
      ..add('## 子任务');
    final tasks = ValueReaders.mapList(plan['tasks']);
    if (tasks.isEmpty) {
      lines.add('暂无可用子任务。');
      return lines.join('\n');
    }
    for (final task in tasks) {
      lines.add(
        '- ${ValueReaders.stringValue(task['agent_name'])}'
        '｜${ValueReaders.stringValue(task['expected_output'])}'
        '：${ValueReaders.stringValue(task['task'])}',
      );
      final skills = ValueReaders.stringList(task['skills']);
      final groups = ValueReaders.stringList(task['skill_groups']);
      if (skills.isNotEmpty || groups.isNotEmpty) {
        lines.add(
          '  技能边界：${skills.isNotEmpty ? skills.join('、') : '无单独技能'} / '
          '${groups.isNotEmpty ? groups.join('、') : '无技能组'}',
        );
      }
    }
    return lines.join('\n');
  }
}
