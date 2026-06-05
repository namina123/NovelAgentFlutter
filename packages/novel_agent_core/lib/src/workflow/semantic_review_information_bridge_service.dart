import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import '../continuity/narrative_state/narrative_reference_constants.dart';
import '../continuity/narrative_state/narrative_semantic_review.dart';
import '../continuity/narrative_state/narrative_source_ref.dart';
import '../continuity/narrative_state/narrative_state_claim.dart';
import '../continuity/narrative_state/semantic_review_finding.dart';
import '../continuity/narrative_state/semantic_review_severity.dart';
import '../information/design_element_card.dart';
import '../information/information_activation_policy.dart';
import '../information/information_lifecycle_statuses.dart';
import '../information/information_policy_constants.dart';
import '../information/information_source_ref.dart';
import '../information/information_usage_policy.dart';
import '../information/project_knowledge_card.dart';
import '../information/research_note.dart';
import 'analysis_information_bridge_constants.dart';

class SemanticReviewInformationBridgeResult {
  const SemanticReviewInformationBridgeResult({
    this.knowledgeCards = const <ProjectKnowledgeCard>[],
    this.designElements = const <DesignElementCard>[],
    this.researchNotes = const <ResearchNote>[],
    this.metadata = const <String, Object?>{},
  });

  final List<ProjectKnowledgeCard> knowledgeCards;
  final List<DesignElementCard> designElements;
  final List<ResearchNote> researchNotes;
  final JsonMap metadata;

  bool get isEmpty {
    return knowledgeCards.isEmpty &&
        designElements.isEmpty &&
        researchNotes.isEmpty &&
        metadata.isEmpty;
  }
}

class SemanticReviewInformationBridgeService {
  const SemanticReviewInformationBridgeService();

  SemanticReviewInformationBridgeResult build({
    required NarrativeSemanticReview review,
  }) {
    final namespaceRoot = _namespaceRootFor(review.source.sourceType);
    if (namespaceRoot.isEmpty) {
      return const SemanticReviewInformationBridgeResult();
    }
    final knowledgeCards = <ProjectKnowledgeCard>[];
    final designElements = <DesignElementCard>[];
    final researchNotes = <ResearchNote>[];
    for (final claim in review.suggestedClaims) {
      if (_isDesignClaim(claim)) {
        designElements.add(
          _designElementFromClaim(
            review: review,
            claim: claim,
            namespaceRoot: namespaceRoot,
          ),
        );
      } else {
        knowledgeCards.add(
          _knowledgeCardFromClaim(
            review: review,
            claim: claim,
            namespaceRoot: namespaceRoot,
          ),
        );
      }
    }
    for (final finding in review.findings) {
      if (!_shouldBridgeFindingToResearchNote(finding)) {
        continue;
      }
      researchNotes.add(
        _researchNoteFromFinding(
          review: review,
          finding: finding,
          namespaceRoot: namespaceRoot,
        ),
      );
    }
    return SemanticReviewInformationBridgeResult(
      knowledgeCards: List<ProjectKnowledgeCard>.unmodifiable(knowledgeCards),
      designElements: List<DesignElementCard>.unmodifiable(designElements),
      researchNotes: List<ResearchNote>.unmodifiable(researchNotes),
      metadata: <String, Object?>{
        'analysis_namespace_roots': <String>[namespaceRoot],
        AnalysisInformationBridgeConstants.metadataPromotionPath:
            AnalysisInformationBridgeConstants.promotionPathUserOrPolicy,
        'knowledge_card_count': knowledgeCards.length,
        'design_element_count': designElements.length,
        'research_note_count': researchNotes.length,
      },
    );
  }

