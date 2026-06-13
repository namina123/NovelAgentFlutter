import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_semantic_review.dart';
import '../continuity/narrative_state/semantic_review_recommended_disposition.dart';
import '../continuity/narrative_state/semantic_review_severity.dart';
import '../tools/domain/domain_tool_outcome_statuses.dart';
import '../tools/domain/narrative_domain_tool_names.dart';
import 'chapter_delivery_state_statuses.dart';
import 'expression_constraint_supervisor_signal_service.dart';
import 'information_evidence_gate_signal.dart';
import 'writing_execution_constraint_summary.dart';

class NarrativeSupervisorRiskPolicyService {
  const NarrativeSupervisorRiskPolicyService({
    ExpressionConstraintSupervisorSignalService?
    expressionConstraintSupervisorSignalService,
  }) : _expressionConstraintSupervisorSignalService =
           expressionConstraintSupervisorSignalService ??
           const ExpressionConstraintSupervisorSignalService();

  final ExpressionConstraintSupervisorSignalService
  _expressionConstraintSupervisorSignalService;

  JsonMap assess({
    required JsonMap result,
    JsonMap execution = const <String, Object?>{},
    JsonMap expressionConstraintSignal = const <String, Object?>{},
  }) {
    // 中文注释: supervisor 风险策略只消费结构化 runtime/tool 结果，不读取正文也不判断题材语义。
    final delivery = _deliverySignal(result, execution);
    final review = _reviewSignal(result, execution);
    final permission = _permissionSignal(result, execution);
    final information = _informationSignal(result, execution);
    final expressionConstraints = expressionConstraintSignal.isNotEmpty
        ? ValueReaders.deepCopyMap(expressionConstraintSignal)
        : _expressionConstraintSignal(result, execution);
    final overall = _overallSignal(
      delivery: delivery,
      review: review,
      permission: permission,
      information: information,
      expressionConstraints: expressionConstraints,
    );
    return <String, Object?>{
      'delivery': delivery,
      'review': review,
      'permission': permission,
      'information': information,
      'expression_constraints': expressionConstraints,
      'overall': overall,
    };
  }

  JsonMap _deliverySignal(JsonMap result, JsonMap execution) {
    final chapterDelivery = ValueReaders.mapValue(
      execution['chapter_delivery'],
    );
    final latestToolDelivery = _latestChapterDeliveryPayload(result);
    final source = chapterDelivery.isNotEmpty
        ? chapterDelivery
        : latestToolDelivery;
    final state = ValueReaders.stringValue(
      source['delivery_state'],
      ValueReaders.stringValue(execution['chapter_delivery_state']),
    ).trim();
    final reason = ValueReaders.stringValue(
      ValueReaders.mapValue(source['state_result'])['reason'],
    ).trim();
    final category = switch (state) {
      ChapterDeliveryStateStatuses.delivered => 'accept',
      ChapterDeliveryStateStatuses.deliveredNeedsRepair ||
      ChapterDeliveryStateStatuses.missingOutputRecoverable ||
      ChapterDeliveryStateStatuses.pathMismatchRecoverable => 'repair',
      ChapterDeliveryStateStatuses.waitingUserChoice => 'checkpoint_user',
      ChapterDeliveryStateStatuses.invalidOutputRewriteRequired ||
      ChapterDeliveryStateStatuses.manualAttentionRequired ||
      ChapterDeliveryStateStatuses.hardFailure => 'manual_attention',
      _ => '',
    };
    return <String, Object?>{
      'present': state.isNotEmpty,
      'state': state,
      'reason': reason,
      'category': category,
      'chapter_path': ValueReaders.stringValue(source['chapter_path']),
      'chapter_body_state': ValueReaders.stringValue(
        source['chapter_body_state'],
      ),
      'sidecar_state': ValueReaders.stringValue(source['sidecar_state']),
      'waiting_user': category == 'checkpoint_user',
      'manual_attention_required': category == 'manual_attention',
      'requires_repair': category == 'repair',
    };
  }

