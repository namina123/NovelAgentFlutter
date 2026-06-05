import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_semantic_review.dart';
import '../continuity/narrative_state/semantic_review_recommended_disposition.dart';
import '../continuity/narrative_state/semantic_review_severity.dart';
import '../tools/domain/domain_tool_outcome_statuses.dart';
import '../tools/domain/narrative_domain_tool_names.dart';
import 'chapter_delivery_state_statuses.dart';

class NarrativeSupervisorRiskPolicyService {
  const NarrativeSupervisorRiskPolicyService();

  JsonMap assess({
    required JsonMap result,
    JsonMap execution = const <String, Object?>{},
  }) {
    // 中文注释: supervisor 风险策略只消费结构化 runtime/tool 结果，不读取正文也不判断题材语义。
    final delivery = _deliverySignal(result, execution);
    final review = _reviewSignal(result, execution);
    final permission = _permissionSignal(result, execution);
    final information = _informationSignal(result, execution);
    final overall = _overallSignal(
      delivery: delivery,
      review: review,
      permission: permission,
      information: information,
    );
    return <String, Object?>{
      'delivery': delivery,
      'review': review,
      'permission': permission,
      'information': information,
      'overall': overall,
    };
  }

  JsonMap _deliverySignal(JsonMap result, JsonMap execution) {
    final chapterDelivery = ValueReaders.mapValue(execution['chapter_delivery']);
    final latestToolDelivery = _latestChapterDeliveryPayload(result);
    final source = chapterDelivery.isNotEmpty ? chapterDelivery : latestToolDelivery;
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
      'chapter_body_state': ValueReaders.stringValue(source['chapter_body_state']),
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
      SemanticReviewRecommendedDisposition.manualAttention => 'manual_attention',
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
          permissionDisposition == DomainToolOutcomeStatuses.needsUserConfirmation ||
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
    final changedPaths = _informationChangedPaths(result);
    final pendingResearchRequests = <String>[];
    final highRiskReferences = <String>[];
    final designConflicts = <String>[];
    final reasons = <String>[];
    for (final rawTool in ValueReaders.objectList(result['executed_tools'])) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolName = ValueReaders.stringValue(tool['name']).trim();
      final toolResult = ValueReaders.mapValue(tool['result']);
      final domainOutcome = ValueReaders.mapValue(toolResult['domain_outcome']);
      final payload = ValueReaders.mapValue(domainOutcome['outcome_payload']);
      switch (toolName) {
        case NarrativeDomainToolNames.requestExternalResearch:
          if (ValueReaders.boolValue(payload['request_registered']) &&
              !ValueReaders.boolValue(payload['network_execution_performed'])) {
            final query = ValueReaders.stringValue(
              ValueReaders.mapValue(payload['research_request'])['query'],
            ).trim();
            pendingResearchRequests.add(
              query.isEmpty ? 'external_research_request' : query,
            );
          }
          break;
        case NarrativeDomainToolNames.proposeReferenceWork:
          final referenceWork = ValueReaders.mapValue(payload['reference_work']);
          final requiresConfirmation =
              ValueReaders.boolValue(payload['requires_user_confirmation']) ||
              ValueReaders.boolValue(referenceWork['requires_confirmation']);
          final riskNoteCount = ValueReaders.intValue(payload['risk_note_count']);
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
                ValueReaders.stringValue(referenceWork['title'], 'reference_work'),
              ),
            );
          }
          break;
        case NarrativeDomainToolNames.proposeDesignElement:
          final designElement = ValueReaders.mapValue(payload['design_element']);
          final metadata = ValueReaders.mapValue(designElement['metadata']);
          if (_modifiesActiveInformation(metadata)) {
            designConflicts.add(
              ValueReaders.stringValue(
                designElement['design_id'],
                ValueReaders.stringValue(designElement['design_label'], 'design_element'),
              ),
            );
          }
          break;
      }
    }
    final requiredOmittedItems = _requiredOmittedInformationItems(execution, result);
    var category = 'accept';
    if (highRiskReferences.isNotEmpty) {
      category = 'manual_attention';
      reasons.add('检测到高风险引用作品边界，建议先人工确认引用范围与使用边界。');
    } else if (designConflicts.isNotEmpty || requiredOmittedItems.isNotEmpty) {
      category = 'repair';
      if (designConflicts.isNotEmpty) {
        reasons.add('检测到可能覆盖现有长期信息的设计提案，建议先返工或确认冲突。');
      }
      if (requiredOmittedItems.isNotEmpty) {
        reasons.add('本轮有 required information 因预算或选择被省略，建议先补上下文再继续。');
      }
    } else if (pendingResearchRequests.isNotEmpty) {
      category = 'checkpoint_user';
      reasons.add('检测到待处理的外部研究请求，建议在继续前确认是否补研究。');
    }
    if (changedPaths.isNotEmpty) {
      reasons.add('本轮已写入 information 层结构化记录，可在 checkpoint 中复核这些改动。');
    }
    final summary = _informationSummary(
      pendingResearchRequests: pendingResearchRequests,
      highRiskReferences: highRiskReferences,
      designConflicts: designConflicts,
      requiredOmittedItems: requiredOmittedItems,
      changedPaths: changedPaths,
      category: category,
    );
    return <String, Object?>{
      'present':
          pendingResearchRequests.isNotEmpty ||
          highRiskReferences.isNotEmpty ||
          designConflicts.isNotEmpty ||
          requiredOmittedItems.isNotEmpty ||
          changedPaths.isNotEmpty,
      'category': category,
      'summary': summary,
      'reason': ValueReaders.stringValue(
        category == 'manual_attention'
            ? 'information_high_risk_reference'
            : category == 'repair'
            ? (designConflicts.isNotEmpty
                  ? 'information_design_conflict'
                  : 'information_required_omitted')
            : category == 'checkpoint_user'
            ? 'information_pending_research'
            : '',
      ),
      'pending_research_count': pendingResearchRequests.length,
      'pending_research_requests': pendingResearchRequests,
      'high_risk_reference_count': highRiskReferences.length,
      'high_risk_reference_ids': highRiskReferences,
      'design_conflict_count': designConflicts.length,
      'design_conflict_ids': designConflicts,
      'required_omitted_count': requiredOmittedItems.length,
      'required_omitted_titles': requiredOmittedItems,
      'changed_path_count': changedPaths.length,
      'changed_paths': changedPaths,
      'reasons': reasons,
      'waiting_user': category == 'checkpoint_user',
      'manual_attention_required': category == 'manual_attention',
      'requires_repair': category == 'repair',
    };
  }

  JsonMap _overallSignal({
    required JsonMap delivery,
    required JsonMap review,
    required JsonMap permission,
    required JsonMap information,
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

  JsonMap _latestChapterDeliveryPayload(JsonMap result) {
    for (final rawTool in ValueReaders.objectList(result['executed_tools']).reversed) {
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
    for (final rawTool in ValueReaders.objectList(result['executed_tools']).reversed) {
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
    final activationReport = ValueReaders.mapValue(
      execution['activation_report'],
    ).isNotEmpty
        ? ValueReaders.mapValue(execution['activation_report'])
        : ValueReaders.mapValue(result['activation_report']);
    final omitted = <String>[];
    for (final rawItem in ValueReaders.objectList(activationReport['items'])) {
      final item = ValueReaders.mapValue(rawItem);
      if (!ValueReaders.boolValue(item['omitted'])) {
        continue;
      }
      final metadata = ValueReaders.mapValue(item['metadata']);
      final sourceKind = ValueReaders.stringValue(metadata['source_kind']).trim();
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
    required List<String> pendingResearchRequests,
    required List<String> highRiskReferences,
    required List<String> designConflicts,
    required List<String> requiredOmittedItems,
    required List<String> changedPaths,
    required String category,
  }) {
    if (category == 'accept' && changedPaths.isEmpty) {
      return '当前没有新的 information 风险信号。';
    }
    final parts = <String>[];
    if (pendingResearchRequests.isNotEmpty) {
      parts.add('待研究 ${pendingResearchRequests.length} 项');
    }
    if (highRiskReferences.isNotEmpty) {
      parts.add('高风险引用 ${highRiskReferences.length} 项');
    }
    if (designConflicts.isNotEmpty) {
      parts.add('设计冲突 ${designConflicts.length} 项');
    }
    if (requiredOmittedItems.isNotEmpty) {
      parts.add('required 信息省略 ${requiredOmittedItems.length} 项');
    }
    if (changedPaths.isNotEmpty) {
      parts.add('information 改动 ${changedPaths.length} 项');
    }
    return parts.isEmpty ? '当前没有新的 information 风险信号。' : parts.join('，');
  }
}