  ProjectKnowledgeCard _knowledgeCardFromClaim({
    required NarrativeSemanticReview review,
    required NarrativeStateClaim claim,
    required String namespaceRoot,
  }) {
    final namespaceTail = _namespaceTail(
      claim.claimNamespace,
      fallback: 'suggested_claim',
      droppingSegments: const <String>{'analysis', 'review', 'explainer'},
    );
    return ProjectKnowledgeCard(
      cardId: 'knowledge_${_safeId(review.reviewId)}_${_safeId(claim.claimId)}',
      cardNamespace: '$namespaceRoot.knowledge.$namespaceTail',
      cardType: _claimCardType(claim),
      title: claim.claimLabel.trim().isEmpty
          ? _titleFromNamespace(namespaceTail, fallback: '分析知识提案')
          : claim.claimLabel,
      summary: _claimSummary(claim),
      contentPayload: <String, Object?>{
        ...ValueReaders.deepCopyMap(claim.claimPayload),
        'claim_namespace': claim.claimNamespace,
        'claim_id': claim.claimId,
      },
      sourceRefs: <InformationSourceRef>[_analysisSourceRef(review.source)],
      evidenceRefs: List<NarrativeEvidenceRef>.unmodifiable(claim.evidenceRefs),
      scopeRefs: _scopeRefsForClaim(review, claim),
      activationPolicy: _activationPolicy(),
      usagePolicy: _analysisUsagePolicy(),
      confidence: claim.confidence,
      lifecycleStatus: InformationLifecycleStatuses.proposed,
      metadata: _bridgeMetadata(
        analysisNamespace: '$namespaceRoot.knowledge.$namespaceTail',
        promotionTargetNamespace:
            '${AnalysisInformationBridgeConstants.writingNamespaceRoot}.knowledge.$namespaceTail',
        review: review,
        bridgedFromClaimId: claim.claimId,
      ),
    );
  }

  DesignElementCard _designElementFromClaim({
    required NarrativeSemanticReview review,
    required NarrativeStateClaim claim,
    required String namespaceRoot,
  }) {
    final namespaceTail = _namespaceTail(
      claim.claimNamespace,
      fallback: 'suggested_pattern',
      droppingSegments: const <String>{
        'analysis',
        'review',
        'explainer',
        'design',
      },
    );
    return DesignElementCard(
      designId: 'design_${_safeId(review.reviewId)}_${_safeId(claim.claimId)}',
      designNamespace: '$namespaceRoot.design.$namespaceTail',
      designLabel: claim.claimLabel.trim().isEmpty
          ? _titleFromNamespace(namespaceTail, fallback: '分析设计提案')
          : claim.claimLabel,
      designPayload: <String, Object?>{
        'design_kind': _designKind(claim),
        'claim_namespace': claim.claimNamespace,
        'claim_id': claim.claimId,
        ...ValueReaders.deepCopyMap(claim.claimPayload),
      },
      sourceRefs: <InformationSourceRef>[_analysisSourceRef(review.source)],
      evidenceRefs: List<NarrativeEvidenceRef>.unmodifiable(claim.evidenceRefs),
      scopeRefs: _scopeRefsForClaim(review, claim),
      linkedRefs: List<NarrativeRef>.unmodifiable(claim.affectedRefs),
      activationPolicy: _activationPolicy(),
      usagePolicy: _analysisUsagePolicy(),
      confidence: claim.confidence,
      uncertainty: claim.uncertainty.trim().isEmpty
          ? '解释性/审稿分析提案，提升到写作长期规则前应先确认。'
          : claim.uncertainty,
      lifecycleStatus: InformationLifecycleStatuses.proposed,
      metadata: _bridgeMetadata(
        analysisNamespace: '$namespaceRoot.design.$namespaceTail',
        promotionTargetNamespace:
            '${AnalysisInformationBridgeConstants.writingNamespaceRoot}.design.$namespaceTail',
        review: review,
        bridgedFromClaimId: claim.claimId,
      ),
    );
  }

  ResearchNote _researchNoteFromFinding({
    required NarrativeSemanticReview review,
    required SemanticReviewFinding finding,
    required String namespaceRoot,
  }) {
    final linkedRefs = <NarrativeRef>[
      ...review.targetRefs,
      ...finding.evidenceRefs
          .map((entry) => entry.targetRef)
          .whereType<NarrativeRef>(),
    ];
    return ResearchNote(
      researchId:
          'research_${_safeId(review.reviewId)}_${_safeId(finding.findingId)}',
      query: '分析复核待确认：${finding.summary}',
      sourceKind: 'analysis_review_finding',
      sourceUrlOrRef: review.reviewId,
      citation: review.source.label.trim().isNotEmpty
          ? review.source.label
          : review.source.sourceId,
      summary: finding.summary,
      usableFacts: _usableFactsFromFinding(finding),
      creativeSuggestions: finding.suggestedAction.trim().isEmpty
          ? const <Object?>[]
          : <Object?>[finding.suggestedAction],
      uncertainty: finding.unableToLocateEvidence
          ? finding.unlocatableReason
          : '解释性/审稿分析结果，提升为写作事实前应先确认。',
      licenseOrUsageNote: '仅作为 analysis namespace 研究提案保留，未自动提升。',
      createdBy: review.source.sourceId.trim().isEmpty
          ? review.source.sourceType
          : review.source.sourceId,
      linkedCards: List<NarrativeRef>.unmodifiable(_dedupeRefs(linkedRefs)),
      usagePolicy: _analysisUsagePolicy(),
      metadata: _bridgeMetadata(
        analysisNamespace: '$namespaceRoot.research.finding',
        promotionTargetNamespace:
            '${AnalysisInformationBridgeConstants.writingNamespaceRoot}.research.finding',
        review: review,
        bridgedFromFindingId: finding.findingId,
      ),
    );
  }