  JsonMap _reviewSignal(JsonMap result, JsonMap execution) {
    final reviewJson = _latestSemanticReviewJson(result, execution);
    if (reviewJson.isEmpty) {
      return const <String, Object?>{
        'present': false,
        'category': '',
        'blocking_finding_count': 0,
        'high_finding_count': 0,
        'questioned_claim_count': 0,
        'accepted_claim_count': 0,
      };
    }
    final review = NarrativeSemanticReview.fromJson(reviewJson);
    final blockingCount = review.findings
        .where((finding) => finding.severity == SemanticReviewSeverity.blocking)
        .length;
    final highCount = review.findings
        .where(
          (finding) =>
              finding.severity == SemanticReviewSeverity.high ||
              finding.severity == SemanticReviewSeverity.blocking,
        )
        .length;
    final mediumOrHigherCount = review.findings
        .where(
          (finding) =>
              finding.severity == SemanticReviewSeverity.medium ||
              finding.severity == SemanticReviewSeverity.high ||
              finding.severity == SemanticReviewSeverity.blocking,
        )
        .length;
    var category = switch (review.recommendedDisposition) {
      SemanticReviewRecommendedDisposition.manualAttention =>
        'manual_attention',
      SemanticReviewRecommendedDisposition.checkpointUser => 'checkpoint_user',
      SemanticReviewRecommendedDisposition.repair => 'repair',
      _ => 'accept',
    };
    if (category == 'accept' && highCount > 0) {
      category = 'repair';
    }
    if (category == 'accept' &&
        review.questionedClaimIds.isNotEmpty &&
        mediumOrHigherCount > 0) {
      category = 'checkpoint_user';
    }
    return <String, Object?>{
      'present': true,
      'review_id': review.reviewId,
      'recommended_disposition': review.recommendedDisposition.id,
      'category': category,
      'summary': review.summary,
      'blocking_finding_count': blockingCount,
      'high_finding_count': highCount,
      'medium_or_higher_finding_count': mediumOrHigherCount,
      'questioned_claim_count': review.questionedClaimIds.length,
      'accepted_claim_count': review.acceptedClaimIds.length,
      'suggested_claim_count': review.suggestedClaims.length,
      'waiting_user': category == 'checkpoint_user',
      'manual_attention_required': category == 'manual_attention',
      'requires_repair': category == 'repair',
    };
  }

