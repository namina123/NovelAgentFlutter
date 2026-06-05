import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_run_compactor_service.dart';
import 'child_failure_disposition.dart';
import 'child_run_package.dart';
import 'collaboration_arbitration_result.dart';
import 'collaboration_conflict_record.dart';
import 'collaboration_result_package.dart';
import 'sub_agent_contract_components.dart';

class SubAgentResultPackageService {
  SubAgentResultPackageService({AgentRunCompactorService? compactorService})
    : _compactorService = compactorService ?? AgentRunCompactorService();

  final AgentRunCompactorService _compactorService;

  String subAgentFinalContent(
    String content, {
    required bool stoppedByToolError,
  }) {
    // 中文注释: 子智能体空回复需要有明确兜底文案，避免主智能体拿到一片空白难以判断。
    final cleanContent = content.trim();
    if (cleanContent.isEmpty && stoppedByToolError) {
      return '子智能体工具执行后未能生成最终回复。';
    }
    return cleanContent;
  }

  JsonMap subAgentSuccessResultPackage({
    required JsonMap package,
    required String task,
    required String content,
    required JsonMap llmResult,
    required List<Object?> executedTools,
    int attemptCount = 1,
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 成功结果返回给主智能体时只保留可合并字段，不把内部状态无限扩散。
    final subSessionId = ValueReaders.stringValue(package['sub_session_id']);
    final resultMarkdown = content.trim();
    final summary = _compactorService.clipResponseSummary(<String, Object?>{
      'result_markdown': resultMarkdown,
    });
    final collaborationPackage = _buildCollaborationResultPackage(
      package: package,
      task: task,
      status: 'success',
      retryable: false,
      cancelled: false,
      resultSummary: summary,
      resultMarkdown: resultMarkdown,
      executedTools: executedTools,
      metadata: <String, Object?>{
        'attempt_count': attemptCount,
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
    return <String, Object?>{
      'ok': true,
      'interaction_type': 'sub_agent_result',
      'strategy': ValueReaders.stringValue(
        package['strategy'],
        'main_with_children',
      ),
      'group_id': ValueReaders.stringValue(package['group_id']),
      'group_name': ValueReaders.stringValue(package['group_name']),
      'execution_package_id': collaborationPackage.executionPackageId,
      'child_run_package_id': collaborationPackage.childRunPackageId,
      'agent_id': collaborationPackage.agentId,
      'agent_name': collaborationPackage.agentName,
      'sub_session_id': subSessionId,
      'continue_session_id': collaborationPackage.continueSessionId,
      'task': task,
      'result_markdown': resultMarkdown,
      'summary': summary,
      'reasoning_content': ValueReaders.stringValue(
        llmResult['reasoning_content'],
      ),
      'tool_calls': ValueReaders.deepCopyList(executedTools),
      'collaboration_conflicts': collaborationPackage.conflicts
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'collaboration_arbitration_result': collaborationPackage.arbitrationResult
          .toJson(),
      'context_policy': ValueReaders.mapValue(package['context_policy']),
      'source_paths': ValueReaders.objectList(package['source_paths']),
      'execution_package': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(package['execution_package']),
      ),
      'child_run_package': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(package['child_run_package']),
      ),
      'available_children': ValueReaders.deepCopyList(
        ValueReaders.objectList(package['available_children']),
      ),
      'not_executed': false,
      'attempt_count': attemptCount,
      'sub_session_tag': '<sub_session_id>$subSessionId</sub_session_id>',
      'collaboration_result_package': collaborationPackage.toJson(),
    };
  }

  JsonMap subAgentFailureResultPackage({
    required JsonMap package,
    required String errorDetail,
    required List<Object?> executedTools,
    required bool cancelled,
    String failureDisposition = ChildFailureDispositions.retryChild,
    String failureCategory = 'model_failure',
    int attemptCount = 1,
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 失败结果显式标出是否可重试，方便主智能体或宿主继续决定恢复策略。
    var detail = errorDetail.trim();
    if (detail.isEmpty) {
      detail = cancelled
          ? 'Sub-agent run cancelled.'
          : 'Sub-agent model call failed.';
    }
    final summary = _failureSummary(
      errorDetail: detail,
      cancelled: cancelled,
      failureDisposition: failureDisposition,
      failureCategory: failureCategory,
    );
    final collaborationPackage = _buildCollaborationResultPackage(
      package: package,
      task: ValueReaders.stringValue(package['task']),
      status: cancelled ? 'cancelled' : 'failed',
      retryable:
          !cancelled &&
          failureDisposition == ChildFailureDispositions.retryChild,
      cancelled: cancelled,
      resultSummary: summary,
      resultMarkdown: '',
      executedTools: executedTools,
      metadata: <String, Object?>{
        'failure_disposition': failureDisposition,
        'failure_category': failureCategory,
        'attempt_count': attemptCount,
        'collaboration_failure_summary': summary,
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
    return <String, Object?>{
      'ok': false,
      'cancelled': cancelled,
      'error': cancelled
          ? 'Sub-agent run cancelled.'
          : 'Sub-agent model call failed: $detail',
      'group_id': ValueReaders.stringValue(package['group_id']),
      'group_name': ValueReaders.stringValue(package['group_name']),
      'execution_package_id': collaborationPackage.executionPackageId,
      'child_run_package_id': collaborationPackage.childRunPackageId,
      'agent_id': collaborationPackage.agentId,
      'agent_name': collaborationPackage.agentName,
      'sub_session_id': collaborationPackage.subSessionId,
      'continue_session_id': collaborationPackage.continueSessionId,
      'task': collaborationPackage.task,
      'tool_calls': ValueReaders.deepCopyList(executedTools),
      'retryable':
          !cancelled &&
          failureDisposition == ChildFailureDispositions.retryChild,
      'summary': summary,
      'failure_disposition': failureDisposition,
      'failure_category': failureCategory,
      'attempt_count': attemptCount,
      'execution_package': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(package['execution_package']),
      ),
      'child_run_package': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(package['child_run_package']),
      ),
      'available_children': ValueReaders.deepCopyList(
        ValueReaders.objectList(package['available_children']),
      ),
      'collaboration_conflicts': collaborationPackage.conflicts
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'collaboration_arbitration_result': collaborationPackage.arbitrationResult
          .toJson(),
      'collaboration_result_package': collaborationPackage.toJson(),
    };
  }

  CollaborationResultPackage _buildCollaborationResultPackage({
    required JsonMap package,
    required String task,
    required String status,
    required bool retryable,
    required bool cancelled,
    required String resultSummary,
    required String resultMarkdown,
    required List<Object?> executedTools,
    JsonMap metadata = const <String, Object?>{},
  }) {
    final childRun = ChildRunPackage.fromJson(
      ValueReaders.mapValue(package['child_run_package']),
    );
    final normalizedMetadata = ValueReaders.deepCopyMap(metadata);
    final conflicts = _normalizeConflictRecords(
      childRun: childRun,
      task: task,
      metadata: normalizedMetadata,
    );
    final arbitrationResult = _arbitrationResultFromMetadata(
      childRun: childRun,
      task: task,
      conflicts: conflicts,
      metadata: normalizedMetadata,
    );
    return CollaborationResultPackage(
      packageId:
          'collaboration_result_${childRun.packageId.isEmpty ? DateTime.now().microsecondsSinceEpoch : childRun.packageId}',
      executionPackageId: childRun.executionPackageId,
      childRunPackageId: childRun.packageId,
      strategy: childRun.strategy,
      agentId: childRun.agentId,
      agentName: childRun.agentName,
      subSessionId: childRun.subSessionId,
      continueSessionId: childRun.continueSessionId,
      task: task.trim().isEmpty ? childRun.goal.task : task.trim(),
      status: status,
      retryable: retryable,
      cancelled: cancelled,
      usedToolCount: executedTools.length,
      resultSummary: resultSummary.trim(),
      resultMarkdown: resultMarkdown.trim(),
      mergeContract: CollaborationMergeContract(
        mergeMode: 'main_agent_merges',
        parentReviewRequired: true,
        allowsDirectDelivery: false,
        acceptedResultTypes: const <String>[
          'conclusion',
          'risk',
          'suggestion',
          'draft_fragment',
        ],
        relationToWritingExecutionResult:
            'consumed_by_writing_execution_collaboration_summary',
        metadata: <String, Object?>{
          'execution_package_id': childRun.executionPackageId,
          'child_run_package_id': childRun.packageId,
        },
      ),
      conflicts: conflicts,
      arbitrationResult: arbitrationResult,
      metadata: <String, Object?>{
        'response_contract': childRun.responseContract,
        ...normalizedMetadata,
      },
    );
  }

  List<CollaborationConflictRecord> _normalizeConflictRecords({
    required ChildRunPackage childRun,
    required String task,
    required JsonMap metadata,
  }) {
    final rawConflicts = ValueReaders.objectList(
      metadata['collaboration_conflicts'],
    );
    final records = <CollaborationConflictRecord>[];
    if (rawConflicts.isEmpty && _hasInlineConflictFields(metadata)) {
      records.add(
        _conflictRecordFromMap(
          raw: metadata,
          childRun: childRun,
          task: task,
          index: 0,
        ),
      );
      return List<CollaborationConflictRecord>.unmodifiable(records);
    }
    for (var index = 0; index < rawConflicts.length; index += 1) {
      final rawMap = ValueReaders.mapValue(rawConflicts[index]);
      if (rawMap.isEmpty) {
        final summary = ValueReaders.stringValue(rawConflicts[index]).trim();
        if (summary.isEmpty) {
          continue;
        }
        records.add(
          _conflictRecordFromMap(
            raw: <String, Object?>{
              'suggestion': summary,
              'risk': CollaborationConflictRisks.low,
              'adoption_hint': 'review',
              'confidence': 0.5,
              'evidence': <Object?>[
                <String, Object?>{'summary': summary},
              ],
            },
            childRun: childRun,
            task: task,
            index: index,
          ),
        );
        continue;
      }
      records.add(
        _conflictRecordFromMap(
          raw: rawMap,
          childRun: childRun,
          task: task,
          index: index,
        ),
      );
    }
    return List<CollaborationConflictRecord>.unmodifiable(records);
  }

  CollaborationConflictRecord _conflictRecordFromMap({
    required JsonMap raw,
    required ChildRunPackage childRun,
    required String task,
    required int index,
  }) {
    final conflictId = ValueReaders.stringValue(
      raw['conflict_id'],
      'conflict_${childRun.packageId}_${index + 1}',
    ).trim();
    final evidence = _normalizeConflictEvidence(raw['evidence']);
    return CollaborationConflictRecord(
      conflictId: conflictId,
      groupKey: ValueReaders.stringValue(
        raw['group_key'],
        ValueReaders.stringValue(
          raw['conflict_key'],
          ValueReaders.stringValue(raw['subject']),
        ),
      ).trim(),
      subject: ValueReaders.stringValue(
        raw['subject'],
        ValueReaders.stringValue(raw['title'], task),
      ).trim(),
      target: ValueReaders.stringValue(raw['target']).trim(),
      agentId: ValueReaders.stringValue(
        raw['agent_id'],
        childRun.agentId,
      ).trim(),
      agentName: ValueReaders.stringValue(
        raw['agent_name'],
        childRun.agentName,
      ).trim(),
      task: ValueReaders.stringValue(raw['task'], task).trim(),
      risk: CollaborationConflictRisks.normalize(
        ValueReaders.stringValue(raw['risk']),
      ),
      suggestion: ValueReaders.stringValue(raw['suggestion']).trim(),
      adoptionHint: ValueReaders.stringValue(raw['adoption_hint']).trim(),
      confidence: ValueReaders.doubleValue(raw['confidence'], 0.5),
      evidence: List<CollaborationConflictEvidence>.unmodifiable(evidence),
      metadata: ValueReaders.deepCopyMap(_conflictMetadata(raw)),
    );
  }

  List<CollaborationConflictEvidence> _normalizeConflictEvidence(Object? raw) {
    final evidence = <CollaborationConflictEvidence>[];
    for (final item in ValueReaders.objectList(raw)) {
      final map = ValueReaders.mapValue(item);
      if (map.isNotEmpty) {
        evidence.add(CollaborationConflictEvidence.fromJson(map));
        continue;
      }
      final summary = ValueReaders.stringValue(item).trim();
      if (summary.isNotEmpty) {
        evidence.add(CollaborationConflictEvidence(summary: summary));
      }
    }
    return evidence;
  }

  JsonMap _conflictMetadata(JsonMap raw) {
    final metadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(raw['metadata']),
    );
    for (final key in const <String>[
      'modifies_long_term_rule',
      'updates_existing_rule',
      'overrides_active_information',
      'requires_user_confirmation',
    ]) {
      if (raw.containsKey(key)) {
        metadata[key] = raw[key];
      }
    }
    return metadata;
  }

  CollaborationArbitrationResult _arbitrationResultFromMetadata({
    required ChildRunPackage childRun,
    required String task,
    required List<CollaborationConflictRecord> conflicts,
    required JsonMap metadata,
  }) {
    final raw = ValueReaders.mapValue(
      metadata['collaboration_arbitration_result'],
    );
    if (raw.isNotEmpty) {
      return CollaborationArbitrationResult.fromJson(raw);
    }
    if (conflicts.isEmpty) {
      return const CollaborationArbitrationResult();
    }
    final highestRisk = _highestRisk(conflicts);
    final selected = _selectPreferredConflict(conflicts);
    final requiresUserConfirmation =
        highestRisk == CollaborationConflictRisks.high ||
        conflicts.any(
          (entry) => ValueReaders.boolValue(
            entry.metadata['requires_user_confirmation'],
          ),
        );
    final requiresRepair =
        !requiresUserConfirmation &&
        highestRisk == CollaborationConflictRisks.medium;
    final status = requiresUserConfirmation
        ? CollaborationArbitrationStatuses.needsUserConfirmation
        : requiresRepair
        ? CollaborationArbitrationStatuses.needsRepair
        : CollaborationArbitrationStatuses.autoResolved;
    final acceptedConflictIds = selected.conflictId.isEmpty
        ? const <String>[]
        : <String>[selected.conflictId];
    final rejectedConflictIds = conflicts
        .where((entry) => entry.conflictId != selected.conflictId)
        .map((entry) => entry.conflictId)
        .where((entry) => entry.trim().isNotEmpty)
        .toList(growable: false);
    return CollaborationArbitrationResult(
      arbitrationId: 'arbitration_${childRun.packageId}_${conflicts.length}',
      groupKey: ValueReaders.stringValue(
        selected.groupKey,
        ValueReaders.stringValue(selected.subject, task),
      ).trim(),
      status: status,
      highestRisk: highestRisk,
      selectedConflictId: selected.conflictId,
      summary: _defaultArbitrationSummary(
        status: status,
        selected: selected,
        groupSize: conflicts.length,
      ),
      reason: status == CollaborationArbitrationStatuses.needsUserConfirmation
          ? 'collaboration_conflict_needs_user_confirmation'
          : status == CollaborationArbitrationStatuses.needsRepair
          ? 'collaboration_conflict_needs_repair'
          : 'collaboration_conflict_auto_resolved',
      autoResolved: status == CollaborationArbitrationStatuses.autoResolved,
      requiresRepair: requiresRepair,
      requiresUserConfirmation: requiresUserConfirmation,
      acceptedConflictIds: acceptedConflictIds,
      rejectedConflictIds: rejectedConflictIds,
      pendingConflictIds:
          status == CollaborationArbitrationStatuses.autoResolved
          ? const <String>[]
          : conflicts
                .map((entry) => entry.conflictId)
                .where((entry) => entry.trim().isNotEmpty)
                .toList(growable: false),
      metadata: <String, Object?>{
        'conflict_count': conflicts.length,
        'selected_agent_name': selected.agentName,
        'selected_adoption_hint': selected.adoptionHint,
      },
    );
  }

  String _defaultArbitrationSummary({
    required String status,
    required CollaborationConflictRecord selected,
    required int groupSize,
  }) {
    final subject = selected.subject.trim().isEmpty ? '协作冲突' : selected.subject;
    if (status == CollaborationArbitrationStatuses.autoResolved) {
      return groupSize <= 1
          ? '低风险冲突已记录，可由主链按建议继续处理：$subject。'
          : '低风险冲突已按更高置信建议自动归并：$subject。';
    }
    if (status == CollaborationArbitrationStatuses.needsRepair) {
      return '协作冲突需要先修订再继续：$subject。';
    }
    return '协作冲突需要用户确认后再继续：$subject。';
  }

  CollaborationConflictRecord _selectPreferredConflict(
    List<CollaborationConflictRecord> conflicts,
  ) {
    return conflicts.reduce((best, current) {
      final currentRiskRank = CollaborationConflictRisks.rank(current.risk);
      final bestRiskRank = CollaborationConflictRisks.rank(best.risk);
      if (currentRiskRank > bestRiskRank) {
        return current;
      }
      if (currentRiskRank < bestRiskRank) {
        return best;
      }
      if (current.confidence > best.confidence) {
        return current;
      }
      return best;
    });
  }

  String _highestRisk(List<CollaborationConflictRecord> conflicts) {
    var highest = CollaborationConflictRisks.low;
    for (final conflict in conflicts) {
      if (CollaborationConflictRisks.rank(conflict.risk) >
          CollaborationConflictRisks.rank(highest)) {
        highest = conflict.risk;
      }
    }
    return highest;
  }

  bool _hasInlineConflictFields(JsonMap metadata) {
    return ValueReaders.stringValue(metadata['risk']).trim().isNotEmpty ||
        ValueReaders.stringValue(metadata['suggestion']).trim().isNotEmpty ||
        ValueReaders.stringValue(metadata['adoption_hint']).trim().isNotEmpty ||
        ValueReaders.objectList(metadata['evidence']).isNotEmpty ||
        metadata.containsKey('confidence');
  }

  String _failureSummary({
    required String errorDetail,
    required bool cancelled,
    required String failureDisposition,
    required String failureCategory,
  }) {
    if (cancelled) {
      return '子智能体运行已取消。';
    }
    final dispositionLabel = switch (failureDisposition) {
      ChildFailureDispositions.retryChild => '建议局部重试',
      ChildFailureDispositions.skipChild => '建议跳过该子智能体',
      ChildFailureDispositions.fallbackSingleMain => '建议退回单主链继续',
      ChildFailureDispositions.requireUser => '需要用户确认后继续',
      _ => failureDisposition,
    };
    final categoryLabel = switch (failureCategory) {
      'timeout' => '超时',
      'empty_response' => '空返回',
      'tool_error' => '工具错误',
      'budget_exhausted' => '预算耗尽',
      'waiting_user' => '需要用户交互',
      _ => '模型失败',
    };
    final detail = errorDetail.trim();
    if (detail.isEmpty) {
      return '子智能体$categoryLabel，$dispositionLabel。';
    }
    return '子智能体$categoryLabel，$dispositionLabel：$detail';
  }
}
