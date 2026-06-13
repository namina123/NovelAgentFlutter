import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../agents/collaboration_arbitration_result.dart';
import '../agents/collaboration_conflict_record.dart';

class WritingExecutionCollaboratorSummary {
  const WritingExecutionCollaboratorSummary({
    this.agentId = '',
    this.agentName = '',
    this.status = '',
    this.task = '',
    this.retryable = false,
    this.usedToolCount = 0,
    this.resultSummary = '',
    this.metadata = const <String, Object?>{},
  });

  final String agentId;
  final String agentName;
  final String status;
  final String task;
  final bool retryable;
  final int usedToolCount;
  final String resultSummary;
  final JsonMap metadata;

  factory WritingExecutionCollaboratorSummary.fromJson(JsonMap json) {
    // 中文注释: 单个协作者摘要保持极简，后续只拿它解释“谁做了什么、结果怎样”。
    return WritingExecutionCollaboratorSummary(
      agentId: ValueReaders.stringValue(json['agent_id']).trim(),
      agentName: ValueReaders.stringValue(json['agent_name']).trim(),
      status: ValueReaders.stringValue(json['status']).trim(),
      task: ValueReaders.stringValue(json['task']).trim(),
      retryable: ValueReaders.boolValue(json['retryable']),
      usedToolCount: ValueReaders.intValue(json['used_tool_count']),
      resultSummary: ValueReaders.stringValue(json['result_summary']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 子摘要输出稳定字段，避免把整个 sub-agent package 继续散发到上层。
    return <String, Object?>{
      'agent_id': agentId,
      'agent_name': agentName,
      'status': status,
      'task': task,
      'retryable': retryable,
      'used_tool_count': usedToolCount,
      'result_summary': resultSummary,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 协作者摘要只校验最小身份与状态，避免把协作者策略规则塞进这里。
    final result = <String>[];
    if (agentId.trim().isEmpty && agentName.trim().isEmpty) {
      result.add('missing_writing_execution_collaborator_identity');
    }
    if (status.trim().isEmpty) {
      result.add('missing_writing_execution_collaborator_status');
    }
    if (usedToolCount < 0) {
      result.add('invalid_writing_execution_collaborator_tool_count');
    }
    return result;
  }
}

class WritingExecutionCollaborationSummary {
  const WritingExecutionCollaborationSummary({
    this.present = false,
    this.strategy = '',
    this.totalCollaboratorCount = 0,
    this.successfulCollaboratorCount = 0,
    this.failedCollaboratorCount = 0,
    this.blockingFailureCount = 0,
    this.cancelledCollaboratorCount = 0,
    this.retryableFailureCount = 0,
    this.retryChildCount = 0,
    this.skipChildCount = 0,
    this.fallbackSingleMainCount = 0,
    this.requireUserCount = 0,
    this.totalConflictCount = 0,
    this.autoResolvedConflictCount = 0,
    this.repairRequiredConflictCount = 0,
    this.userConfirmationConflictCount = 0,
    this.degraded = false,
    this.highestConflictRisk = '',
    this.summary = '',
    this.failureSummary = '',
    this.conflictSummary = '',
    this.agentNames = const <String>[],
    this.failedAgentNames = const <String>[],
    this.collaborators = const <WritingExecutionCollaboratorSummary>[],
    this.conflicts = const <CollaborationConflictRecord>[],
    this.arbitrationResults = const <CollaborationArbitrationResult>[],
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String strategy;
  final int totalCollaboratorCount;
  final int successfulCollaboratorCount;
  final int failedCollaboratorCount;
  final int blockingFailureCount;
  final int cancelledCollaboratorCount;
  final int retryableFailureCount;
  final int retryChildCount;
  final int skipChildCount;
  final int fallbackSingleMainCount;
  final int requireUserCount;
  final int totalConflictCount;
  final int autoResolvedConflictCount;
  final int repairRequiredConflictCount;
  final int userConfirmationConflictCount;
  final bool degraded;
  final String highestConflictRisk;
  final String summary;
  final String failureSummary;
  final String conflictSummary;
  final List<String> agentNames;
  final List<String> failedAgentNames;
  final List<WritingExecutionCollaboratorSummary> collaborators;
  final List<CollaborationConflictRecord> conflicts;
  final List<CollaborationArbitrationResult> arbitrationResults;
  final JsonMap metadata;

  factory WritingExecutionCollaborationSummary.fromJson(JsonMap json) {
    // 中文注释: collaboration summary 回读后应能直接给 GUI/CLI 用，不要求它理解 sub-agent 原始包结构。
    final failedCollaboratorCount = ValueReaders.intValue(
      json['failed_collaborator_count'],
    );
    final blockingFailureCount = json.containsKey('blocking_failure_count')
        ? ValueReaders.intValue(json['blocking_failure_count'])
        : failedCollaboratorCount;
    return WritingExecutionCollaborationSummary(
      present: ValueReaders.boolValue(json['present']),
      strategy: ValueReaders.stringValue(json['strategy']).trim(),
      totalCollaboratorCount: ValueReaders.intValue(
        json['total_collaborator_count'],
      ),
      successfulCollaboratorCount: ValueReaders.intValue(
        json['successful_collaborator_count'],
      ),
      failedCollaboratorCount: failedCollaboratorCount,
      blockingFailureCount: blockingFailureCount,
      cancelledCollaboratorCount: ValueReaders.intValue(
        json['cancelled_collaborator_count'],
      ),
      retryableFailureCount: ValueReaders.intValue(
        json['retryable_failure_count'],
      ),
      retryChildCount: ValueReaders.intValue(json['retry_child_count']),
      skipChildCount: ValueReaders.intValue(json['skip_child_count']),
      fallbackSingleMainCount: ValueReaders.intValue(
        json['fallback_single_main_count'],
      ),
      requireUserCount: ValueReaders.intValue(json['require_user_count']),
      totalConflictCount: ValueReaders.intValue(json['total_conflict_count']),
      autoResolvedConflictCount: ValueReaders.intValue(
        json['auto_resolved_conflict_count'],
      ),
      repairRequiredConflictCount: ValueReaders.intValue(
        json['repair_required_conflict_count'],
      ),
      userConfirmationConflictCount: ValueReaders.intValue(
        json['user_confirmation_conflict_count'],
      ),
      degraded: ValueReaders.boolValue(json['degraded']),
      highestConflictRisk: ValueReaders.stringValue(
        json['highest_conflict_risk'],
      ).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      failureSummary: ValueReaders.stringValue(json['failure_summary']).trim(),
      conflictSummary: ValueReaders.stringValue(
        json['conflict_summary'],
      ).trim(),
      agentNames: ValueReaders.stringList(json['agent_names']),
      failedAgentNames: ValueReaders.stringList(json['failed_agent_names']),
      collaborators: ValueReaders.mapList(json['collaborators'])
          .map(WritingExecutionCollaboratorSummary.fromJson)
          .toList(growable: false),
      conflicts: ValueReaders.mapList(
        json['conflicts'],
      ).map(CollaborationConflictRecord.fromJson).toList(growable: false),
      arbitrationResults: ValueReaders.mapList(
        json['arbitration_results'],
      ).map(CollaborationArbitrationResult.fromJson).toList(growable: false),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 协作摘要只输出结果归因所需字段，不把完整子会话 transcript 混入共享结果合同。
    return <String, Object?>{
      'present': present,
      'strategy': strategy,
      'total_collaborator_count': totalCollaboratorCount,
      'successful_collaborator_count': successfulCollaboratorCount,
      'failed_collaborator_count': failedCollaboratorCount,
      'blocking_failure_count': blockingFailureCount,
      'cancelled_collaborator_count': cancelledCollaboratorCount,
      'retryable_failure_count': retryableFailureCount,
      'retry_child_count': retryChildCount,
      'skip_child_count': skipChildCount,
      'fallback_single_main_count': fallbackSingleMainCount,
      'require_user_count': requireUserCount,
      'total_conflict_count': totalConflictCount,
      'auto_resolved_conflict_count': autoResolvedConflictCount,
      'repair_required_conflict_count': repairRequiredConflictCount,
      'user_confirmation_conflict_count': userConfirmationConflictCount,
      'degraded': degraded,
      'highest_conflict_risk': highestConflictRisk,
      'summary': summary,
      'failure_summary': failureSummary,
      'conflict_summary': conflictSummary,
      'agent_names': agentNames,
      'failed_agent_names': failedAgentNames,
      'collaborators': collaborators
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'conflicts': conflicts
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'arbitration_results': arbitrationResults
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 协作摘要校验只检查计数是否自洽，避免在合同层重做协作者预算或权限判断。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (totalCollaboratorCount < 0 ||
        successfulCollaboratorCount < 0 ||
        failedCollaboratorCount < 0 ||
        blockingFailureCount < 0 ||
        cancelledCollaboratorCount < 0 ||
        retryableFailureCount < 0 ||
        retryChildCount < 0 ||
        skipChildCount < 0 ||
        fallbackSingleMainCount < 0 ||
        requireUserCount < 0 ||
        totalConflictCount < 0 ||
        autoResolvedConflictCount < 0 ||
        repairRequiredConflictCount < 0 ||
        userConfirmationConflictCount < 0) {
      result.add('invalid_writing_execution_collaboration_counts');
    }
    if (collaborators.expand((entry) => entry.validateBasics()).isNotEmpty) {
      result.add('invalid_writing_execution_collaboration_children');
    }
    if (conflicts.expand((entry) => entry.validateBasics()).isNotEmpty) {
      result.add('invalid_writing_execution_collaboration_conflicts');
    }
    if (arbitrationResults
        .expand((entry) => entry.validateBasics())
        .isNotEmpty) {
      result.add('invalid_writing_execution_collaboration_arbitration');
    }
    return result;
  }
}
