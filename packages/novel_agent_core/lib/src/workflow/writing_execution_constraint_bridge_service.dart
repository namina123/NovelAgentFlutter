import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/constraint_binding_applies_to.dart';
import '../continuity/narrative_state/narrative_constraint_binding_proposal.dart';
import '../creative/expression_constraint_execution_policy.dart';
import '../creative/expression_constraint_execution_policy_resolution_context.dart';
import '../creative/expression_constraint_execution_policy_resolver_service.dart';
import '../creative/expression_constraint_kind.dart';
import '../creative/expression_constraint_injection_policy_service.dart';
import '../creative/expression_constraint_profile.dart';
import '../creative/expression_constraint_profile_normalizer_service.dart';
import '../creative/project_expression_constraint_binding.dart';
import '../creative/project_expression_constraint_binding_normalizer_service.dart';
import 'chapter_length_profile_resolver_service.dart';
import 'writing_execution_constraint_bridge_result.dart';
import 'writing_execution_constraint_summary.dart';

class WritingExecutionConstraintBridgeService {
  const WritingExecutionConstraintBridgeService({
    ChapterLengthProfileResolverService? chapterLengthProfileResolverService,
    ExpressionConstraintExecutionPolicyResolverService?
    expressionConstraintExecutionPolicyResolverService,
    ExpressionConstraintInjectionPolicyService?
    expressionConstraintInjectionPolicyService,
    ExpressionConstraintProfileNormalizerService?
    expressionConstraintProfileNormalizerService,
    ProjectExpressionConstraintBindingNormalizerService?
    projectExpressionConstraintBindingNormalizerService,
  }) : _chapterLengthProfileResolverService =
           chapterLengthProfileResolverService ??
           const ChapterLengthProfileResolverService(),
       _expressionConstraintExecutionPolicyResolverService =
           expressionConstraintExecutionPolicyResolverService ??
           const ExpressionConstraintExecutionPolicyResolverService(),
       _expressionConstraintInjectionPolicyService =
           expressionConstraintInjectionPolicyService ??
           const ExpressionConstraintInjectionPolicyService(),
       _expressionConstraintProfileNormalizerService =
           expressionConstraintProfileNormalizerService ??
           const ExpressionConstraintProfileNormalizerService(),
       _projectExpressionConstraintBindingNormalizerService =
           projectExpressionConstraintBindingNormalizerService ??
           const ProjectExpressionConstraintBindingNormalizerService();

  final ChapterLengthProfileResolverService
  _chapterLengthProfileResolverService;
  final ExpressionConstraintExecutionPolicyResolverService
  _expressionConstraintExecutionPolicyResolverService;
  final ExpressionConstraintInjectionPolicyService
  _expressionConstraintInjectionPolicyService;
  final ExpressionConstraintProfileNormalizerService
  _expressionConstraintProfileNormalizerService;
  final ProjectExpressionConstraintBindingNormalizerService
  _projectExpressionConstraintBindingNormalizerService;

