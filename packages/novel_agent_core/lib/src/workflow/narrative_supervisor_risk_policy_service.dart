import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_semantic_review.dart';
import '../continuity/narrative_state/semantic_review_recommended_disposition.dart';
import '../continuity/narrative_state/semantic_review_severity.dart';
import '../tools/domain/domain_tool_outcome_statuses.dart';
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
    final overall = _overallSignal(
      delivery: delivery,
      review: review,
      permission: permission,
    );
    return <String, Object?>{
      'delivery': delivery,
      'review': review,
      'permission': permission,
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

  JsonMap _overallSignal({
    required JsonMap delivery,
    required JsonMap review,
    required JsonMap permission,
  }) {
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
}