  InformationSourceRef _analysisSourceRef(NarrativeSourceRef source) {
    return InformationSourceRef(
      sourceRef: source,
      sourceAuthority: InformationSourceAuthorities.analysisInterpreted,
      roleAuthority: source.sourceType == NarrativeSourceTypes.reviewer
          ? InformationRoleAuthorities.reviewer
          : InformationRoleAuthorities.explainer,
      researchDepth: InformationResearchDepths.quick,
      metadata: <String, Object?>{
        AnalysisInformationBridgeConstants.metadataPromotionPath:
            AnalysisInformationBridgeConstants.promotionPathUserOrPolicy,
      },
    );
  }

  InformationActivationPolicy _activationPolicy() {
    return const InformationActivationPolicy(
      activationPriority: InformationActivationPriorities.reference,
      preferredBudgetChars: 320,
      requiresExplicitSelection: false,
      metadata: <String, Object?>{'source_namespace': 'analysis'},
    );
  }

  InformationUsagePolicy _analysisUsagePolicy() {
    return const InformationUsagePolicy(
      usageMode: InformationUsageModes.referenceOnly,
      citationRiskLevel: InformationCitationRiskLevels.normal,
      requiresConfirmation: true,
      allowsDerivativeUse: true,
      allowsDirectQuote: false,
      referenceScope: <String, Object?>{
        'source_namespace': 'analysis',
        'writing_namespace': 'separate',
      },
      metadata: <String, Object?>{
        'promotion_path':
            AnalysisInformationBridgeConstants.promotionPathUserOrPolicy,
      },
    );
  }

  JsonMap _bridgeMetadata({
    required String analysisNamespace,
    required String promotionTargetNamespace,
    required NarrativeSemanticReview review,
    String bridgedFromClaimId = '',
    String bridgedFromFindingId = '',
  }) {
    return <String, Object?>{
      AnalysisInformationBridgeConstants.metadataAnalysisNamespace:
          analysisNamespace,
      AnalysisInformationBridgeConstants.metadataAnalysisStatus:
          AnalysisInformationBridgeConstants.proposedStatus,
      AnalysisInformationBridgeConstants.metadataPromotionPath:
          AnalysisInformationBridgeConstants.promotionPathUserOrPolicy,
      AnalysisInformationBridgeConstants.metadataPromotionTargetNamespace:
          promotionTargetNamespace,
      AnalysisInformationBridgeConstants.metadataBridgedFromReviewId:
          review.reviewId,
      if (bridgedFromClaimId.trim().isNotEmpty)
        AnalysisInformationBridgeConstants.metadataBridgedFromClaimId:
            bridgedFromClaimId,
      if (bridgedFromFindingId.trim().isNotEmpty)
        AnalysisInformationBridgeConstants.metadataBridgedFromFindingId:
            bridgedFromFindingId,
      'review_source_type': review.source.sourceType,
    };
  }

  bool _isDesignClaim(NarrativeStateClaim claim) {
    final hintText = <String>[
      claim.claimNamespace,
      claim.claimLabel,
      ValueReaders.stringValue(claim.claimPayload['design_kind']),
      ValueReaders.stringValue(claim.claimPayload['pattern_kind']),
      ValueReaders.stringValue(claim.claimPayload['kind']),
      ValueReaders.stringValue(claim.claimPayload['summary']),
    ].join(' ').toLowerCase();
    return hintText.contains('design') ||
        hintText.contains('pattern') ||
        hintText.contains('symbol') ||
        hintText.contains('motif') ||
        hintText.contains('structure') ||
        hintText.contains('style') ||
        hintText.contains('naming') ||
        hintText.contains('命名') ||
        hintText.contains('结构') ||
        hintText.contains('象征') ||
        hintText.contains('意象');
  }

  bool _shouldBridgeFindingToResearchNote(SemanticReviewFinding finding) {
    if (finding.unableToLocateEvidence) {
      return true;
    }
    if (finding.suggestedAction.trim().isNotEmpty) {
      return true;
    }
    return finding.severity == SemanticReviewSeverity.blocking ||
        finding.severity == SemanticReviewSeverity.high ||
        finding.severity == SemanticReviewSeverity.medium;
  }