  WritingExecutionConstraintBridgeResult bridge({
    required String appliesTo,
    required String projectTypeId,
    String agentId = '',
    String modeId = '',
    String stageId = '',
    String intent = 'draft',
    String taskType = '',
    String phase = '',
    String expressionConstraintPolicyMode = '',
    String expressionConstraintInjectionMode = '',
    JsonMap legacyChapterLengthOptions = const <String, Object?>{},
    List<Object?> legacyExpressionConstraintProfiles = const <Object?>[],
    List<Object?> legacyProjectExpressionConstraintBindings = const <Object?>[],
    List<WritingExecutionConstraintSummary>
        recentExpressionConstraintSummaries =
        const <WritingExecutionConstraintSummary>[],
    List<NarrativeConstraintBindingProposal> narrativeBindings =
        const <NarrativeConstraintBindingProposal>[],
  }) {
    final cleanAppliesTo = appliesTo.trim().isEmpty
        ? ConstraintBindingAppliesTo.writing
        : appliesTo.trim();
    final cleanStageId = stageId.trim().isEmpty ? 'draft' : stageId.trim();
    final cleanModeId = modeId.trim();
    final cleanAgentId = agentId.trim();
    final cleanProjectTypeId = projectTypeId.trim();
    final cleanIntent = intent.trim().isEmpty ? 'draft' : intent.trim();
    final cleanTaskType = taskType.trim();
    final cleanPhase = phase.trim();

    final legacyProfiles = legacyExpressionConstraintProfiles
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .map(_expressionConstraintProfileNormalizerService.normalize)
        .where((profile) => profile.id.trim().isNotEmpty)
        .toList(growable: true);
    final legacyBindings = legacyProjectExpressionConstraintBindings
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .map(_projectExpressionConstraintBindingNormalizerService.normalize)
        .where((binding) => binding.profileId.trim().isNotEmpty)
        .toList(growable: true);

    final chapterLengthCandidates = narrativeBindings
        .where(
          (binding) =>
              _isChapterLengthConstraint(binding.constraintType) &&
              _matchesRuntime(
                binding,
                appliesTo: cleanAppliesTo,
                projectTypeId: cleanProjectTypeId,
                agentId: cleanAgentId,
                modeId: cleanModeId,
                stageId: cleanStageId,
                requireImmediateStageMatch: true,
              ) &&
              !binding.policy.forbiddenAutoApply,
        )
        .toList(growable: false);
    final expressionCandidates = narrativeBindings
        .where(
          (binding) =>
              _isExpressionConstraint(binding.constraintType) &&
              _matchesRuntime(
                binding,
                appliesTo: cleanAppliesTo,
                projectTypeId: cleanProjectTypeId,
                agentId: cleanAgentId,
                modeId: cleanModeId,
                stageId: cleanStageId,
                requireImmediateStageMatch: false,
              ) &&
              !binding.policy.forbiddenAutoApply,
        )
        .toList(growable: false);

    final legacyChapterLengthMetadata = _chapterLengthProfileResolverService
        .buildMetadataFromOptions(
          legacyChapterLengthOptions,
          stage: cleanStageId,
        );
    final bindingChapterLengthMetadata = chapterLengthCandidates.isEmpty
        ? const <String, Object?>{}
        : _chapterLengthMetadataFromBinding(
            chapterLengthCandidates.last,
            stageId: cleanStageId,
          );
    final effectiveChapterLengthMetadata =
        bindingChapterLengthMetadata.isNotEmpty
        ? bindingChapterLengthMetadata
        : legacyChapterLengthMetadata;

    final profileIds = <String>{};
    final bindingIds = <String>{};
    final bindingIdentities = <String>{};
    for (final profile in legacyProfiles) {
      profileIds.add(profile.id);
    }
    for (final binding in legacyBindings) {
      bindingIds.add(binding.id);
      bindingIdentities.add(_bindingIdentity(binding));
    }
    final bindingDerivedProfiles = <ExpressionConstraintProfile>[];
    final bindingDerivedBindings = <ProjectExpressionConstraintBinding>[];
    final appliedExpressionBindingIds = <String>[];
    for (final binding in expressionCandidates) {
      final applied = _appendExpressionConstraintBinding(
        binding,
        existingProfiles: legacyProfiles,
        profileIds: profileIds,
        bindingIds: bindingIds,
        bindingIdentities: bindingIdentities,
        sinkProfiles: bindingDerivedProfiles,
        sinkBindings: bindingDerivedBindings,
      );
      if (applied && !appliedExpressionBindingIds.contains(binding.bindingId)) {
        appliedExpressionBindingIds.add(binding.bindingId);
      }
    }

    final allProfiles = <ExpressionConstraintProfile>[
      ...legacyProfiles,
      ...bindingDerivedProfiles,
    ];
    final allBindings = <ProjectExpressionConstraintBinding>[
      ...legacyBindings,
      ...bindingDerivedBindings,
    ];
    final policyResolution = _expressionConstraintExecutionPolicyResolverService
        .resolve(
          ExpressionConstraintExecutionPolicyResolutionContext(
            overrideMode: _resolvePolicyModeOverride(
              expressionConstraintPolicyMode,
              legacyInjectionModeOverride: expressionConstraintInjectionMode,
            ),
            intent: cleanIntent,
            taskType: cleanTaskType,
            phase: cleanPhase,
            appliesTo: cleanAppliesTo,
            projectTypeId: cleanProjectTypeId,
            agentId: cleanAgentId,
            modeId: cleanModeId,
            stageId: cleanStageId,
            hasBindings: allBindings.isNotEmpty,
            recentSummaries: recentExpressionConstraintSummaries,
          ),
        );
    final policy = policyResolution.policy;
    final expressionConstraintReviewRequired =
        policyResolution.applied &&
        policy.reviewRequirement != ExpressionConstraintReviewRequirements.none;
    final resolvedExpressionConstraintInjectionMode = policyResolution.applied
        ? _expressionConstraintInjectionPolicyService.modeId(
            _expressionConstraintInjectionPolicyService.resolveMode(
              executionPolicy: policy,
              policyMode: policy.mode,
              policyInjectionStrength: policy.injectionStrength,
              intent: cleanIntent,
              taskType: cleanTaskType,
              phase: cleanPhase,
              overrideModeId: expressionConstraintInjectionMode,
            ),
          )
        : 'disabled';

    return WritingExecutionConstraintBridgeResult(
      chapterLengthMetadata: effectiveChapterLengthMetadata,
      expressionConstraintProfiles:
          List<ExpressionConstraintProfile>.unmodifiable(allProfiles),
      projectExpressionConstraintBindings:
          List<ProjectExpressionConstraintBinding>.unmodifiable(allBindings),
      expressionConstraintPolicyMode: policy.mode,
      expressionConstraintInjectionStrength: policy.injectionStrength,
      expressionConstraintReviewRequirement: policy.reviewRequirement,
      expressionConstraintViolationDisposition: policy.violationDisposition,
      expressionConstraintApplied: policyResolution.applied,
      expressionConstraintRuntimeEscalated: policyResolution.runtimeEscalated,
      expressionConstraintTechnicalTurnExcluded:
          policyResolution.technicalTurnExcluded,
      expressionConstraintAppliedReasons: List<String>.unmodifiable(
        policyResolution.whyApplied,
      ),
      expressionConstraintSkippedReasons: List<String>.unmodifiable(
        policyResolution.whySkipped,
      ),
      expressionConstraintInjectionMode:
          resolvedExpressionConstraintInjectionMode,
      expressionConstraintReviewRequired: expressionConstraintReviewRequired,
      runtimeReport: <String, Object?>{
        'applies_to': cleanAppliesTo,
        'project_type_id': cleanProjectTypeId,
        'agent_id': cleanAgentId,
        'mode_id': cleanModeId,
        'stage_id': cleanStageId,
        'intent': cleanIntent,
        'task_type': cleanTaskType,
        'phase': cleanPhase,
        'chapter_length': <String, Object?>{
          'applied': effectiveChapterLengthMetadata.isNotEmpty,
          'source': bindingChapterLengthMetadata.isNotEmpty
              ? 'binding'
              : legacyChapterLengthMetadata.isNotEmpty
              ? 'legacy'
              : 'none',
          'binding_id': chapterLengthCandidates.isEmpty
              ? ''
              : chapterLengthCandidates.last.bindingId,
          'legacy_present': legacyChapterLengthMetadata.isNotEmpty,
          'profile': ValueReaders.deepCopyMap(
            ValueReaders.mapValue(
              effectiveChapterLengthMetadata['chapter_length_profile'],
            ),
          ),
        },
        'expression_constraints': <String, Object?>{
          'legacy_profile_count': legacyProfiles.length,
          'legacy_binding_count': legacyBindings.length,
          'binding_profile_count': bindingDerivedProfiles.length,
          'binding_binding_count': bindingDerivedBindings.length,
          'profile_count': allProfiles.length,
          'binding_count': allBindings.length,
          'applied_binding_ids': appliedExpressionBindingIds,
          'policy_mode': policy.mode,
          'policy_applied': policyResolution.applied,
          'injection_strength': policy.injectionStrength,
          'injection_mode': resolvedExpressionConstraintInjectionMode,
          'review_requirement': policy.reviewRequirement,
          'review_required': expressionConstraintReviewRequired,
          'violation_disposition': policy.violationDisposition,
          'runtime_escalated': policyResolution.runtimeEscalated,
          'technical_turn_excluded': policyResolution.technicalTurnExcluded,
          'why_applied': ValueReaders.deepCopyList(
            policyResolution.whyApplied.cast<Object?>(),
          ),
          'why_skipped': ValueReaders.deepCopyList(
            policyResolution.whySkipped.cast<Object?>(),
          ),
          'policy': policyResolution.toJson(),
        },
        'execution_gate': <String, Object?>{
          'chapter_length': <String, Object?>{
            'configured': effectiveChapterLengthMetadata.isNotEmpty,
            'soft_action': 'adjust_next_chapter',
            'reminder_action': 'remind',
            'hard_action': 'review_or_repair',
          },
          'expression_constraints': <String, Object?>{
            'active': allBindings.isNotEmpty,
            'policy_mode': policy.mode,
            'applied': policyResolution.applied,
            'disabled':
                policy.mode ==
                ExpressionConstraintExecutionPolicyModes.disabled,
            'technical_turn_excluded': policyResolution.technicalTurnExcluded,
            'runtime_escalated': policyResolution.runtimeEscalated,
            'injection_strength': policy.injectionStrength,
            'injection_mode': resolvedExpressionConstraintInjectionMode,
            'review_requirement': policy.reviewRequirement,
            'review_required': expressionConstraintReviewRequired,
            'violation_disposition': policy.violationDisposition,
            'profile_count': allProfiles.length,
            'binding_count': allBindings.length,
            'applied_binding_ids': appliedExpressionBindingIds,
            'why_applied': ValueReaders.deepCopyList(
              policyResolution.whyApplied.cast<Object?>(),
            ),
            'why_skipped': ValueReaders.deepCopyList(
              policyResolution.whySkipped.cast<Object?>(),
            ),
          },
        },
      },
    );
  }

