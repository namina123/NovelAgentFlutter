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
    return ValueReaders.stringList(group['agents']).contains(requestedAgentId);
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
