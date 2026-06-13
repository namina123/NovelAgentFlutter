import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'review_authority_policy.dart';
import 'review_basis.dart';
import 'review_contract.dart';
import 'review_contract_catalog.dart';
import 'review_finding_contract.dart';
import 'review_reviewer_ref.dart';
import 'review_type_constants.dart';

class LongTaskCheckpointReviewContractMapperService {
  const LongTaskCheckpointReviewContractMapperService();

  ReviewContract mapReview({
    required JsonMap checkpointReview,
    String reviewType = ReviewTypeConstants.general,
    String createdAt = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    final reviewId = ValueReaders.stringValue(
      checkpointReview['id'],
      'long_task_checkpoint_review',
    ).trim();
    final disposition = _recommendedDisposition(checkpointReview);
    final riskLevel = _riskLevel(checkpointReview);
    final targetPaths = _targetPaths(checkpointReview);
    final sourcePaths = _sourcePaths(checkpointReview, targetPaths);
    final evidencePaths = _evidencePaths(
      checkpointReview,
      sourcePaths: sourcePaths,
      targetPaths: targetPaths,
    );
    final summary = _summary(checkpointReview, disposition);
    final authorityPolicy = ReviewAuthorityPolicy.longTask(
      metadata: <String, Object?>{
        'source': 'long_task_checkpoint_review_contract_mapper',
      },
    );
    return ReviewContract(
      reviewId: reviewId,
      reviewType: reviewType.trim().isEmpty
          ? ReviewTypeConstants.general
          : reviewType.trim(),
      reviewer: const ReviewReviewerRef(
        reviewerId: 'long_task_checkpoint_supervisor',
        reviewerRole: 'runtime_supervisor',
        label: '长任务检查点监督层',
      ),
      basis: ReviewBasis(
        basisType: 'long_task_checkpoint',
        summary: _basisSummary(checkpointReview),
        sourcePaths: sourcePaths,
        targetPaths: targetPaths,
        policyRefs: _policyRefs(checkpointReview),
        metadata: <String, Object?>{
          'task_id': ValueReaders.stringValue(
            ValueReaders.mapValue(checkpointReview['task'])['id'],
          ),
          'task_type': ValueReaders.stringValue(checkpointReview['task_type']),
          'stage': ValueReaders.stringValue(checkpointReview['stage']),
        },
      ),
      findings: _findings(
        checkpointReview,
        disposition: disposition,
        riskLevel: riskLevel,
      ),
      riskLevel: riskLevel,
      recommendedDisposition: disposition,
      repairBrief: _repairBrief(checkpointReview, disposition),
      summary: summary,
      evidencePaths: evidencePaths,
      createdAt: createdAt.trim().isEmpty
          ? ValueReaders.stringValue(checkpointReview['created_at']).trim()
          : createdAt.trim(),
      metadata: <String, Object?>{
        ...metadata,
        'origin': 'long_task_checkpoint_review_contract_mapper',
        'review_authority_policy': authorityPolicy.toJson(),
        'checkpoint_review_kind': ValueReaders.stringValue(
          checkpointReview['kind'],
          'long_task_checkpoint_review',
        ),
        'checkpoint_severity': ValueReaders.stringValue(
          checkpointReview['severity'],
        ),
        'checkpoint_disposition': ValueReaders.stringValue(
          ValueReaders.mapValue(
            checkpointReview['disposition'],
          )['disposition'],
          ValueReaders.stringValue(checkpointReview['continuation_disposition']),
        ),
        'checkpoint_reason': ValueReaders.stringValue(
          ValueReaders.mapValue(checkpointReview['disposition'])['reason'],
          ValueReaders.stringValue(checkpointReview['continuation_reason']),
        ),
        'followup_review_required': ValueReaders.boolValue(
          ValueReaders.mapValue(
            checkpointReview['disposition'],
          )['create_followup_review_tasks'],
        ),
        'revision_followup_required': ValueReaders.boolValue(
          ValueReaders.mapValue(
            checkpointReview['disposition'],
          )['request_revision_followup'],
        ),
      },
    );
  }

  List<ReviewFindingContract> _findings(
    JsonMap checkpointReview, {
    required String disposition,
    required String riskLevel,
  }) {
    final result = <ReviewFindingContract>[];
    final severity = _findingSeverity(disposition);
    final collaborationSignal = ValueReaders.mapValue(
      checkpointReview['collaboration_signal'],
    );
    final informationSignal = ValueReaders.mapValue(
      checkpointReview['information_signal'],
    );
    final expressionSignal = ValueReaders.mapValue(
      checkpointReview['expression_constraint_signal'],
    );
    final summary = ValueReaders.stringValue(checkpointReview['summary']).trim();

    _appendFinding(
      result,
      findingId: 'checkpoint_collaboration',
      summary: ValueReaders.stringValue(collaborationSignal['summary']),
      severity: _signalSeverity(
        disposition,
        category: ValueReaders.stringValue(collaborationSignal['category']),
      ),
      suggestedAction: _suggestedAction(disposition),
      evidencePaths: ValueReaders.stringList(
        checkpointReview['output_paths'],
      ),
    );
    _appendFinding(
      result,
      findingId: 'checkpoint_information',
      summary: ValueReaders.stringValue(informationSignal['summary']),
      severity: _signalSeverity(
        disposition,
        category: ValueReaders.stringValue(informationSignal['category']),
      ),
      suggestedAction: _suggestedAction(disposition),
      evidencePaths: _unique(<String>[
        ...ValueReaders.stringList(checkpointReview['output_paths']),
        ...ValueReaders.stringList(
          checkpointReview['information_changed_paths'],
        ),
      ]),
    );
    _appendFinding(
      result,
      findingId: 'checkpoint_expression_constraint',
      summary: ValueReaders.stringValue(expressionSignal['summary']),
      severity: ValueReaders.boolValue(expressionSignal['repair_required'])
          ? ReviewFindingSeverities.blocking
          : severity,
      suggestedAction: _suggestedAction(disposition),
      evidencePaths: ValueReaders.stringList(checkpointReview['output_paths']),
    );

    final severityReasons = ValueReaders.stringList(
      checkpointReview['severity_reasons'],
    );
    for (var index = 0; index < severityReasons.length; index += 1) {
      final reason = severityReasons[index].trim();
      if (reason.isEmpty) {
        continue;
      }
      result.add(
        ReviewFindingContract(
          findingId: 'checkpoint_severity_reason_${index + 1}',
          severity: severity,
          summary: reason,
          suggestedAction: _suggestedAction(disposition),
          evidencePaths: ValueReaders.stringList(checkpointReview['output_paths']),
        ),
      );
    }

    if (result.isEmpty && summary.isNotEmpty) {
      result.add(
        ReviewFindingContract(
          findingId: 'checkpoint_summary',
          severity: riskLevel == ReviewRiskLevels.none
              ? ReviewFindingSeverities.info
              : severity,
          summary: summary,
          suggestedAction: _suggestedAction(disposition),
          evidencePaths: ValueReaders.stringList(checkpointReview['output_paths']),
        ),
      );
    }

    return List<ReviewFindingContract>.unmodifiable(result);
  }

  void _appendFinding(
    List<ReviewFindingContract> target, {
    required String findingId,
    required String summary,
    required String severity,
    required String suggestedAction,
    required List<String> evidencePaths,
  }) {
    final cleanSummary = summary.trim();
    if (cleanSummary.isEmpty) {
      return;
    }
    target.add(
      ReviewFindingContract(
        findingId: findingId,
        severity: severity,
        summary: cleanSummary,
        suggestedAction: suggestedAction,
        evidencePaths: evidencePaths,
      ),
    );
  }

  String _recommendedDisposition(JsonMap checkpointReview) {
    final disposition = ValueReaders.stringValue(
      checkpointReview['continuation_disposition'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(checkpointReview['disposition'])['disposition'],
      ),
    ).trim();
    final dispositionDetails = ValueReaders.mapValue(checkpointReview['disposition']);
    final informationCategory = ValueReaders.stringValue(
      ValueReaders.mapValue(checkpointReview['information_signal'])['category'],
    ).trim();
    final collaborationCategory = ValueReaders.stringValue(
      ValueReaders.mapValue(checkpointReview['collaboration_signal'])['category'],
    ).trim();
    if (disposition == 'manual_attention') {
      return ReviewRecommendedDispositions.manualAttention;
    }
    if (disposition == 'blocked_wait_user') {
      if (_isUserCheckpointCategory(informationCategory) ||
          _isUserCheckpointCategory(collaborationCategory)) {
        return ReviewRecommendedDispositions.checkpointUser;
      }
      if (ValueReaders.boolValue(dispositionDetails['request_revision_followup']) ||
          informationCategory == 'repair' ||
          collaborationCategory == 'repair' ||
          ValueReaders.boolValue(
            ValueReaders.mapValue(
              checkpointReview['expression_constraint_signal'],
            )['repair_required'],
          )) {
        return ReviewRecommendedDispositions.repair;
      }
      if (ValueReaders.boolValue(dispositionDetails['create_followup_review_tasks'])) {
        return ReviewRecommendedDispositions.adjustNext;
      }
      return ReviewRecommendedDispositions.checkpointUser;
    }
    return ReviewRecommendedDispositions.accept;
  }

  bool _isUserCheckpointCategory(String category) {
    return category.trim() == 'checkpoint_user';
  }

  String _riskLevel(JsonMap checkpointReview) {
    final severity = ValueReaders.stringValue(
      checkpointReview['severity'],
    ).trim();
    switch (severity) {
      case 'critical':
        return ReviewRiskLevels.critical;
      case 'high':
        return ReviewRiskLevels.high;
      case 'medium':
        return ReviewRiskLevels.medium;
      case 'low':
        return ReviewRiskLevels.low;
    }
    final disposition = ValueReaders.stringValue(
      checkpointReview['continuation_disposition'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(checkpointReview['disposition'])['disposition'],
      ),
    ).trim();
    if (disposition == 'manual_attention') {
      return ReviewRiskLevels.critical;
    }
    if (disposition == 'blocked_wait_user') {
      return ReviewRiskLevels.high;
    }
    return ReviewRiskLevels.none;
  }

  String _repairBrief(JsonMap checkpointReview, String disposition) {
    if (disposition != ReviewRecommendedDispositions.repair) {
      return '';
    }
    final informationSummary = ValueReaders.stringValue(
      ValueReaders.mapValue(checkpointReview['information_signal'])['summary'],
    ).trim();
    if (informationSummary.isNotEmpty) {
      return informationSummary;
    }
    final collaborationSummary = ValueReaders.stringValue(
      ValueReaders.mapValue(
        checkpointReview['collaboration_signal'],
      )['summary'],
    ).trim();
    if (collaborationSummary.isNotEmpty) {
      return collaborationSummary;
    }
    final summary = ValueReaders.stringValue(checkpointReview['summary']).trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    return '当前检查点要求先完成返修或后续复核，再恢复长任务主链。';
  }

  String _summary(JsonMap checkpointReview, String disposition) {
    final summary = ValueReaders.stringValue(checkpointReview['summary']).trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    switch (disposition) {
      case ReviewRecommendedDispositions.manualAttention:
        return '当前检查点风险已进入人工处理范围。';
      case ReviewRecommendedDispositions.checkpointUser:
        return '当前检查点仍需用户确认后才能继续。';
      case ReviewRecommendedDispositions.repair:
        return '当前检查点建议先完成返修或补充复核，再恢复长任务主链。';
      case ReviewRecommendedDispositions.adjustNext:
        return '当前检查点建议先插入后续复核，再继续推进长任务队列。';
      default:
        return '当前检查点风险较低，可继续推进长任务主链。';
    }
  }

  String _basisSummary(JsonMap checkpointReview) {
    final taskSummary = ValueReaders.mapValue(checkpointReview['task']);
    final taskTitle = ValueReaders.stringValue(taskSummary['title']).trim();
    final taskType = ValueReaders.stringValue(
      checkpointReview['task_type'],
      ValueReaders.stringValue(taskSummary['task_type']),
    ).trim();
    final severity = ValueReaders.stringValue(checkpointReview['severity']).trim();
    final disposition = ValueReaders.stringValue(
      ValueReaders.mapValue(checkpointReview['disposition'])['disposition'],
      ValueReaders.stringValue(checkpointReview['continuation_disposition']),
    ).trim();
    final outputCount = ValueReaders.stringList(
      checkpointReview['output_paths'],
    ).length;
    return '基于长任务 checkpoint review 生成共享审稿合同。'
        ' task=${taskTitle.isEmpty ? taskType : taskTitle}'
        ' severity=${severity.isEmpty ? 'unknown' : severity}'
        ' disposition=${disposition.isEmpty ? 'unknown' : disposition}'
        ' outputs=$outputCount';
  }

  List<String> _policyRefs(JsonMap checkpointReview) {
    return _unique(<String>[
      'review_trigger:${ReviewTriggerAuthorities.runtimeSupervisorPolicy}',
      'checkpoint_severity:${ValueReaders.stringValue(checkpointReview['severity'])}',
      'checkpoint_disposition:${ValueReaders.stringValue(ValueReaders.mapValue(checkpointReview['disposition'])['disposition'])}',
      'checkpoint_reason:${ValueReaders.stringValue(ValueReaders.mapValue(checkpointReview['disposition'])['reason'])}',
    ]);
  }

  List<String> _targetPaths(JsonMap checkpointReview) {
    return _unique(ValueReaders.stringList(checkpointReview['output_paths']));
  }

  List<String> _sourcePaths(JsonMap checkpointReview, List<String> targetPaths) {
    return _unique(<String>[
      ...ValueReaders.stringList(checkpointReview['persistent_context_paths']),
      ...ValueReaders.stringList(checkpointReview['changed_paths']),
      ...targetPaths,
    ]);
  }

  List<String> _evidencePaths(
    JsonMap checkpointReview, {
    required List<String> sourcePaths,
    required List<String> targetPaths,
  }) {
    final result = _unique(<String>[
      ValueReaders.stringValue(checkpointReview['json_path']),
      ValueReaders.stringValue(checkpointReview['markdown_path']),
      ...ValueReaders.stringList(checkpointReview['information_changed_paths']),
      ...ValueReaders.stringList(checkpointReview['changed_paths']),
      ...targetPaths,
      ...sourcePaths,
    ]);
    if (result.isNotEmpty) {
      return result;
    }
    final reviewId = ValueReaders.stringValue(checkpointReview['id']).trim();
    return <String>[
      reviewId.isEmpty ? 'tracking/checkpoint_reviews/unknown' : reviewId,
    ];
  }

  String _findingSeverity(String disposition) {
    switch (disposition) {
      case ReviewRecommendedDispositions.manualAttention:
      case ReviewRecommendedDispositions.repair:
      case ReviewRecommendedDispositions.checkpointUser:
        return ReviewFindingSeverities.blocking;
      case ReviewRecommendedDispositions.adjustNext:
        return ReviewFindingSeverities.high;
      case ReviewRecommendedDispositions.remind:
        return ReviewFindingSeverities.medium;
      default:
        return ReviewFindingSeverities.info;
    }
  }

  String _signalSeverity(String disposition, {required String category}) {
    final cleanCategory = category.trim();
    if (cleanCategory == 'repair' || cleanCategory == 'checkpoint_user') {
      return ReviewFindingSeverities.blocking;
    }
    return _findingSeverity(disposition);
  }

  String _suggestedAction(String disposition) {
    switch (disposition) {
      case ReviewRecommendedDispositions.manualAttention:
        return '暂停主链，等待人工处理当前检查点风险。';
      case ReviewRecommendedDispositions.checkpointUser:
        return '等待用户确认当前检查点，再决定是否继续主链。';
      case ReviewRecommendedDispositions.repair:
        return '先完成返修或补充复核，再恢复长任务主链。';
      case ReviewRecommendedDispositions.adjustNext:
        return '先插入后续复核任务，再继续推进后续章节或检查点。';
      default:
        return '记录当前检查点结论并继续。';
    }
  }

  List<String> _unique(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final clean = value.trim().replaceAll('\\', '/');
      if (clean.isEmpty || result.contains(clean)) {
        continue;
      }
      result.add(clean);
    }
    return List<String>.unmodifiable(result);
  }
}