  String _resolvePolicyModeOverride(
    String explicitPolicyMode, {
    required String legacyInjectionModeOverride,
  }) {
    final cleanPolicyMode = explicitPolicyMode.trim().toLowerCase();
    if (cleanPolicyMode.isNotEmpty) {
      return cleanPolicyMode;
    }
    final cleanLegacyOverride = legacyInjectionModeOverride
        .trim()
        .toLowerCase();
    if (cleanLegacyOverride == 'disabled' || cleanLegacyOverride == 'none') {
      return ExpressionConstraintExecutionPolicyModes.disabled;
    }
    return '';
  }

  bool _appendExpressionConstraintBinding(
    NarrativeConstraintBindingProposal binding, {
    required List<ExpressionConstraintProfile> existingProfiles,
    required Set<String> profileIds,
    required Set<String> bindingIds,
    required Set<String> bindingIdentities,
    required List<ExpressionConstraintProfile> sinkProfiles,
    required List<ProjectExpressionConstraintBinding> sinkBindings,
  }) {
    var applied = false;
    final payload = binding.constraintPayload;
    final scopedAgentIds = binding.scope.agentIds;
    final scopedModeIds = binding.scope.modeIds;
    final scopedStageIds = binding.scope.stageIds;
    final displayName = binding.constraintLabel.trim().isNotEmpty
        ? binding.constraintLabel.trim()
        : '表达限制';
    final baseMetadata = <String, Object?>{
      'source': 'narrative_constraint_binding',
      'binding_id': binding.bindingId,
      'constraint_type': binding.constraintType,
      'constraint_origin': binding.constraintOrigin,
      'binding_reason': binding.reason,
    };

    final directProfileId = _resolvedDirectProfileId(
      binding,
      availableProfiles: existingProfiles,
      profileIds: profileIds,
    );
    if (directProfileId.isNotEmpty) {
      final projectBinding = ProjectExpressionConstraintBinding(
        id: _nextUniqueBindingId(bindingIds, '${binding.bindingId}__profile'),
        profileId: directProfileId,
        displayName: displayName,
        enabled: true,
        defaultForProject:
            scopedAgentIds.isEmpty &&
            scopedModeIds.isEmpty &&
            scopedStageIds.isEmpty,
        targetAgentIds: List<String>.unmodifiable(scopedAgentIds),
        targetModeIds: List<String>.unmodifiable(scopedModeIds),
        targetStageIds: List<String>.unmodifiable(scopedStageIds),
        weight: ValueReaders.intValue(
          payload['weight'] ?? binding.metadata['weight'],
          120,
        ),
        metadata: baseMetadata,
      );
      final identity = _bindingIdentity(projectBinding);
      if (!bindingIdentities.contains(identity)) {
        bindingIdentities.add(identity);
        sinkBindings.add(projectBinding);
      }
      applied = true;
    }

    final syntheticRules = _expressionRules(payload);
    if (syntheticRules.isEmpty) {
      return applied;
    }
    final syntheticProfileId = _nextUniqueProfileId(
      profileIds,
      ValueReaders.stringValue(
        payload['generated_profile_id'],
        '${binding.bindingId}__rules',
      ),
    );
    final profile = ExpressionConstraintProfile(
      id: syntheticProfileId,
      displayName: displayName,
      summary: binding.reason.trim().isNotEmpty
          ? binding.reason.trim()
          : '来自开放叙事状态约束绑定的表达限制。',
      kind: _expressionConstraintKind(payload),
      rules: List<String>.unmodifiable(syntheticRules),
      riskSignals: List<String>.unmodifiable(
        ValueReaders.stringList(payload['risk_signals']),
      ),
      metadata: <String, Object?>{...baseMetadata, 'synthetic_profile': true},
    );
    sinkProfiles.add(profile);
    final syntheticBinding = ProjectExpressionConstraintBinding(
      id: _nextUniqueBindingId(bindingIds, '${binding.bindingId}__rules'),
      profileId: syntheticProfileId,
      displayName: displayName,
      enabled: true,
      defaultForProject:
          scopedAgentIds.isEmpty &&
          scopedModeIds.isEmpty &&
          scopedStageIds.isEmpty,
      targetAgentIds: List<String>.unmodifiable(scopedAgentIds),
      targetModeIds: List<String>.unmodifiable(scopedModeIds),
      targetStageIds: List<String>.unmodifiable(scopedStageIds),
      weight: ValueReaders.intValue(
        payload['rule_weight'] ??
            payload['weight'] ??
            binding.metadata['weight'],
        140,
      ),
      metadata: <String, Object?>{...baseMetadata, 'synthetic_profile': true},
    );
    final syntheticIdentity = _bindingIdentity(syntheticBinding);
    if (!bindingIdentities.contains(syntheticIdentity)) {
      bindingIdentities.add(syntheticIdentity);
      sinkBindings.add(syntheticBinding);
    }
    applied = true;
    return applied;
  }

