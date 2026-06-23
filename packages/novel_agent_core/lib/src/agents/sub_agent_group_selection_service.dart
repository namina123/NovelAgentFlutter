import '../common/json_types.dart';
import '../common/value_readers.dart';

class SubAgentGroupSelectionService {
  JsonMap selectGroup({
    required JsonMap parentAgent,
    required String task,
    required List<JsonMap> availableGroups,
    String requestedAgentId = '',
    JsonMap preferredGroup = const <String, Object?>{},
  }) {
    // 中文注释: 子智能体协作组选择只做轻量规则分流，真正的委派与执行仍交给后续运行服务。
    final cleanRequestedAgentId = requestedAgentId.trim();
    if (availableGroups.isEmpty) {
      return ValueReaders.deepCopyMap(preferredGroup);
    }
    final preferredGroupId = ValueReaders.stringValue(
      preferredGroup['id'],
    ).trim();
    if (preferredGroupId.isNotEmpty) {
      for (final group in availableGroups) {
        if (ValueReaders.stringValue(group['id']).trim() != preferredGroupId) {
          continue;
        }
        if (_groupSupportsRequestedAgent(group, cleanRequestedAgentId)) {
          return ValueReaders.deepCopyMap(group);
        }
      }
    }
    if (preferredGroup.isNotEmpty) {
      if (_groupSupportsRequestedAgent(preferredGroup, cleanRequestedAgentId)) {
        return ValueReaders.deepCopyMap(preferredGroup);
      }
    }
    if (cleanRequestedAgentId.isNotEmpty) {
      for (final group in availableGroups) {
        if (_groupSupportsRequestedAgent(group, cleanRequestedAgentId)) {
          return ValueReaders.deepCopyMap(group);
        }
      }
    }
    if (preferredGroup.isNotEmpty) {
      return ValueReaders.deepCopyMap(preferredGroup);
    }
    final normalizedTask = task.trim().toLowerCase();
    final preferredGroupIds = <String>[
      if (_looksLikeReviewTask(normalizedTask)) 'optional_review_room',
      'optional_editorial_room',
      ValueReaders.stringValue(parentAgent['preferred_group_id']),
    ];
    for (final preferredId in preferredGroupIds) {
      if (preferredId.trim().isEmpty) {
        continue;
      }
      for (final group in availableGroups) {
        if (ValueReaders.stringValue(group['id']) == preferredId) {
          return ValueReaders.deepCopyMap(group);
        }
      }
    }
    return ValueReaders.deepCopyMap(availableGroups.first);
  }

  bool _groupSupportsRequestedAgent(JsonMap group, String requestedAgentId) {
    if (requestedAgentId.isEmpty) {
      return true;
    }
    // 中文注释: 匹配时归一化（小写 + 把 -/_ 视作等价），避免模型 emit 的 agent_id 与存储形式
    // （kebab vs snake、大小写漂移）不一致而静默匹配失败——这与技能 ID snake/kebab 不匹配同类。
    // 不改存储/路径用的 safeAgentId（那会动到既有索引路径），只在比对层归一化。
    final canonicalRequested = _canonicalAgentId(requestedAgentId);
    return ValueReaders.stringList(group['agents'])
        .any((agentId) => _canonicalAgentId(agentId) == canonicalRequested);
  }

  String _canonicalAgentId(String id) {
    return id.trim().toLowerCase().replaceAll('-', '_');
  }

  bool _looksLikeReviewTask(String task) {
    // 中文注释: 审稿类任务优先走较窄的审稿室，避免不必要地把正文作者也拉进来。
    return task.contains('审') ||
        task.contains('润色') ||
        task.contains('连续性') ||
        task.contains('文风') ||
        task.contains('读者') ||
        task.contains('检查') ||
        task.contains('修订');
  }
}
