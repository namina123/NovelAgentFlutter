import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import '../../runtime/tool_round_evidence.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_outcome_statuses.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_permission_dispositions.dart';
import 'domain_tool_request.dart';

class NarrativePermissionPolicyService {
  const NarrativePermissionPolicyService();

  static const String proposeNarrativeProfileUpdate =
      'propose_narrative_profile_update';
  static const String proposeConstraintBinding = 'propose_constraint_binding';
  static const String requestProfileClarification =
      'request_profile_clarification';
  static const String submitChapterDelivery = 'submit_chapter_delivery';
  static const String submitNarrativeStateClaims =
      'submit_narrative_state_claims';
  static const String submitSemanticReview = 'submit_semantic_review';

  DomainToolPermissionDecision decide(DomainToolRequest request) {
    if (_containsForbiddenScriptPayload(request.requestPayload)) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.rejected,
        reason: '禁止自动执行脚本或命令型 payload。',
        policyRef: 'policy.forbidden_auto_execute',
      );
    }

    switch (request.toolName) {
      case submitChapterDelivery:
        return _decideChapterDelivery(request);
      case requestProfileClarification:
        return _decideProfileClarification(request);
      case proposeNarrativeProfileUpdate:
        return _decideProfileProposal(request);
      case proposeConstraintBinding:
        return _decideConstraintBinding(request);
      case submitNarrativeStateClaims:
        return _decideClaimSubmission(request);
      case submitSemanticReview:
        return _decideSemanticReview(request);
      default:
        return const DomainToolPermissionDecision(
          disposition: DomainToolPermissionDispositions.proposed,
          reason: '未知领域工具默认进入提案状态，等待后续显式 handler 收口。',
          policyRef: 'policy.default_proposed',
        );
    }
  }

  DomainToolOutcome buildPermissionOutcome({
    required String outcomeId,
    required DomainToolRequest request,
    JsonMap outcomePayload = const <String, Object?>{},
    ToolRoundEvidence? toolRoundEvidence,
  }) {
    final permissionDecision = decide(request);
    return DomainToolOutcome(
      outcomeId: outcomeId,
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: _outcomeStatusFor(permissionDecision.disposition),
      permissionDecision: permissionDecision,
      outcomePayload: ValueReaders.deepCopyMap(outcomePayload),
      toolRoundEvidence: toolRoundEvidence ?? request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
    );
  }

  DomainToolPermissionDecision _decideProfileProposal(
    DomainToolRequest request,
  ) {
    final proposal = NarrativeProfileProposal.fromJson(request.requestPayload);
    final profileNamespace = _profileNamespaceOf(proposal);
    final targetsBuiltinProfile =
        _looksProtectedProfileId(proposal.targetProfileId) ||
        _looksProtectedProfileId(proposal.baseProfileId) ||
        _looksProtectedNamespace(profileNamespace);
    if (targetsBuiltinProfile) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.rejected,
        reason: '禁止自动修改核心内置 profile。',
        policyRef: 'policy.forbidden_builtin_profile_update',
      );
    }
    if (proposal.requiresUserConfirmation ||
        proposal.targetProfileId.trim().isNotEmpty ||
        proposal.baseProfileId.trim().isNotEmpty) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.needsUserConfirmation,
        reason: '涉及长期项目规则或覆盖既有 profile，必须用户确认。',
        policyRef: 'policy.profile_update_requires_user_confirmation',
      );
    }
    return const DomainToolPermissionDecision(
      disposition: DomainToolPermissionDispositions.proposed,
      reason: 'profile 更新先进入提案状态，不直接自动接受。',
      policyRef: 'policy.profile_update_auto_proposed',
    );
  }

  DomainToolPermissionDecision _decideConstraintBinding(
    DomainToolRequest request,
  ) {
    final proposal = NarrativeConstraintBindingProposal.fromJson(
      request.requestPayload,
    );
    if (proposal.policy.forbiddenAutoApply) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.rejected,
        reason: '该约束绑定显式禁止自动应用。',
        policyRef: 'policy.constraint_binding_forbidden',
      );
    }
    if (proposal.policy.requiresUserConfirmation ||
        _isHighRiskConstraintBinding(proposal)) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.needsUserConfirmation,
        reason: '高风险约束绑定会改变长期写作/审稿策略，必须用户确认。',
        policyRef: 'policy.constraint_binding_requires_user_confirmation',
      );
    }
    if (proposal.policy.autoAccept) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.accepted,
        reason: '低风险约束绑定允许自动接受。',
        policyRef: 'policy.constraint_binding_auto_accept',
      );
    }
    return const DomainToolPermissionDecision(
      disposition: DomainToolPermissionDispositions.proposed,
      reason: '约束绑定默认先进入提案状态。',
      policyRef: 'policy.constraint_binding_auto_proposed',
    );
  }

  DomainToolPermissionDecision _decideClaimSubmission(
    DomainToolRequest request,
  ) {
    final claims = ValueReaders.mapList(
      request.requestPayload['claims'],
    ).map(NarrativeStateClaim.fromJson).toList(growable: false);
    if (request.source.sourceType == NarrativeSourceTypes.reviewer) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.proposed,
        reason: 'reviewer 补充 claim 默认进入提案状态。',
        policyRef: 'policy.reviewer_claim_auto_proposed',
      );
    }
    final isLowRiskChapterLocal =
        claims.isNotEmpty &&
        claims.every((claim) => _isLowRiskChapterLocalClaim(claim));
    if (isLowRiskChapterLocal) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.accepted,
        reason: '本章局部且证据完整的 claim 可自动接受。',
        policyRef: 'policy.chapter_local_claim_auto_accept',
      );
    }
    return const DomainToolPermissionDecision(
      disposition: DomainToolPermissionDispositions.proposed,
      reason: 'claim 证据或影响范围不足以自动接受，先进入提案状态。',
      policyRef: 'policy.claim_auto_proposed',
    );
  }

  DomainToolPermissionDecision _decideSemanticReview(
    DomainToolRequest request,
  ) {
    final review = NarrativeSemanticReview.fromJson(request.requestPayload);
    final hasBlockingFinding = review.findings.any(
      (finding) => finding.severity == SemanticReviewSeverity.blocking,
    );
    if (hasBlockingFinding) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.proposed,
        reason: 'blocking review finding 进入提案/风险消费链，不直接调度执行。',
        policyRef: 'policy.semantic_review_blocking_proposed',
      );
    }
    return const DomainToolPermissionDecision(
      disposition: DomainToolPermissionDispositions.proposed,
      reason: 'semantic review 默认作为结构化建议进入提案状态。',
      policyRef: 'policy.semantic_review_auto_proposed',
    );
  }

  DomainToolPermissionDecision _decideChapterDelivery(
    DomainToolRequest request,
  ) {
    if (request.source.sourceType == NarrativeSourceTypes.writer ||
        request.source.sourceType == NarrativeSourceTypes.recovery ||
        request.source.sourceType == NarrativeSourceTypes.system) {
      return const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.accepted,
        reason: '章节交付工具允许在受控写作来源下直接进入 handler 状态判断。',
        policyRef: 'policy.chapter_delivery_auto_accept',
      );
    }
    return const DomainToolPermissionDecision(
      disposition: DomainToolPermissionDispositions.proposed,
      reason: '非受控来源的章节交付请求先进入提案状态。',
      policyRef: 'policy.chapter_delivery_auto_proposed',
    );
  }

  DomainToolPermissionDecision _decideProfileClarification(
    DomainToolRequest request,
  ) {
    return const DomainToolPermissionDecision(
      disposition: DomainToolPermissionDispositions.proposed,
      reason: '澄清请求先进入 handler，再统一转为等待用户确认结果。',
      policyRef: 'policy.profile_clarification_handler_waiting_user',
    );
  }

  String _outcomeStatusFor(String disposition) {
    switch (disposition) {
      case DomainToolPermissionDispositions.accepted:
        return DomainToolOutcomeStatuses.accepted;
      case DomainToolPermissionDispositions.proposed:
        return DomainToolOutcomeStatuses.proposed;
      case DomainToolPermissionDispositions.rejected:
        return DomainToolOutcomeStatuses.rejected;
      case DomainToolPermissionDispositions.needsUserConfirmation:
        return DomainToolOutcomeStatuses.needsUserConfirmation;
    }
    return DomainToolOutcomeStatuses.proposed;
  }

  bool _containsForbiddenScriptPayload(JsonMap payload) {
    const forbiddenKeys = <String>{
      'script',
      'script_path',
      'command',
      'shell_command',
      'executable_path',
    };
    for (final entry in payload.entries) {
      final key = entry.key.trim().toLowerCase();
      if (forbiddenKeys.contains(key) &&
          ValueReaders.stringValue(entry.value).trim().isNotEmpty) {
        return true;
      }
      final nested = ValueReaders.mapValue(entry.value);
      if (nested.isNotEmpty && _containsForbiddenScriptPayload(nested)) {
        return true;
      }
    }
    return false;
  }

  bool _isHighRiskConstraintBinding(
    NarrativeConstraintBindingProposal proposal,
  ) {
    final normalizedType = proposal.constraintType.trim().toLowerCase();
    final affectsCoreStrategy = proposal.scope.appliesTo.any(
      (entry) => const <String>{
        ConstraintBindingAppliesTo.writing,
        ConstraintBindingAppliesTo.review,
        ConstraintBindingAppliesTo.repair,
      }.contains(entry),
    );
    final touchesStyleOrExpression =
        normalizedType.contains('style') ||
        const ConstraintTypeClassifier().isExpressionConstraint(
          proposal.constraintType,
        );
    return affectsCoreStrategy || touchesStyleOrExpression;
  }

  bool _isLowRiskChapterLocalClaim(NarrativeStateClaim claim) {
    if (claim.confidence < 0.7 || claim.evidenceRefs.isEmpty) {
      return false;
    }
    if (claim.affectedRefs.isEmpty) {
      return false;
    }
    return claim.affectedRefs.every(_isChapterLocalRef) &&
        claim.contextRefs.every(_isChapterLocalRef);
  }

  bool _isChapterLocalRef(NarrativeRef ref) {
    return ref.refType == NarrativeRefTypes.chapter ||
        ref.refType == NarrativeRefTypes.segment;
  }

  bool _looksProtectedProfileId(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('builtin.') || normalized.startsWith('core.');
  }

  bool _looksProtectedNamespace(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('builtin.') || normalized.startsWith('core.');
  }

  String _profileNamespaceOf(NarrativeProfileProposal proposal) {
    return ValueReaders.stringValue(
      proposal.profilePatch.patchPayload['namespace'],
      ValueReaders.stringValue(
        proposal.profilePatch.patchPayload['profile_namespace'],
      ),
    ).trim();
  }
}