  JsonMap _permissionSignal(JsonMap result, JsonMap execution) {
    final waitingTools = <String>[];
    for (final rawTool in ValueReaders.objectList(result['executed_tools'])) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolName = ValueReaders.stringValue(tool['name']).trim();
      final toolResult = ValueReaders.mapValue(tool['result']);
      final domainOutcome = ValueReaders.mapValue(toolResult['domain_outcome']);
      final outcomeStatus = ValueReaders.stringValue(
        domainOutcome['outcome_status'],
        ValueReaders.stringValue(toolResult['domain_outcome_status']),
      ).trim();
      final permissionDecision = ValueReaders.mapValue(
        domainOutcome['permission_decision'],
      );
      final permissionDisposition = ValueReaders.stringValue(
        permissionDecision['disposition'],
      ).trim();
      final waiting =
          outcomeStatus == DomainToolOutcomeStatuses.needsUserConfirmation ||
          permissionDisposition ==
              DomainToolOutcomeStatuses.needsUserConfirmation ||
          ValueReaders.boolValue(toolResult['waiting_for_user_choice']);
      if (waiting && toolName.isNotEmpty && !waitingTools.contains(toolName)) {
        waitingTools.add(toolName);
      }
    }
    final response = ValueReaders.mapValue(result['response']);
    final executionWaiting =
        ValueReaders.boolValue(response['waiting_for_user_choice']) ||
        ValueReaders.boolValue(execution['waiting_for_user_choice']);
    return <String, Object?>{
      'waiting_for_user': waitingTools.isNotEmpty || executionWaiting,
      'waiting_tool_names': waitingTools,
      'category': waitingTools.isNotEmpty || executionWaiting
          ? 'checkpoint_user'
          : 'accept',
      'reason': waitingTools.isNotEmpty
          ? 'domain_tool_needs_user_confirmation'
          : (executionWaiting ? 'runtime_waiting_for_user_choice' : ''),
    };
  }

  JsonMap _informationSignal(JsonMap result, JsonMap execution) {
    final providedSignal = _providedInformationSignal(result, execution);
    final providedGate = InformationEvidenceGateSignal.fromJson(
      ValueReaders.mapValue(providedSignal['evidence_gate']).isNotEmpty
          ? ValueReaders.mapValue(providedSignal['evidence_gate'])
          : providedSignal,
    );
    final changedPaths = _informationChangedPaths(result);
    final pendingResearchRequests = <String>[];
    final awaitingConfirmationRequests = <String>[];
    final highRiskReferences = <String>[];
    final designConflicts = <String>[];
    final reasons = <String>[];
    for (final rawTool in ValueReaders.objectList(result['executed_tools'])) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolName = ValueReaders.stringValue(tool['name']).trim();
      final toolResult = ValueReaders.mapValue(tool['result']);
      final domainOutcome = ValueReaders.mapValue(toolResult['domain_outcome']);
      final outcomeStatus = ValueReaders.stringValue(
        domainOutcome['outcome_status'],
        ValueReaders.stringValue(toolResult['domain_outcome_status']),
      ).trim();
      final permissionDecision = ValueReaders.mapValue(
        domainOutcome['permission_decision'],
      );
      final permissionDisposition = ValueReaders.stringValue(
        permissionDecision['disposition'],
      ).trim();
      final payload = ValueReaders.mapValue(domainOutcome['outcome_payload']);
      switch (toolName) {
        case NarrativeDomainToolNames.requestExternalResearch:
          if (ValueReaders.boolValue(payload['request_registered']) &&
              !ValueReaders.boolValue(payload['network_execution_performed'])) {
            final query = ValueReaders.stringValue(
              ValueReaders.mapValue(payload['research_request'])['query'],
            ).trim();
            final descriptor = query.isEmpty
                ? 'external_research_request'
                : query;
            final awaitingConfirmation =
                outcomeStatus ==
                    DomainToolOutcomeStatuses.needsUserConfirmation ||
                permissionDisposition ==
                    DomainToolOutcomeStatuses.needsUserConfirmation ||
                ValueReaders.boolValue(toolResult['waiting_for_user_choice']);
            if (awaitingConfirmation) {
              awaitingConfirmationRequests.add(descriptor);
            } else {
              pendingResearchRequests.add(descriptor);
            }
          }
          break;
        case NarrativeDomainToolNames.proposeReferenceWork:
          final referenceWork = ValueReaders.mapValue(
            payload['reference_work'],
          );
          final requiresConfirmation =
              ValueReaders.boolValue(payload['requires_user_confirmation']) ||
              ValueReaders.boolValue(referenceWork['requires_confirmation']);
          final riskNoteCount = ValueReaders.intValue(
            payload['risk_note_count'],
          );
          final relationshipToProject = ValueReaders.stringValue(
            payload['relationship_to_project'],
            ValueReaders.stringValue(referenceWork['relationship_to_project']),
          ).trim();
          if (requiresConfirmation ||
              riskNoteCount > 0 ||
              _isHighRiskReferenceRelationship(relationshipToProject)) {
            highRiskReferences.add(
              ValueReaders.stringValue(
                referenceWork['reference_work_id'],
                ValueReaders.stringValue(
                  referenceWork['title'],
                  'reference_work',
                ),
              ),
            );
          }
          break;
        case NarrativeDomainToolNames.proposeDesignElement:
          final designElement = ValueReaders.mapValue(
            payload['design_element'],
          );
          final metadata = ValueReaders.mapValue(designElement['metadata']);
          if (_modifiesActiveInformation(metadata)) {
            designConflicts.add(
              ValueReaders.stringValue(
                designElement['design_id'],
                ValueReaders.stringValue(
                  designElement['design_label'],
                  'design_element',
                ),
              ),
            );
          }
          break;
      }
    }
    final requiredOmittedItems = _requiredOmittedInformationItems(
      execution,
      result,
    );
    final awaitingConfirmationCount = _maxInt(
      awaitingConfirmationRequests.length,
      providedGate.awaitingConfirmationCount,
    );
    final pendingResearchCount = _maxInt(
      pendingResearchRequests.length,
      providedGate.pendingResearchCount,
    );
    final gatewayFailureCount = _maxInt(
      _providedCount(
        providedSignal,
        'gateway_failure_count',
        fallbackKey: 'gateway_failed_count',
      ),
      providedGate.gatewayFailureCount,
    );
    final rigorousSourceInsufficientCount = _maxInt(
      _providedCount(providedSignal, 'rigorous_source_insufficient_count'),
      providedGate.rigorousSourceInsufficientCount,
    );
    final requiredInformationOmittedCount = _maxInt(
      _providedCount(
        providedSignal,
        'required_information_omitted_count',
        fallbackKey: 'required_omitted_count',
      ),
      _maxInt(
        providedGate.requiredInformationOmittedCount,
        requiredOmittedItems.length,
      ),
    );
    final externalFactUnverifiedCount = _maxInt(
      _providedCount(providedSignal, 'external_fact_unverified_count'),
      providedGate.externalFactUnverifiedCount,
    );
    var category = 'accept';
    if (highRiskReferences.isNotEmpty) {
      category = 'manual_attention';
      reasons.add('检测到高风险引用作品边界，建议先人工确认引用范围与使用边界。');
    } else if (awaitingConfirmationCount > 0) {
      category = 'checkpoint_user';
      reasons.add('检测到资料请求正在等待用户确认，当前节点应停在真实确认点。');
    } else if (gatewayFailureCount > 0) {
      category = 'repair';
      reasons.add('资料网关执行失败，建议先修复网关或重试研究链路。');
    } else if (designConflicts.isNotEmpty ||
        requiredInformationOmittedCount > 0 ||
        rigorousSourceInsufficientCount > 0 ||
        externalFactUnverifiedCount > 0) {
      category = 'repair';
      if (designConflicts.isNotEmpty) {
        reasons.add('检测到可能覆盖现有长期信息的设计提案，建议先返工或确认冲突。');
      }
      if (requiredInformationOmittedCount > 0) {
        reasons.add('本轮有 required information 因预算或选择被省略，建议先补上下文再继续。');
      }
      if (rigorousSourceInsufficientCount > 0) {
        reasons.add('当前资料来源未达到严谨来源要求，建议先补充权威来源或保留不确定性。');
      }
      if (externalFactUnverifiedCount > 0) {
        reasons.add('当前存在未核验的外部事实，建议在继续前补交叉核验。');
      }
    } else if (pendingResearchCount > 0) {
      category = 'accept';
      reasons.add('检测到待执行的研究请求，继续前建议关注资料缺口是否需要补齐。');
    }
    if (changedPaths.isNotEmpty) {
      reasons.add('本轮已写入 information 层结构化记录，可在 checkpoint 中复核这些改动。');
    }
    final evidenceGate = InformationEvidenceGateSignal.fromJson(
      <String, Object?>{
        'present':
            pendingResearchCount > 0 ||
            awaitingConfirmationCount > 0 ||
            gatewayFailureCount > 0 ||
            rigorousSourceInsufficientCount > 0 ||
            requiredInformationOmittedCount > 0 ||
            externalFactUnverifiedCount > 0 ||
            highRiskReferences.isNotEmpty ||
            designConflicts.isNotEmpty ||
            changedPaths.isNotEmpty ||
            providedGate.present,
        'recommended_disposition': category,
        'reason': ValueReaders.stringValue(
          category == 'manual_attention'
              ? 'information_high_risk_reference'
              : category == 'checkpoint_user'
              ? 'information_awaiting_confirmation'
              : category == 'repair'
              ? (gatewayFailureCount > 0
                    ? 'information_gateway_failed'
                    : designConflicts.isNotEmpty
                    ? 'information_design_conflict'
                    : rigorousSourceInsufficientCount > 0
                    ? 'information_rigorous_source_insufficient'
                    : externalFactUnverifiedCount > 0
                    ? 'information_external_fact_unverified'
                    : 'information_required_omitted')
              : pendingResearchCount > 0
              ? 'information_pending_research'
              : '',
        ),
        'changed_paths': changedPaths,
        'pending_research_count': pendingResearchCount,
        'awaiting_confirmation_count': awaitingConfirmationCount,
        'gateway_failure_count': gatewayFailureCount,
        'rigorous_source_insufficient_count': rigorousSourceInsufficientCount,
        'required_information_omitted_count': requiredInformationOmittedCount,
        'external_fact_unverified_count': externalFactUnverifiedCount,
        'waiting_user': category == 'checkpoint_user',
        'manual_attention_required': category == 'manual_attention',
        'requires_repair': category == 'repair',
        'metadata': <String, Object?>{
          ...ValueReaders.deepCopyMap(providedGate.metadata),
          'pending_research_requests': pendingResearchRequests,
          'awaiting_confirmation_requests': awaitingConfirmationRequests,
          'high_risk_reference_ids': highRiskReferences,
          'design_conflict_ids': designConflicts,
          'required_omitted_titles': requiredOmittedItems,
          'reasons': reasons,
        },
      },
    );
    final summary = _informationSummary(
      pendingResearchCount: pendingResearchCount,
      awaitingConfirmationCount: awaitingConfirmationCount,
      gatewayFailureCount: gatewayFailureCount,
      rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      externalFactUnverifiedCount: externalFactUnverifiedCount,
      highRiskReferences: highRiskReferences,
      designConflicts: designConflicts,
      requiredInformationOmittedCount: requiredInformationOmittedCount,
      changedPaths: changedPaths,
      category: category,
    );
    return <String, Object?>{
      'present': evidenceGate.present,
      'severity': evidenceGate.severity,
      'recommended_disposition': evidenceGate.recommendedDisposition,
      'category': category,
      'summary': summary,
      'reason': evidenceGate.reason,
      'pending_research_count': pendingResearchCount,
      'pending_research_requests': pendingResearchRequests,
      'awaiting_confirmation_count': awaitingConfirmationCount,
      'awaiting_confirmation_requests': awaitingConfirmationRequests,
      'gateway_failure_count': gatewayFailureCount,
      'rigorous_source_insufficient_count': rigorousSourceInsufficientCount,
      'external_fact_unverified_count': externalFactUnverifiedCount,
      'high_risk_reference_count': highRiskReferences.length,
      'high_risk_reference_ids': highRiskReferences,
      'design_conflict_count': designConflicts.length,
      'design_conflict_ids': designConflicts,
      'required_omitted_count': requiredInformationOmittedCount,
      'required_information_omitted_count': requiredInformationOmittedCount,
      'required_omitted_titles': requiredOmittedItems,
      'changed_path_count': changedPaths.length,
      'changed_paths': changedPaths,
      'reasons': reasons,
      'waiting_user': evidenceGate.waitingUser,
      'manual_attention_required': evidenceGate.manualAttentionRequired,
      'requires_repair': evidenceGate.requiresRepair,
      'evidence_gate': evidenceGate.toJson(),
    };
  }

  JsonMap _overallSignal({
    required JsonMap delivery,
    required JsonMap review,
    required JsonMap permission,
    required JsonMap information,
    required JsonMap expressionConstraints,
  }) {
    if (ValueReaders.boolValue(information['manual_attention_required'])) {
      return <String, Object?>{
        'category': 'manual_attention',
        'reason': ValueReaders.stringValue(
          information['reason'],
          'information_manual_attention',
        ),
        'summary': ValueReaders.stringValue(
          information['summary'],
          '信息层信号要求人工介入，当前节点不应自动继续。',
        ),
        'waiting_user': false,
        'manual_attention_required': true,
        'requires_repair': false,
      };
    }
    if (ValueReaders.boolValue(permission['waiting_for_user'])) {
      return <String, Object?>{
        'category': 'checkpoint_user',
        'reason': 'permission_waiting_user',
        'summary': '至少一个领域工具正在等待用户确认，本轮应停在真正的用户确认点。',
        'waiting_user': true,
        'manual_attention_required': false,
        'requires_repair': false,
      };
    }
    if (ValueReaders.boolValue(delivery['manual_attention_required'])) {
      return <String, Object?>{
        'category': 'manual_attention',
        'reason': 'delivery_manual_attention',
        'summary': '章节交付已经进入人工处理范围，不应继续把它伪装成等待用户确认。',
        'waiting_user': false,
        'manual_attention_required': true,
        'requires_repair': false,
      };
    }
    if (ValueReaders.boolValue(review['manual_attention_required'])) {
      return <String, Object?>{
        'category': 'manual_attention',
        'reason': 'semantic_review_manual_attention',
        'summary': '语义复核明确要求人工介入，当前节点不应自动继续。',
        'waiting_user': false,
        'manual_attention_required': true,
        'requires_repair': false,
      };
    }
    if (ValueReaders.stringValue(expressionConstraints['category']).trim() ==
        'light_repair') {
      return <String, Object?>{
        'category': 'repair',
        'reason': ValueReaders.stringValue(
          expressionConstraints['gate_reason'],
          'expression_constraint_light_repair',
        ),
        'summary': ValueReaders.stringValue(
          expressionConstraints['summary'],
          '表达限制已出现轻量风险，建议先做小修再继续。',
        ),
        'waiting_user': false,
        'manual_attention_required': false,
        'requires_repair': true,
      };
    }
    if (ValueReaders.stringValue(expressionConstraints['category']).trim() ==
        'waiting_review_evidence') {
      return <String, Object?>{
        'category': 'repair',
        'reason': ValueReaders.stringValue(
          expressionConstraints['gate_reason'],
          'expression_constraint_review_missing',
        ),
        'summary': ValueReaders.stringValue(
          expressionConstraints['summary'],
          '表达限制当前缺少复核证据，建议先补证据再继续。',
        ),
        'waiting_user': false,
        'manual_attention_required': false,
        'requires_repair': true,
      };
    }
    if (ValueReaders.boolValue(information['requires_repair'])) {
      return <String, Object?>{
        'category': 'repair',
        'reason': ValueReaders.stringValue(
          information['reason'],
          'information_repair_required',
        ),
        'summary': ValueReaders.stringValue(
          information['summary'],
          '信息层信号提示应先补研究、补上下文或处理设计冲突。',
        ),
        'waiting_user': false,
        'manual_attention_required': false,
        'requires_repair': true,
      };
    }
    if (ValueReaders.boolValue(delivery['requires_repair'])) {
      return <String, Object?>{
        'category': 'repair',
        'reason': 'delivery_recovery_required',
        'summary': '章节交付还未稳定达标，应先走 recovery / revision，而不是继续主链。',
        'waiting_user': false,
        'manual_attention_required': false,
        'requires_repair': true,
      };
    }
    if (ValueReaders.boolValue(review['requires_repair'])) {
      return <String, Object?>{
        'category': 'repair',
        'reason': 'semantic_review_repair_required',
        'summary': '语义复核已经给出 blocking/high 风险，建议先返工再决定是否继续。',
        'waiting_user': false,
        'manual_attention_required': false,
        'requires_repair': true,
      };
    }
    if (ValueReaders.boolValue(information['waiting_user'])) {
      return <String, Object?>{
        'category': 'checkpoint_user',
        'reason': ValueReaders.stringValue(
          information['reason'],
          'information_waiting_user',
        ),
        'summary': ValueReaders.stringValue(
          information['summary'],
          '信息层信号建议先停在用户确认点，再继续主链。',
        ),
        'waiting_user': true,
        'manual_attention_required': false,
        'requires_repair': false,
      };
    }
    if (ValueReaders.boolValue(delivery['waiting_user'])) {
      return <String, Object?>{
        'category': 'checkpoint_user',
        'reason': 'delivery_waiting_user_choice',
        'summary': '章节交付正在等待用户做真实选择，当前可以停在明确的用户确认点。',
        'waiting_user': true,
        'manual_attention_required': false,
        'requires_repair': false,
      };
    }
    if (ValueReaders.boolValue(review['waiting_user'])) {
      return <String, Object?>{
        'category': 'checkpoint_user',
        'reason': 'semantic_review_checkpoint_user',
        'summary': '语义复核希望用户确认当前风险结论后再继续推进。',
        'waiting_user': true,
        'manual_attention_required': false,
        'requires_repair': false,
      };
    }
    return const <String, Object?>{
      'category': 'accept',
      'reason': 'narrative_risk_clear',
      'summary': '当前没有来自交付、语义复核或权限层的额外阻塞信号。',
      'waiting_user': false,
      'manual_attention_required': false,
      'requires_repair': false,
    };
  }

  JsonMap _expressionConstraintSignal(JsonMap result, JsonMap execution) {
    final shared = _sharedWritingExecutionResult(result, execution);
    if (shared.isNotEmpty) {
      final constraints = WritingExecutionConstraintSummary.fromJson(
        ValueReaders.mapValue(shared['constraints']),
      );
      return _expressionConstraintSupervisorSignalService.signalFromSummary(
        constraints,
      );
    }
    return const <String, Object?>{};
  }

  JsonMap _latestChapterDeliveryPayload(JsonMap result) {
    for (final rawTool in ValueReaders.objectList(
      result['executed_tools'],
    ).reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) != 'submit_chapter_delivery') {
        continue;
      }
      final outcome = ValueReaders.mapValue(
        ValueReaders.mapValue(tool['result'])['domain_outcome'],
      );
      final payload = ValueReaders.mapValue(outcome['outcome_payload']);
      if (payload.isNotEmpty) {
        return payload;
      }
    }
    return const <String, Object?>{};
  }

  JsonMap _latestSemanticReviewJson(JsonMap result, JsonMap execution) {
    final executionReview = ValueReaders.mapValue(execution['semantic_review']);
    if (executionReview.isNotEmpty) {
      return executionReview;
    }
    for (final rawTool in ValueReaders.objectList(
      result['executed_tools'],
    ).reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) != 'submit_semantic_review') {
        continue;
      }
      final outcome = ValueReaders.mapValue(
        ValueReaders.mapValue(tool['result'])['domain_outcome'],
      );
      final payload = ValueReaders.mapValue(outcome['outcome_payload']);
      final review = ValueReaders.mapValue(payload['review']);
      if (review.isNotEmpty) {
        return review;
      }
    }
    return const <String, Object?>{};
  }

  List<String> _informationChangedPaths(JsonMap result) {
    final changedPaths = <String>[];
    void addPaths(Object? value) {
      for (final rawPath in ValueReaders.stringList(value)) {
        final path = rawPath.trim();
        if (path.isEmpty || changedPaths.contains(path)) {
          continue;
        }
        if (_isInformationChangedPath(path)) {
          changedPaths.add(path);
        }
      }
    }

    addPaths(result['changed_paths']);
    for (final rawTool in ValueReaders.objectList(result['executed_tools'])) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolResult = ValueReaders.mapValue(tool['result']);
      addPaths(toolResult['changed_paths']);
      final domainOutcome = ValueReaders.mapValue(toolResult['domain_outcome']);
      final persistence = ValueReaders.mapValue(
        ValueReaders.mapValue(domainOutcome['metadata'])['adapter_persistence'],
      );
      addPaths(persistence['changed_paths']);
    }
    return changedPaths;
  }

  bool _isInformationChangedPath(String path) {
    final normalized = path.replaceAll('\\', '/').trim().toLowerCase();
    return normalized.startsWith('.novel_agent/information/') ||
        normalized.startsWith('knowledge/') ||
        normalized.startsWith('research/') ||
        normalized.startsWith('references/');
  }

  List<String> _requiredOmittedInformationItems(
    JsonMap execution,
    JsonMap result,
  ) {
    final activationReport =
        ValueReaders.mapValue(execution['activation_report']).isNotEmpty
        ? ValueReaders.mapValue(execution['activation_report'])
        : ValueReaders.mapValue(result['activation_report']);
    final omitted = <String>[];
    for (final rawItem in ValueReaders.objectList(activationReport['items'])) {
      final item = ValueReaders.mapValue(rawItem);
      if (!ValueReaders.boolValue(item['omitted'])) {
        continue;
      }
      final metadata = ValueReaders.mapValue(item['metadata']);
      final sourceKind = ValueReaders.stringValue(
        metadata['source_kind'],
      ).trim();
      if (!sourceKind.startsWith('project_')) {
        continue;
      }
      if (!ValueReaders.boolValue(metadata['required'])) {
        continue;
      }
      final title = ValueReaders.stringValue(
        item['title'],
        ValueReaders.stringValue(item['item_id'], sourceKind),
      ).trim();
      if (title.isNotEmpty && !omitted.contains(title)) {
        omitted.add(title);
      }
    }
    return omitted;
  }

  bool _modifiesActiveInformation(JsonMap metadata) {
    final unknownFields = ValueReaders.mapValue(
      metadata[OpenJsonContractCodecService.unknownFieldsMetadataKey],
    );
    return ValueReaders.boolValue(metadata['modifies_long_term_rule']) ||
        ValueReaders.boolValue(metadata['updates_existing_rule']) ||
        ValueReaders.boolValue(metadata['overrides_active_information']) ||
        ValueReaders.boolValue(unknownFields['modifies_long_term_rule']) ||
        ValueReaders.boolValue(unknownFields['updates_existing_rule']) ||
        ValueReaders.boolValue(unknownFields['overrides_active_information']);
  }

  bool _isHighRiskReferenceRelationship(String relationshipToProject) {
    final normalized = relationshipToProject.trim().toLowerCase();
    return normalized.contains('fanfic') ||
        normalized.contains('crossover') ||
        normalized.contains('deconstructed_source') ||
        normalized.contains('transmigration') ||
        normalized.contains('real_world_novel') ||
        normalized.contains('source_work');
  }

  String _informationSummary({
    required int pendingResearchCount,
    required int awaitingConfirmationCount,
    required int gatewayFailureCount,
    required int rigorousSourceInsufficientCount,
    required int externalFactUnverifiedCount,
    required List<String> highRiskReferences,
    required List<String> designConflicts,
    required int requiredInformationOmittedCount,
    required List<String> changedPaths,
    required String category,
  }) {
    if (category == 'accept' && changedPaths.isEmpty) {
      return '当前没有新的 information 风险信号。';
    }
    final parts = <String>[];
    if (pendingResearchCount > 0) {
      parts.add('待研究 $pendingResearchCount 项');
    }
    if (awaitingConfirmationCount > 0) {
      parts.add('待确认研究 $awaitingConfirmationCount 项');
    }
    if (gatewayFailureCount > 0) {
      parts.add('研究网关失败 $gatewayFailureCount 项');
    }
    if (rigorousSourceInsufficientCount > 0) {
      parts.add('严谨来源不足 $rigorousSourceInsufficientCount 项');
    }
    if (externalFactUnverifiedCount > 0) {
      parts.add('外部事实未核验 $externalFactUnverifiedCount 项');
    }
    if (highRiskReferences.isNotEmpty) {
      parts.add('高风险引用 ${highRiskReferences.length} 项');
    }
    if (designConflicts.isNotEmpty) {
      parts.add('设计冲突 ${designConflicts.length} 项');
    }
    if (requiredInformationOmittedCount > 0) {
      parts.add('required 信息省略 $requiredInformationOmittedCount 项');
    }
    if (changedPaths.isNotEmpty) {
      parts.add('information 改动 ${changedPaths.length} 项');
    }
    return parts.isEmpty ? '当前没有新的 information 风险信号。' : parts.join('，');
  }

  JsonMap _providedInformationSignal(JsonMap result, JsonMap execution) {
    final executionSignal = ValueReaders.mapValue(
      execution['information_signal'],
    );
    if (executionSignal.isNotEmpty) {
      return executionSignal;
    }
    final resultSignal = ValueReaders.mapValue(result['information_signal']);
    if (resultSignal.isNotEmpty) {
      return resultSignal;
    }
    final sharedResult = ValueReaders.mapValue(
      result['writing_execution_result'],
    );
    if (sharedResult.isNotEmpty) {
      return ValueReaders.mapValue(
        ValueReaders.mapValue(sharedResult['information'])['evidence_gate'],
      );
    }
    return const <String, Object?>{};
  }

  JsonMap _sharedWritingExecutionResult(JsonMap result, JsonMap execution) {
    final direct = ValueReaders.mapValue(result['writing_execution_result']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final executionShared = ValueReaders.mapValue(
      execution['writing_execution_result'],
    );
    if (executionShared.isNotEmpty) {
      return executionShared;
    }
    final executionPathShared = ValueReaders.mapValue(
      ValueReaders.mapValue(execution['execution'])['writing_execution_result'],
    );
    if (executionPathShared.isNotEmpty) {
      return executionPathShared;
    }
    return const <String, Object?>{};
  }

  int _providedCount(JsonMap signal, String key, {String fallbackKey = ''}) {
    final direct = ValueReaders.intValue(signal[key]);
    if (direct > 0) {
      return direct;
    }
    if (fallbackKey.isNotEmpty) {
      final fallback = ValueReaders.intValue(signal[fallbackKey]);
      if (fallback > 0) {
        return fallback;
      }
    }
    return ValueReaders.intValue(
      ValueReaders.mapValue(signal['evidence_gate'])[key],
    );
  }

  int _maxInt(int left, int right) {
    return left > right ? left : right;
  }
}
