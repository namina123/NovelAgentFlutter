import '../common/json_types.dart';
import '../common/value_readers.dart';

class OpeningIntentSnapshot {
  const OpeningIntentSnapshot({
    this.resolvedAgentGroupId = '',
    this.availableAgentGroupIds = const <String>[],
    this.runtimeBaselineId = '',
    this.modeId = '',
    this.sessionGoalModeId = '',
    this.freeTextIntent = '',
    this.metadata = const <String, Object?>{},
  });

  final String resolvedAgentGroupId;
  final List<String> availableAgentGroupIds;
  final String runtimeBaselineId;
  final String modeId;
  final String sessionGoalModeId;
  final String freeTextIntent;
  final JsonMap metadata;

  bool get hasResolvedAgentGroup => resolvedAgentGroupId.trim().isNotEmpty;

  bool get hasConversationGoal => sessionGoalModeId.trim().isNotEmpty;

  bool get hasFreeTextIntent => freeTextIntent.trim().isNotEmpty;

  OpeningIntentSnapshot copyWith({
    String? resolvedAgentGroupId,
    List<String>? availableAgentGroupIds,
    String? runtimeBaselineId,
    String? modeId,
    String? sessionGoalModeId,
    String? freeTextIntent,
    JsonMap? metadata,
  }) {
    // 中文注释: opening 意图快照保持不可变，方便后续 app 在不同事件源之间安全合并。
    return OpeningIntentSnapshot(
      resolvedAgentGroupId: resolvedAgentGroupId ?? this.resolvedAgentGroupId,
      availableAgentGroupIds:
          availableAgentGroupIds ?? this.availableAgentGroupIds,
      runtimeBaselineId: runtimeBaselineId ?? this.runtimeBaselineId,
      modeId: modeId ?? this.modeId,
      sessionGoalModeId: sessionGoalModeId ?? this.sessionGoalModeId,
      freeTextIntent: freeTextIntent ?? this.freeTextIntent,
      metadata: metadata ?? this.metadata,
    );
  }

  JsonMap toJsonMap() {
    return <String, Object?>{
      'resolved_agent_group_id': resolvedAgentGroupId,
      'available_agent_group_ids': ValueReaders.deepCopyList(
        availableAgentGroupIds.cast<Object?>(),
      ),
      'runtime_baseline_id': runtimeBaselineId,
      'mode_id': modeId,
      'session_goal_mode_id': sessionGoalModeId,
      'free_text_intent': freeTextIntent,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OpeningIntentSnapshot fromJsonMap(JsonMap document) {
    return OpeningIntentSnapshot(
      resolvedAgentGroupId: ValueReaders.stringValue(
        document['resolved_agent_group_id'],
      ).trim(),
      availableAgentGroupIds: ValueReaders.stringList(
        document['available_agent_group_ids'],
      ),
      runtimeBaselineId: ValueReaders.stringValue(
        document['runtime_baseline_id'],
      ).trim(),
      modeId: ValueReaders.stringValue(document['mode_id']).trim(),
      sessionGoalModeId: ValueReaders.stringValue(
        document['session_goal_mode_id'],
      ).trim(),
      freeTextIntent: ValueReaders.stringValue(
        document['free_text_intent'],
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['metadata']),
      ),
    );
  }
}