  String _resolvedDirectProfileId(
    NarrativeConstraintBindingProposal binding, {
    required List<ExpressionConstraintProfile> availableProfiles,
    required Set<String> profileIds,
  }) {
    final payload = binding.constraintPayload;
    final directProfileId = ValueReaders.stringValue(
      payload['profile_id'],
      ValueReaders.stringValue(payload['builtin_profile_id']),
    ).trim();
    if (directProfileId.isNotEmpty) {
      return directProfileId;
    }
    final fallbackId = binding.constraintId.trim();
    if (fallbackId.isEmpty) {
      return '';
    }
    if (profileIds.contains(fallbackId) ||
        availableProfiles.any((profile) => profile.id == fallbackId)) {
      return fallbackId;
    }
    return '';
  }

  List<String> _expressionRules(JsonMap payload) {
    final result = <String>[];
    void addRules(Object? value) {
      for (final item in ValueReaders.stringList(value)) {
        final clean = item.trim();
        if (clean.isNotEmpty && !result.contains(clean)) {
          result.add(clean);
        }
      }
    }

    addRules(payload['rules']);
    addRules(payload['project_level_rules']);
    addRules(
      ValueReaders.mapValue(
        payload['soft_review_policy'],
      )['project_level_rules'],
    );
    return result;
  }