  String _claimCardType(NarrativeStateClaim claim) {
    final payloadType = ValueReaders.stringValue(
      claim.claimPayload['card_type'],
    );
    if (payloadType.trim().isNotEmpty) {
      return payloadType.trim();
    }
    final namespaceTail = _namespaceTail(
      claim.claimNamespace,
      fallback: 'analysis_claim',
      droppingSegments: const <String>{'analysis', 'review', 'explainer'},
    );
    return namespaceTail.replaceAll('.', '_');
  }

  String _designKind(NarrativeStateClaim claim) {
    final explicit = ValueReaders.stringValue(
      claim.claimPayload['design_kind'],
    );
    if (explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    final namespace = claim.claimNamespace.toLowerCase();
    if (namespace.contains('style')) {
      return 'style_pattern';
    }
    if (namespace.contains('symbol') || namespace.contains('motif')) {
      return 'symbol_system';
    }
    if (namespace.contains('naming') || claim.claimLabel.contains('命名')) {
      return 'naming_pattern';
    }
    if (namespace.contains('structure') || claim.claimLabel.contains('结构')) {
      return 'structure_pattern';
    }
    return 'design_pattern';
  }

  String _claimSummary(NarrativeStateClaim claim) {
    final payloadSummary = ValueReaders.stringValue(
      claim.claimPayload['summary'],
    );
    if (payloadSummary.trim().isNotEmpty) {
      return payloadSummary.trim();
    }
    final evidenceSummary = claim.evidenceRefs
        .map((entry) => entry.summary.trim())
        .firstWhere((entry) => entry.isNotEmpty, orElse: () => '');
    if (evidenceSummary.isNotEmpty) {
      return evidenceSummary;
    }
    return claim.claimLabel.trim();
  }

  List<NarrativeRef> _scopeRefsForClaim(
    NarrativeSemanticReview review,
    NarrativeStateClaim claim,
  ) {
    return List<NarrativeRef>.unmodifiable(
      _dedupeRefs(<NarrativeRef>[
        ...claim.affectedRefs,
        ...claim.contextRefs,
        ...review.targetRefs,
      ]),
    );
  }

  List<Object?> _usableFactsFromFinding(SemanticReviewFinding finding) {
    final facts = <Object?>[
      <String, Object?>{
        'severity': finding.severity.id,
        'summary': finding.summary,
      },
    ];
    for (final evidence in finding.evidenceRefs) {
      final summary = evidence.summary.trim();
      if (summary.isEmpty) {
        continue;
      }
      facts.add(<String, Object?>{
        'evidence_id': evidence.evidenceId,
        'summary': summary,
      });
    }
    if (finding.relatedClaimIds.isNotEmpty) {
      facts.add(<String, Object?>{
        'related_claim_ids': List<String>.from(finding.relatedClaimIds),
      });
    }
    return facts;
  }

  List<NarrativeRef> _dedupeRefs(List<NarrativeRef> refs) {
    final seen = <String>{};
    final result = <NarrativeRef>[];
    for (final ref in refs) {
      final key = '${ref.refType}:${ref.refId}';
      if (ref.refId.trim().isEmpty || !seen.add(key)) {
        continue;
      }
      result.add(ref);
    }
    return result;
  }

  String _namespaceRootFor(String sourceType) {
    switch (sourceType) {
      case NarrativeSourceTypes.explainer:
      case NarrativeSourceTypes.explainerInterpreted:
        return AnalysisInformationBridgeConstants.namespaceRootExplainer;
      case NarrativeSourceTypes.reviewer:
        return AnalysisInformationBridgeConstants.namespaceRootReview;
      default:
        return '';
    }
  }

  String _namespaceTail(
    String namespace, {
    required String fallback,
    Set<String> droppingSegments = const <String>{},
  }) {
    final parts = namespace
        .split('.')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .where((entry) => !droppingSegments.contains(entry))
        .toList(growable: false);
    if (parts.isEmpty) {
      return fallback;
    }
    return parts.join('.');
  }

  String _titleFromNamespace(String namespace, {required String fallback}) {
    final clean = namespace.replaceAll('.', ' ').replaceAll('_', ' ').trim();
    if (clean.isEmpty) {
      return fallback;
    }
    return clean;
  }

  String _safeId(String value) {
    final clean = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_');
    if (clean.isEmpty) {
      return 'item';
    }
    return clean;
  }
}
