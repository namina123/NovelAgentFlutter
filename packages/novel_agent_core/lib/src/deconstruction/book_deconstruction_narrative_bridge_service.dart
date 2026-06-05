import '../assets/character_profile.dart';
import '../assets/organization_profile.dart';
import '../assets/style_profile.dart';
import '../assets/world_rule_set.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../continuity/narrative_state/narrative_profile_lifecycle_status.dart';
import '../continuity/narrative_state/narrative_profile_patch.dart';
import '../continuity/narrative_state/narrative_profile_proposal.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import '../continuity/narrative_state/narrative_reference_constants.dart';
import '../continuity/narrative_state/narrative_semantic_review.dart';
import '../continuity/narrative_state/narrative_source_ref.dart';
import '../continuity/narrative_state/narrative_state_claim.dart';
import '../continuity/narrative_state/semantic_review_finding.dart';
import '../continuity/narrative_state/semantic_review_recommended_disposition.dart';
import '../continuity/narrative_state/semantic_review_severity.dart';
import '../inspiration/inspiration_premise.dart';
import 'book_deconstruction_chapter_outline.dart';
import 'book_deconstruction_continuity_hints.dart';
import 'book_deconstruction_coverage_hint.dart';
import 'book_deconstruction_extraction_result.dart';
import 'book_deconstruction_hint_source_kind.dart';
import 'book_deconstruction_identity_mapping_hint.dart';
import 'book_deconstruction_input.dart';
import 'book_deconstruction_mechanic_hint.dart';
import 'book_deconstruction_information_bridge_service.dart';
import 'book_deconstruction_narrative_artifact_bundle.dart';
import 'book_deconstruction_narrative_bridge_constants.dart';
import 'book_deconstruction_scope_hint.dart';

class BookDeconstructionNarrativeBridgeService {
  const BookDeconstructionNarrativeBridgeService({
    BookDeconstructionInformationBridgeService informationBridgeService =
        const BookDeconstructionInformationBridgeService(),
  }) : _informationBridgeService = informationBridgeService;

  final BookDeconstructionInformationBridgeService _informationBridgeService;

  BookDeconstructionNarrativeArtifactBundle build({
    required BookDeconstructionInput input,
    required BookDeconstructionExtractionResult extractionResult,
  }) {
    final directSource = NarrativeSourceRef(
      sourceType: NarrativeSourceTypes.deconstruction,
      sourceId: extractionResult.extractionId,
      label: extractionResult.sourceTitle,
      description: '拆书直接抽取结果',
      metadata: <String, Object?>{
        'mode_id': extractionResult.modeId,
        'project_strategy_id': extractionResult.projectStrategyId,
      },
    );
    final interpretedSource = NarrativeSourceRef(
      sourceType: NarrativeSourceTypes.explainerInterpreted,
      sourceId: 'explainer_${extractionResult.extractionId}',
      label: '${extractionResult.sourceTitle} 分析解释桥',
      description: '拆书/解书分析后的解释性叙事状态桥',
      metadata: <String, Object?>{
        'mode_id': extractionResult.modeId,
        'project_strategy_id': extractionResult.projectStrategyId,
      },
    );
    final primaryDocumentRef = _primaryDocumentRef(input);
    final claims = <NarrativeStateClaim>[
      ...extractionResult.premises.map(
        (premise) => _premiseClaim(
          premise: premise,
          extractionId: extractionResult.extractionId,
          source: directSource,
          primaryDocumentRef: primaryDocumentRef,
          sourceTitle: extractionResult.sourceTitle,
        ),
      ),
      if (extractionResult.storyOutlineSummary.trim().isNotEmpty)
        _storyOutlineClaim(
          extractionResult: extractionResult,
          source: directSource,
          primaryDocumentRef: primaryDocumentRef,
        ),
      ...extractionResult.chapterOutlines.map(
        (outline) => _chapterOutlineClaim(
          extractionId: extractionResult.extractionId,
          outline: outline,
          source: directSource,
          primaryDocumentRef: primaryDocumentRef,
        ),
      ),
      ...extractionResult.styleProfiles.map(
        (profile) => _styleProfileClaim(
          extractionId: extractionResult.extractionId,
          profile: profile,
          source: directSource,
          primaryDocumentRef: primaryDocumentRef,
        ),
      ),
      ...extractionResult.worldRuleSets.map(
        (ruleSet) => _worldRuleSetClaim(
          extractionId: extractionResult.extractionId,
          ruleSet: ruleSet,
          source: directSource,
          primaryDocumentRef: primaryDocumentRef,
        ),
      ),
      ...extractionResult.characterProfiles.map(
        (profile) => _characterProfileClaim(
          extractionId: extractionResult.extractionId,
          profile: profile,
          source: directSource,
          primaryDocumentRef: primaryDocumentRef,
        ),
      ),
      ...extractionResult.organizationProfiles.map(
        (profile) => _organizationProfileClaim(
          extractionId: extractionResult.extractionId,
          profile: profile,
          source: directSource,
          primaryDocumentRef: primaryDocumentRef,
        ),
      ),
      ..._continuityClaims(
        extractionId: extractionResult.extractionId,
        continuityHints: extractionResult.continuityHints,
        directSource: directSource,
        interpretedSource: interpretedSource,
        primaryDocumentRef: primaryDocumentRef,
      ),
    ];

    final proposal = _profileProposal(
      input: input,
      extractionResult: extractionResult,
      claims: claims,
      source: interpretedSource,
    );
    final review = _semanticReview(
      extractionResult: extractionResult,
      claims: claims,
      proposal: proposal,
      source: interpretedSource,
      primaryDocumentRef: primaryDocumentRef,
    );
    final informationArtifacts = _informationBridgeService.build(
      input: input,
      extractionResult: extractionResult,
    );

    return BookDeconstructionNarrativeArtifactBundle(
      claims: List<NarrativeStateClaim>.unmodifiable(claims),
      profileProposals: List<NarrativeProfileProposal>.unmodifiable(
        <NarrativeProfileProposal>[proposal],
      ),
      semanticReviews: List<NarrativeSemanticReview>.unmodifiable(
        <NarrativeSemanticReview>[review],
      ),
      knowledgeCards: informationArtifacts.knowledgeCards,
      designElements: informationArtifacts.designElements,
      researchNotes: informationArtifacts.researchNotes,
      referenceWorks: informationArtifacts.referenceWorks,
      metadata: <String, Object?>{
        ...informationArtifacts.metadata,
        'analysis_namespace_roots': <String>[
          'analysis.deconstruction',
          'analysis.explainer',
        ],
        'promotion_path': BookDeconstructionNarrativeBridgeConstants
            .promotionPathUserOrPolicy,
        'source_title': extractionResult.sourceTitle,
        'extraction_id': extractionResult.extractionId,
      },
    );
  }