  ExpressionConstraintKind _expressionConstraintKind(JsonMap payload) {
    final rawKind = ValueReaders.stringValue(
      payload['kind'],
      ValueReaders.stringValue(payload['constraint_kind']),
    ).trim();
    return switch (rawKind) {
      'natural_expression' => ExpressionConstraintKind.naturalExpression,
      'narrative_boundary' => ExpressionConstraintKind.narrativeBoundary,
      'terminology_control' => ExpressionConstraintKind.terminologyControl,
      'rhythm_control' => ExpressionConstraintKind.rhythmControl,
      'continuity_guard' => ExpressionConstraintKind.continuityGuard,
      _ => ExpressionConstraintKind.custom,
    };
  }

  JsonMap _chapterLengthMetadataFromBinding(
    NarrativeConstraintBindingProposal binding, {
    required String stageId,
  }) {
    final payload = binding.constraintPayload;
    final hardPolicy = binding.policy.hardExecutionPolicy;
    final softPolicy = binding.policy.softReviewPolicy;
    final target = ValueReaders.intValue(
      payload['target_word_count'] ??
          payload['target_length'] ??
          hardPolicy['target_word_count'] ??
          hardPolicy['target_length'],
    );
    final min = ValueReaders.intValue(
      payload['preferred_min'] ??
          payload['min_word_count'] ??
          softPolicy['warn_if_below'] ??
          hardPolicy['preferred_min'],
    );
    final max = ValueReaders.intValue(
      payload['preferred_max'] ??
          payload['max_word_count'] ??
          softPolicy['warn_if_above'] ??
          hardPolicy['preferred_max'],
    );
    if (target <= 0 && min <= 0 && max <= 0) {
      return const <String, Object?>{};
    }
    final profile = <String, Object?>{
      'enabled': true,
      'target_length': target > 0
          ? target
          : min > 0
          ? min
          : max > 0
          ? max
          : 0,
      if (min > 0) 'preferred_min': min,
      if (max > 0) 'preferred_max': max,
      'stage': _bindingStageId(binding, stageId),
      'metric_unit': ValueReaders.stringValue(
        payload['metric_unit'],
        'visible_characters',
      ),
      'metadata': <String, Object?>{
        'source': 'narrative_constraint_binding',
        'binding_id': binding.bindingId,
      },
    };
    final policy = <String, Object?>{
      'rolling_window': ValueReaders.intValue(
        payload['rolling_window'] ??
            hardPolicy['rolling_window'] ??
            softPolicy['rolling_window'],
        4,
      ).clamp(2, 8),
      'mild_deviation_ratio': _ratio(
        payload['mild_deviation_ratio'] ??
            hardPolicy['mild_deviation_ratio'] ??
            softPolicy['mild_deviation_ratio'],
        0.18,
      ),
      'severe_deviation_ratio': _ratio(
        payload['severe_deviation_ratio'] ??
            hardPolicy['severe_deviation_ratio'] ??
            softPolicy['severe_deviation_ratio'],
        0.35,
      ),
      'mild_adjacent_delta_ratio': _ratio(
        payload['mild_adjacent_delta_ratio'] ??
            hardPolicy['mild_adjacent_delta_ratio'] ??
            softPolicy['mild_adjacent_delta_ratio'],
        0.22,
      ),
      'severe_adjacent_delta_ratio': _ratio(
        payload['severe_adjacent_delta_ratio'] ??
            hardPolicy['severe_adjacent_delta_ratio'] ??
            softPolicy['severe_adjacent_delta_ratio'],
        0.45,
      ),
    };
    return <String, Object?>{
      'chapter_length_profile': profile,
      'chapter_length_distribution_policy': policy,
      if (target > 0) 'chapter_word_target': target,
      if (min > 0) 'chapter_word_min': min,
      if (max > 0) 'chapter_word_max': max,
    };
  }