  NarrativeStateClaim _premiseClaim({
    required InspirationPremise premise,
    required String extractionId,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
    required String sourceTitle,
  }) {
    final claimId = 'claim_${extractionId}_premise_${_safeSuffix(premise.id)}';
    return _claim(
      claimId: claimId,
      claimNamespace: 'analysis.deconstruction.premise',
      claimLabel: premise.displayName.trim().isEmpty
          ? '核心前提'
          : premise.displayName,
      targetNamespace: 'continuity.foundation.premise',
      source: source,
      confidence: 0.88,
      payload: <String, Object?>{
        'premise_id': premise.id,
        'display_name': premise.displayName,
        'summary': premise.summary,
        'source_path': premise.sourcePath,
        'source_title': sourceTitle,
      },
      affectedRefs: <NarrativeRef>[primaryDocumentRef],
      evidenceSummary: premise.summary,
    );
  }

  NarrativeStateClaim _storyOutlineClaim({
    required BookDeconstructionExtractionResult extractionResult,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    final claimId = 'claim_${extractionResult.extractionId}_story_outline';
    return _claim(
      claimId: claimId,
      claimNamespace: 'analysis.deconstruction.story_outline',
      claimLabel: '故事总纲提要',
      targetNamespace: 'continuity.foundation.story_outline',
      source: source,
      confidence: 0.84,
      payload: <String, Object?>{
        'source_title': extractionResult.sourceTitle,
        'summary': extractionResult.storyOutlineSummary,
      },
      affectedRefs: <NarrativeRef>[primaryDocumentRef],
      evidenceSummary: extractionResult.storyOutlineSummary,
    );
  }

  NarrativeStateClaim _chapterOutlineClaim({
    required String extractionId,
    required BookDeconstructionChapterOutline outline,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    final chapterRef = NarrativeRef(
      refType: NarrativeRefTypes.chapter,
      refId: outline.id,
      displayName: outline.title,
      chapterId: outline.id,
      metadata: <String, Object?>{'sequence': outline.sequence},
    );
    return _claim(
      claimId: 'claim_${extractionId}_${outline.id}',
      claimNamespace: 'analysis.deconstruction.chapter_outline',
      claimLabel: outline.title,
      targetNamespace: 'continuity.foundation.chapter_outline',
      source: source,
      confidence: 0.8,
      payload: <String, Object?>{
        'chapter_id': outline.id,
        'sequence': outline.sequence,
        'title': outline.title,
        'summary': outline.summary,
      },
      affectedRefs: <NarrativeRef>[chapterRef],
      contextRefs: <NarrativeRef>[primaryDocumentRef],
      evidenceSummary: outline.summary,
    );
  }

  NarrativeStateClaim _styleProfileClaim({
    required String extractionId,
    required StyleProfile profile,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    return _assetClaim(
      claimId: 'claim_${extractionId}_style_${_safeSuffix(profile.id)}',
      claimNamespace: 'analysis.deconstruction.style_profile',
      claimLabel: profile.displayName,
      targetNamespace: 'continuity.foundation.style_profile',
      assetKind: 'style_profile',
      assetId: profile.id,
      source: source,
      confidence: 0.8,
      payload: <String, Object?>{
        'profile_id': profile.id,
        'display_name': profile.displayName,
        'summary': profile.summary,
      },
      primaryDocumentRef: primaryDocumentRef,
      evidenceSummary: profile.summary,
    );
  }

  NarrativeStateClaim _worldRuleSetClaim({
    required String extractionId,
    required WorldRuleSet ruleSet,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    return _assetClaim(
      claimId: 'claim_${extractionId}_world_${_safeSuffix(ruleSet.id)}',
      claimNamespace: 'analysis.deconstruction.world_rule_set',
      claimLabel: ruleSet.displayName,
      targetNamespace: 'continuity.foundation.world_rule_set',
      assetKind: 'world_rule_set',
      assetId: ruleSet.id,
      source: source,
      confidence: 0.82,
      payload: <String, Object?>{
        'rule_set_id': ruleSet.id,
        'display_name': ruleSet.displayName,
        'summary': ruleSet.summary,
        'rules': ruleSet.rules,
      },
      primaryDocumentRef: primaryDocumentRef,
      evidenceSummary: ruleSet.summary,
    );
  }

  NarrativeStateClaim _characterProfileClaim({
    required String extractionId,
    required CharacterProfile profile,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    return _assetClaim(
      claimId: 'claim_${extractionId}_character_${_safeSuffix(profile.id)}',
      claimNamespace: 'analysis.deconstruction.character_profile',
      claimLabel: profile.displayName,
      targetNamespace: 'continuity.foundation.character_profile',
      assetKind: 'character_profile',
      assetId: profile.id,
      source: source,
      confidence: 0.83,
      payload: <String, Object?>{
        'character_id': profile.id,
        'display_name': profile.displayName,
        'summary': profile.summary,
      },
      primaryDocumentRef: primaryDocumentRef,
      evidenceSummary: profile.summary,
    );
  }

  NarrativeStateClaim _organizationProfileClaim({
    required String extractionId,
    required OrganizationProfile profile,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    return _assetClaim(
      claimId: 'claim_${extractionId}_organization_${_safeSuffix(profile.id)}',
      claimNamespace: 'analysis.deconstruction.organization_profile',
      claimLabel: profile.displayName,
      targetNamespace: 'continuity.foundation.organization_profile',
      assetKind: 'organization_profile',
      assetId: profile.id,
      source: source,
      confidence: 0.8,
      payload: <String, Object?>{
        'organization_id': profile.id,
        'display_name': profile.displayName,
        'summary': profile.summary,
      },
      primaryDocumentRef: primaryDocumentRef,
      evidenceSummary: profile.summary,
    );
  }

  List<NarrativeStateClaim> _continuityClaims({
    required String extractionId,
    required BookDeconstructionContinuityHints continuityHints,
    required NarrativeSourceRef directSource,
    required NarrativeSourceRef interpretedSource,
    required NarrativeRef primaryDocumentRef,
  }) {
    final claims = <NarrativeStateClaim>[];
    final coverage = continuityHints.coverage;
    if (coverage.sourceLabel.trim().isNotEmpty ||
        coverage.sourcePaths.isNotEmpty ||
        coverage.sourceRanges.isNotEmpty ||
        coverage.notes.trim().isNotEmpty) {
      claims.add(
        _continuityCoverageClaim(
          extractionId: extractionId,
          coverage: coverage,
          source: _sourceForHint(
            coverage.sourceRanges.any(
                  (item) =>
                      item.sourceKind ==
                      BookDeconstructionHintSourceKind.inferredHint,
                )
                ? BookDeconstructionHintSourceKind.inferredHint
                : BookDeconstructionHintSourceKind.sourceFact,
            directSource: directSource,
            interpretedSource: interpretedSource,
          ),
          primaryDocumentRef: primaryDocumentRef,
        ),
      );
    }
    claims.addAll(
      continuityHints.scopeMap.scopes.map(
        (scope) => _scopeClaim(
          extractionId: extractionId,
          scope: scope,
          source: _sourceForHint(
            scope.sourceKind,
            directSource: directSource,
            interpretedSource: interpretedSource,
          ),
          primaryDocumentRef: primaryDocumentRef,
        ),
      ),
    );
    claims.addAll(
      continuityHints.identityMappings.map(
        (mapping) => _identityMappingClaim(
          extractionId: extractionId,
          mapping: mapping,
          source: _sourceForHint(
            mapping.sourceKind,
            directSource: directSource,
            interpretedSource: interpretedSource,
          ),
          primaryDocumentRef: primaryDocumentRef,
        ),
      ),
    );
    claims.addAll(
      continuityHints.mechanicHints.map(
        (hint) => _mechanicHintClaim(
          extractionId: extractionId,
          hint: hint,
          source: _sourceForHint(
            hint.sourceKind,
            directSource: directSource,
            interpretedSource: interpretedSource,
          ),
          primaryDocumentRef: primaryDocumentRef,
        ),
      ),
    );
    return claims;
  }

  NarrativeStateClaim _continuityCoverageClaim({
    required String extractionId,
    required BookDeconstructionCoverageHint coverage,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    final analysisNamespace = _analysisNamespaceForSource(
      source,
      directNamespace: 'analysis.deconstruction.continuity.coverage',
      interpretedNamespace: 'analysis.explainer.continuity.coverage',
    );
    return _claim(
      claimId: 'claim_${extractionId}_continuity_coverage',
      claimNamespace: analysisNamespace,
      claimLabel: '连续性覆盖提示',
      targetNamespace: 'continuity.foundation.coverage',
      source: source,
      confidence: source.sourceType == NarrativeSourceTypes.explainerInterpreted
          ? 0.65
          : 0.78,
      payload: <String, Object?>{
        'source_label': coverage.sourceLabel,
        'source_paths': coverage.sourcePaths,
        'chapter_start': coverage.chapterStart,
        'chapter_end': coverage.chapterEnd,
        'is_partial': coverage.isPartial,
        'source_ranges': coverage.sourceRanges
            .map(
              (item) => <String, Object?>{
                'range_id': item.id,
                'display_name': item.displayName,
                'chapter_start': item.chapterStart,
                'chapter_end': item.chapterEnd,
                'source_paths': item.sourcePaths,
                'source_kind': item.sourceKind.name,
                'notes': item.notes,
                'metadata': ValueReaders.deepCopyMap(item.metadata),
              },
            )
            .toList(growable: false),
        'notes': coverage.notes,
        'metadata': ValueReaders.deepCopyMap(coverage.metadata),
      },
      affectedRefs: <NarrativeRef>[primaryDocumentRef],
      evidenceSummary: coverage.notes.trim().isNotEmpty
          ? coverage.notes
          : coverage.sourceLabel,
    );
  }

  NarrativeStateClaim _scopeClaim({
    required String extractionId,
    required BookDeconstructionScopeHint scope,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    final analysisNamespace = _analysisNamespaceForSource(
      source,
      directNamespace: 'analysis.deconstruction.continuity.scope',
      interpretedNamespace: 'analysis.explainer.continuity.scope',
    );
    return _claim(
      claimId: 'claim_${extractionId}_scope_${_safeSuffix(scope.id)}',
      claimNamespace: analysisNamespace,
      claimLabel: scope.displayName,
      targetNamespace: 'continuity.foundation.scope',
      source: source,
      confidence: source.sourceType == NarrativeSourceTypes.explainerInterpreted
          ? 0.62
          : 0.77,
      payload: <String, Object?>{
        'scope_id': scope.id,
        'display_name': scope.displayName,
        'scope_kind': scope.scopeKind.name,
        'parent_scope_id': scope.parentScopeId,
        'chapter_start': scope.chapterStart,
        'chapter_end': scope.chapterEnd,
        'source_paths': scope.sourcePaths,
        'source_kind': scope.sourceKind.name,
        'notes': scope.notes,
        'metadata': ValueReaders.deepCopyMap(scope.metadata),
      },
      affectedRefs: <NarrativeRef>[
        NarrativeRef(
          refType: NarrativeRefTypes.segment,
          refId: scope.id,
          displayName: scope.displayName,
          metadata: <String, Object?>{'scope_kind': scope.scopeKind.name},
        ),
      ],
      contextRefs: <NarrativeRef>[primaryDocumentRef],
      evidenceSummary: scope.notes.trim().isNotEmpty
          ? scope.notes
          : scope.displayName,
    );
  }

  NarrativeStateClaim _identityMappingClaim({
    required String extractionId,
    required BookDeconstructionIdentityMappingHint mapping,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    final analysisNamespace = _analysisNamespaceForSource(
      source,
      directNamespace: 'analysis.deconstruction.continuity.identity_mapping',
      interpretedNamespace: 'analysis.explainer.continuity.identity_mapping',
    );
    return _claim(
      claimId: 'claim_${extractionId}_identity_${_safeSuffix(mapping.id)}',
      claimNamespace: analysisNamespace,
      claimLabel: mapping.scopedDisplayName.trim().isEmpty
          ? mapping.scopedEntityId
          : mapping.scopedDisplayName,
      targetNamespace: 'continuity.foundation.identity_mapping',
      source: source,
      confidence: source.sourceType == NarrativeSourceTypes.explainerInterpreted
          ? 0.61
          : 0.76,
      payload: <String, Object?>{
        'mapping_id': mapping.id,
        'canonical_entity_id': mapping.canonicalEntityId,
        'scoped_entity_id': mapping.scopedEntityId,
        'scoped_display_name': mapping.scopedDisplayName,
        'scope_hint_id': mapping.scopeHintId,
        'chapter_start': mapping.chapterStart,
        'chapter_end': mapping.chapterEnd,
        'source_paths': mapping.sourcePaths,
        'source_kind': mapping.sourceKind.name,
        'mapping_reason': mapping.mappingReason,
        'notes': mapping.notes,
        'metadata': ValueReaders.deepCopyMap(mapping.metadata),
      },
      affectedRefs: <NarrativeRef>[
        NarrativeRef(
          refType: NarrativeRefTypes.asset,
          refId: mapping.canonicalEntityId,
          displayName: mapping.scopedDisplayName,
          metadata: <String, Object?>{
            'scoped_entity_id': mapping.scopedEntityId,
            'scope_hint_id': mapping.scopeHintId,
          },
        ),
      ],
      contextRefs: <NarrativeRef>[primaryDocumentRef],
      evidenceSummary: mapping.mappingReason.trim().isNotEmpty
          ? mapping.mappingReason
          : mapping.notes,
    );
  }

  NarrativeStateClaim _mechanicHintClaim({
    required String extractionId,
    required BookDeconstructionMechanicHint hint,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    final analysisNamespace = _analysisNamespaceForSource(
      source,
      directNamespace: 'analysis.deconstruction.continuity.mechanic_hint',
      interpretedNamespace: 'analysis.explainer.continuity.mechanic_hint',
    );
    return _claim(
      claimId: 'claim_${extractionId}_mechanic_${_safeSuffix(hint.id)}',
      claimNamespace: analysisNamespace,
      claimLabel: hint.displayName,
      targetNamespace: 'continuity.foundation.mechanic_hint',
      source: source,
      confidence: source.sourceType == NarrativeSourceTypes.explainerInterpreted
          ? 0.58
          : 0.74,
      payload: <String, Object?>{
        'mechanic_hint_id': hint.id,
        'display_name': hint.displayName,
        'scope_hint_id': hint.scopeHintId,
        'identity_mode_hint': hint.identityModeHint?.name ?? '',
        'memory_mode_hint': hint.memoryModeHint?.name ?? '',
        'state_mode_hint': hint.stateModeHint?.name ?? '',
        'causal_mode_hint': hint.causalModeHint?.name ?? '',
        'branch_mode_hint': hint.branchModeHint?.name ?? '',
        'visibility_mode_hint': hint.visibilityModeHint?.name ?? '',
        'chapter_start': hint.chapterStart,
        'chapter_end': hint.chapterEnd,
        'source_paths': hint.sourcePaths,
        'source_kind': hint.sourceKind.name,
        'notes': hint.notes,
        'metadata': ValueReaders.deepCopyMap(hint.metadata),
      },
      affectedRefs: <NarrativeRef>[
        NarrativeRef(
          refType: NarrativeRefTypes.segment,
          refId: hint.id,
          displayName: hint.displayName,
          metadata: <String, Object?>{'scope_hint_id': hint.scopeHintId},
        ),
      ],
      contextRefs: <NarrativeRef>[primaryDocumentRef],
      evidenceSummary: hint.notes.trim().isNotEmpty
          ? hint.notes
          : hint.displayName,
    );
  }

  NarrativeProfileProposal _profileProposal({
    required BookDeconstructionInput input,
    required BookDeconstructionExtractionResult extractionResult,
    required List<NarrativeStateClaim> claims,
    required NarrativeSourceRef source,
  }) {
    final proposalId =
        'proposal_${extractionResult.extractionId}_continuation_foundation';
    final targetProfileId =
        'continuation_foundation_${extractionResult.extractionId}';
    return NarrativeProfileProposal(
      proposalId: proposalId,
      proposalStatus: NarrativeProfileLifecycleStatus.proposed,
      targetProfileId: targetProfileId,
      baseProfileId: '',
      requiresUserConfirmation: true,
      reason: extractionResult.continuityHints.hasInferredHints
          ? '拆书分析包含解释性连续性推断，进入正式续写前需要用户确认。'
          : '拆书 foundation build 已形成续写解释器草案，建议用户确认后再提升到正式规则。',
      confidence: extractionResult.continuityHints.hasInferredHints
          ? 0.65
          : 0.78,
      source: source,
      profilePatch: NarrativeProfilePatch(
        patchId:
            'patch_${extractionResult.extractionId}_continuation_foundation',
        patchLabel: '拆书续写底稿解释器草案',
        patchPayload: <String, Object?>{
          'source_title': extractionResult.sourceTitle,
          'story_outline_summary': extractionResult.storyOutlineSummary,
          'premises': extractionResult.premises
              .map(
                (item) => <String, Object?>{
                  'id': item.id,
                  'display_name': item.displayName,
                  'summary': item.summary,
                },
              )
              .toList(growable: false),
          'style_profiles': extractionResult.styleProfiles
              .map(_styleProfilePayload)
              .toList(growable: false),
          'world_rule_sets': extractionResult.worldRuleSets
              .map(_worldRuleSetPayload)
              .toList(growable: false),
          'character_profiles': extractionResult.characterProfiles
              .map(_characterProfilePayload)
              .toList(growable: false),
          'organization_profiles': extractionResult.organizationProfiles
              .map(_organizationProfilePayload)
              .toList(growable: false),
          'continuity_hints': _continuityHintPayload(
            extractionResult.continuityHints,
          ),
          'operator_notes': input.operatorNotes,
        },
        patchExtensions: <String, Object?>{
          'analysis_claim_ids': claims
              .map((claim) => claim.claimId)
              .toList(growable: false),
          'source_document_ids': input.sourceDocuments
              .map((entry) => entry.id)
              .toList(growable: false),
        },
        source: source,
        confidence: extractionResult.continuityHints.hasInferredHints
            ? 0.65
            : 0.78,
        reason: '把拆书基础抽取整理为续写可消费的项目解释器草案。',
        metadata: <String, Object?>{
          BookDeconstructionNarrativeBridgeConstants.metadataAnalysisNamespace:
              'analysis.explainer.profile.continuation_foundation',
          BookDeconstructionNarrativeBridgeConstants
                  .metadataPromotionTargetProfileNamespace:
              'continuity.foundation.interpreter',
          BookDeconstructionNarrativeBridgeConstants
                  .metadataPromotionTargetProfileId:
              targetProfileId,
          BookDeconstructionNarrativeBridgeConstants.metadataAnalysisStatus:
              BookDeconstructionNarrativeBridgeConstants.proposedStatus,
          BookDeconstructionNarrativeBridgeConstants.metadataPromotionPath:
              BookDeconstructionNarrativeBridgeConstants
                  .promotionPathUserOrPolicy,
          BookDeconstructionNarrativeBridgeConstants
                  .metadataInheritedByDerivedProjects:
              true,
        },
      ),
      metadata: <String, Object?>{
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisNamespace:
            'analysis.explainer.profile.continuation_foundation',
        BookDeconstructionNarrativeBridgeConstants
                .metadataPromotionTargetProfileNamespace:
            'continuity.foundation.interpreter',
        BookDeconstructionNarrativeBridgeConstants
                .metadataPromotionTargetProfileId:
            targetProfileId,
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisStatus:
            BookDeconstructionNarrativeBridgeConstants.proposedStatus,
        BookDeconstructionNarrativeBridgeConstants.metadataPromotionPath:
            BookDeconstructionNarrativeBridgeConstants
                .promotionPathUserOrPolicy,
        BookDeconstructionNarrativeBridgeConstants
                .metadataInheritedByDerivedProjects:
            true,
      },
    );
  }

  NarrativeSemanticReview _semanticReview({
    required BookDeconstructionExtractionResult extractionResult,
    required List<NarrativeStateClaim> claims,
    required NarrativeProfileProposal proposal,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    final inferredClaimIds = claims
        .where(
          (claim) =>
              claim.source.sourceType ==
              NarrativeSourceTypes.explainerInterpreted,
        )
        .map((claim) => claim.claimId)
        .toList(growable: false);
    final directClaimIds = claims
        .where(
          (claim) =>
              claim.source.sourceType == NarrativeSourceTypes.deconstruction,
        )
        .map((claim) => claim.claimId)
        .toList(growable: false);
    final findings = <SemanticReviewFinding>[
      if (extractionResult.continuityHints.hasInferredHints)
        SemanticReviewFinding(
          findingId: 'finding_${extractionResult.extractionId}_inferred_hints',
          severity: SemanticReviewSeverity.medium,
          summary: '连续性提示中包含解释性推断，建议在提升为续写规则前先人工确认。',
          evidenceRefs: <NarrativeEvidenceRef>[
            _evidenceRef(
              evidenceId:
                  'snippet_${extractionResult.extractionId}_continuity_hints',
              source: source,
              targetRef: primaryDocumentRef,
              summary: extractionResult.continuityHints.notes,
            ),
          ],
          relatedClaimIds: inferredClaimIds,
          suggestedAction: '保留在 analysis namespace，待用户确认后再 promote。',
          confidence: 0.7,
          metadata: <String, Object?>{'proposal_id': proposal.proposalId},
        ),
      if (extractionResult.worldRuleSets.isEmpty)
        SemanticReviewFinding(
          findingId: 'finding_${extractionResult.extractionId}_missing_world',
          severity: SemanticReviewSeverity.low,
          summary: '当前拆书结果缺少明确世界规则，续写前最好补录关键规则。',
          evidenceRefs: const <NarrativeEvidenceRef>[],
          unableToLocateEvidence: true,
          unlocatableReason: '本轮输入没有显式世界规则提要。',
          confidence: 0.64,
        ),
      if (extractionResult.characterProfiles.isEmpty)
        SemanticReviewFinding(
          findingId:
              'finding_${extractionResult.extractionId}_missing_characters',
          severity: SemanticReviewSeverity.low,
          summary: '当前拆书结果缺少角色画像，派生续写项目时需要补充核心角色状态。',
          evidenceRefs: const <NarrativeEvidenceRef>[],
          unableToLocateEvidence: true,
          unlocatableReason: '本轮输入没有显式角色提要。',
          confidence: 0.64,
        ),
    ];
    return NarrativeSemanticReview(
      reviewId: 'review_${extractionResult.extractionId}_analysis_bridge',
      source: source,
      recommendedDisposition: findings.isEmpty
          ? SemanticReviewRecommendedDisposition.accept
          : SemanticReviewRecommendedDisposition.acceptWithNote,
      targetRefs: <NarrativeRef>[primaryDocumentRef],
      acceptedClaimIds: directClaimIds,
      questionedClaimIds: inferredClaimIds,
      summary: findings.isEmpty
          ? '拆书 foundation build 形成的 claims 可作为续写事实底稿。'
          : '拆书 foundation build 已形成事实底稿，但其中解释性推断应保留在 analysis namespace 等待确认。',
      confidence: findings.isEmpty ? 0.82 : 0.71,
      findings: List<SemanticReviewFinding>.unmodifiable(findings),
      metadata: <String, Object?>{
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisNamespace:
            'analysis.explainer.semantic_review',
        BookDeconstructionNarrativeBridgeConstants
                .metadataPromotionTargetNamespace:
            'continuity.foundation.review',
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisStatus:
            BookDeconstructionNarrativeBridgeConstants.proposedStatus,
        BookDeconstructionNarrativeBridgeConstants.metadataPromotionPath:
            BookDeconstructionNarrativeBridgeConstants
                .promotionPathUserOrPolicy,
        BookDeconstructionNarrativeBridgeConstants
                .metadataInheritedByDerivedProjects:
            true,
        'proposal_id': proposal.proposalId,
      },
    );
  }

  NarrativeStateClaim _assetClaim({
    required String claimId,
    required String claimNamespace,
    required String claimLabel,
    required String targetNamespace,
    required String assetKind,
    required String assetId,
    required NarrativeSourceRef source,
    required double confidence,
    required JsonMap payload,
    required NarrativeRef primaryDocumentRef,
    required String evidenceSummary,
  }) {
    final assetRef = NarrativeRef(
      refType: NarrativeRefTypes.asset,
      refId: assetId,
      displayName: claimLabel,
      metadata: <String, Object?>{'asset_kind': assetKind},
    );
    return _claim(
      claimId: claimId,
      claimNamespace: claimNamespace,
      claimLabel: claimLabel,
      targetNamespace: targetNamespace,
      source: source,
      confidence: confidence,
      payload: payload,
      affectedRefs: <NarrativeRef>[assetRef],
      contextRefs: <NarrativeRef>[primaryDocumentRef],
      evidenceSummary: evidenceSummary,
    );
  }

  NarrativeStateClaim _claim({
    required String claimId,
    required String claimNamespace,
    required String claimLabel,
    required String targetNamespace,
    required NarrativeSourceRef source,
    required double confidence,
    required JsonMap payload,
    required List<NarrativeRef> affectedRefs,
    List<NarrativeRef> contextRefs = const <NarrativeRef>[],
    required String evidenceSummary,
  }) {
    return NarrativeStateClaim(
      claimId: claimId,
      claimNamespace: claimNamespace,
      claimLabel: claimLabel,
      claimPayload: ValueReaders.deepCopyMap(payload),
      affectedRefs: List<NarrativeRef>.unmodifiable(affectedRefs),
      contextRefs: List<NarrativeRef>.unmodifiable(contextRefs),
      evidenceRefs:
          List<NarrativeEvidenceRef>.unmodifiable(<NarrativeEvidenceRef>[
            _evidenceRef(
              evidenceId: 'snippet_$claimId',
              source: source,
              targetRef: contextRefs.isNotEmpty
                  ? contextRefs.first
                  : affectedRefs.first,
              summary: evidenceSummary,
            ),
          ]),
      source: source,
      confidence: confidence,
      uncertainty:
          source.sourceType == NarrativeSourceTypes.explainerInterpreted
          ? '解释性分析结果，提升到正式续写规则前应先确认。'
          : '',
      metadata: <String, Object?>{
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisNamespace:
            claimNamespace,
        BookDeconstructionNarrativeBridgeConstants
                .metadataPromotionTargetNamespace:
            targetNamespace,
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisStatus:
            BookDeconstructionNarrativeBridgeConstants.proposedStatus,
        BookDeconstructionNarrativeBridgeConstants.metadataPromotionPath:
            BookDeconstructionNarrativeBridgeConstants
                .promotionPathUserOrPolicy,
        BookDeconstructionNarrativeBridgeConstants
                .metadataInheritedByDerivedProjects:
            true,
      },
    );
  }

  NarrativeEvidenceRef _evidenceRef({
    required String evidenceId,
    required NarrativeSourceRef source,
    required NarrativeRef targetRef,
    required String summary,
  }) {
    return NarrativeEvidenceRef(
      evidenceType: NarrativeEvidenceTypes.extractedSnippet,
      evidenceId: evidenceId,
      sourceRef: source,
      targetRef: targetRef,
      summary: summary.trim(),
    );
  }

  NarrativeSourceRef _sourceForHint(
    BookDeconstructionHintSourceKind sourceKind, {
    required NarrativeSourceRef directSource,
    required NarrativeSourceRef interpretedSource,
  }) {
    return sourceKind == BookDeconstructionHintSourceKind.inferredHint
        ? interpretedSource
        : directSource;
  }

  NarrativeRef _primaryDocumentRef(BookDeconstructionInput input) {
    if (input.sourceDocuments.isEmpty) {
      return const NarrativeRef(
        refType: NarrativeRefTypes.externalImportSnippet,
        refId: 'source_document_missing',
        displayName: '拆书源文稿',
      );
    }
    final document = input.sourceDocuments.first;
    return NarrativeRef(
      refType: NarrativeRefTypes.externalImportSnippet,
      refId: document.id,
      displayName: document.title,
      relativePath: document.relativePathHint,
      sourcePath: document.relativePathHint,
      metadata: <String, Object?>{
        'media_type': document.mediaType,
        'sequence': document.sequence,
      },
    );
  }

  String _analysisNamespaceForSource(
    NarrativeSourceRef source, {
    required String directNamespace,
    required String interpretedNamespace,
  }) {
    return source.sourceType == NarrativeSourceTypes.explainerInterpreted
        ? interpretedNamespace
        : directNamespace;
  }

  JsonMap _styleProfilePayload(StyleProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'display_name': profile.displayName,
      'summary': profile.summary,
    };
  }

  JsonMap _worldRuleSetPayload(WorldRuleSet ruleSet) {
    return <String, Object?>{
      'id': ruleSet.id,
      'display_name': ruleSet.displayName,
      'summary': ruleSet.summary,
      'rules': ruleSet.rules,
    };
  }

  JsonMap _characterProfilePayload(CharacterProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'display_name': profile.displayName,
      'summary': profile.summary,
    };
  }

  JsonMap _organizationProfilePayload(OrganizationProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'display_name': profile.displayName,
      'summary': profile.summary,
    };
  }

  JsonMap _continuityHintPayload(BookDeconstructionContinuityHints hints) {
    return <String, Object?>{
      'coverage': <String, Object?>{
        'source_label': hints.coverage.sourceLabel,
        'source_paths': hints.coverage.sourcePaths,
        'chapter_start': hints.coverage.chapterStart,
        'chapter_end': hints.coverage.chapterEnd,
        'is_partial': hints.coverage.isPartial,
        'notes': hints.coverage.notes,
      },
      'scopes': hints.scopeMap.scopes
          .map(
            (scope) => <String, Object?>{
              'id': scope.id,
              'display_name': scope.displayName,
              'scope_kind': scope.scopeKind.name,
              'parent_scope_id': scope.parentScopeId,
              'source_kind': scope.sourceKind.name,
              'notes': scope.notes,
            },
          )
          .toList(growable: false),
      'identity_mappings': hints.identityMappings
          .map(
            (mapping) => <String, Object?>{
              'id': mapping.id,
              'canonical_entity_id': mapping.canonicalEntityId,
              'scoped_entity_id': mapping.scopedEntityId,
              'scoped_display_name': mapping.scopedDisplayName,
              'scope_hint_id': mapping.scopeHintId,
              'source_kind': mapping.sourceKind.name,
              'mapping_reason': mapping.mappingReason,
              'notes': mapping.notes,
            },
          )
          .toList(growable: false),
      'mechanic_hints': hints.mechanicHints
          .map(
            (hint) => <String, Object?>{
              'id': hint.id,
              'display_name': hint.displayName,
              'scope_hint_id': hint.scopeHintId,
              'source_kind': hint.sourceKind.name,
              'notes': hint.notes,
            },
          )
          .toList(growable: false),
      'notes': hints.notes,
      'has_inferred_hints': hints.hasInferredHints,
    };
  }

  String _safeSuffix(String value) {
    final clean = value.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_\u4e00-\u9fa5]+'),
      '_',
    );
    if (clean.isEmpty) {
      return 'item';
    }
    return clean;
  }
}