  String _bindingStageId(
    NarrativeConstraintBindingProposal binding,
    String fallbackStageId,
  ) {
    if (binding.scope.stageIds.isEmpty) {
      return fallbackStageId;
    }
    return binding.scope.stageIds.first.trim().isEmpty
        ? fallbackStageId
        : binding.scope.stageIds.first.trim();
  }

  bool _matchesRuntime(
    NarrativeConstraintBindingProposal binding, {
    required String appliesTo,
    required String projectTypeId,
    required String agentId,
    required String modeId,
    required String stageId,
    required bool requireImmediateStageMatch,
  }) {
    if (!_matchesScope(binding.scope.appliesTo, appliesTo)) {
      return false;
    }
    if (!_matchesScope(binding.scope.projectTypeIds, projectTypeId)) {
      return false;
    }
    if (binding.scope.agentIds.isNotEmpty &&
        !_matchesScope(binding.scope.agentIds, agentId)) {
      return false;
    }
    if (binding.scope.modeIds.isNotEmpty &&
        !_matchesScope(binding.scope.modeIds, modeId)) {
      return false;
    }
    if (requireImmediateStageMatch &&
        binding.scope.stageIds.isNotEmpty &&
        !_matchesScope(binding.scope.stageIds, stageId)) {
      return false;
    }
    return true;
  }

  bool _matchesScope(List<String> scopedIds, String currentId) {
    if (scopedIds.isEmpty) {
      return true;
    }
    final cleanCurrentId = currentId.trim();
    if (cleanCurrentId.isEmpty) {
      return false;
    }
    return scopedIds.contains(cleanCurrentId);
  }

  bool _isChapterLengthConstraint(String constraintType) {
    final clean = constraintType.trim();
    return clean == 'chapter_length' || clean == 'word_count';
  }

  bool _isExpressionConstraint(String constraintType) {
    final clean = constraintType.trim();
    return clean == 'expression_constraint' ||
        clean.startsWith('expression_constraint.');
  }

  String _bindingIdentity(ProjectExpressionConstraintBinding binding) {
    return [
      binding.id.trim(),
      binding.profileId.trim(),
      binding.targetAgentIds.join(','),
      binding.targetModeIds.join(','),
      binding.targetStageIds.join(','),
    ].join('|');
  }

  String _nextUniqueProfileId(Set<String> existingIds, String baseId) {
    var candidate = baseId.trim().isEmpty
        ? 'expression_constraint'
        : baseId.trim();
    var index = 1;
    while (existingIds.contains(candidate)) {
      candidate =
          '${baseId.trim().isEmpty ? 'expression_constraint' : baseId.trim()}_$index';
      index += 1;
    }
    existingIds.add(candidate);
    return candidate;
  }

  String _nextUniqueBindingId(Set<String> existingIds, String baseId) {
    var candidate = baseId.trim().isEmpty
        ? 'expression_binding'
        : baseId.trim();
    var index = 1;
    while (existingIds.contains(candidate)) {
      candidate =
          '${baseId.trim().isEmpty ? 'expression_binding' : baseId.trim()}_$index';
      index += 1;
    }
    existingIds.add(candidate);
    return candidate;
  }

  double _ratio(Object? value, double fallback) {
    final resolved = ValueReaders.doubleValue(value, fallback);
    return resolved <= 0 ? fallback : resolved;
  }
}
