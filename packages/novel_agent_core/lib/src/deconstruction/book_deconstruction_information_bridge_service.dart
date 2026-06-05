import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import '../continuity/narrative_state/narrative_reference_constants.dart';
import '../continuity/narrative_state/narrative_source_ref.dart';
import '../continuity/narrative_state/narrative_text_span_ref.dart';
import '../information/design_element_card.dart';
import '../information/information_activation_policy.dart';
import '../information/information_lifecycle_statuses.dart';
import '../information/information_source_ref.dart';
import '../information/information_usage_policy.dart';
import '../information/project_knowledge_card.dart';
import '../information/reference_work_record.dart';
import '../information/research_note.dart';
import 'book_deconstruction_chapter_outline.dart';
import 'book_deconstruction_continuity_hints.dart';
import 'book_deconstruction_extraction_result.dart';
import 'book_deconstruction_hint_source_kind.dart';
import 'book_deconstruction_input.dart';
import 'book_deconstruction_mechanic_hint.dart';
import 'book_deconstruction_narrative_artifact_bundle.dart';
import 'book_deconstruction_narrative_bridge_constants.dart';

class BookDeconstructionInformationBridgeService {
  const BookDeconstructionInformationBridgeService();

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
      description: '拆书/解书分析后的解释性信息桥',
      metadata: <String, Object?>{
        'mode_id': extractionResult.modeId,
        'project_strategy_id': extractionResult.projectStrategyId,
      },
    );
    final primaryDocumentRef = _primaryDocumentRef(input);
    final knowledgeCards = <ProjectKnowledgeCard>[
      if (extractionResult.storyOutlineSummary.trim().isNotEmpty)
        _storyOutlineKnowledgeCard(
          extractionResult: extractionResult,
          directSource: directSource,
          primaryDocumentRef: primaryDocumentRef,
        ),
      ...extractionResult.chapterOutlines.map(
        (outline) => _chapterOutlineKnowledgeCard(
          extractionId: extractionResult.extractionId,
          sourceTitle: extractionResult.sourceTitle,
          outline: outline,
          directSource: directSource,
          primaryDocumentRef: primaryDocumentRef,
        ),
      ),
    ];
    final designElements = <DesignElementCard>[
      ..._worldRuleDesignElements(
        extractionId: extractionResult.extractionId,
        sourceTitle: extractionResult.sourceTitle,
        directSource: directSource,
        primaryDocumentRef: primaryDocumentRef,
        extractionResult: extractionResult,
      ),
      ..._styleDesignElements(
        extractionId: extractionResult.extractionId,
        sourceTitle: extractionResult.sourceTitle,
        directSource: directSource,
        primaryDocumentRef: primaryDocumentRef,
        extractionResult: extractionResult,
      ),
      ..._mechanicHintDesignElements(
        extractionId: extractionResult.extractionId,
        sourceTitle: extractionResult.sourceTitle,
        continuityHints: extractionResult.continuityHints,
        directSource: directSource,
        interpretedSource: interpretedSource,
        primaryDocumentRef: primaryDocumentRef,
      ),
    ];
    final researchNotes = <ResearchNote>[
      if (_hasResearchNoteDraft(extractionResult))
        _researchNoteDraft(
          extractionResult: extractionResult,
          directSource: directSource,
          primaryDocumentRef: primaryDocumentRef,
        ),
    ];
    final referenceWorks = <ReferenceWorkRecord>[
      _referenceWorkRecord(
        extractionResult: extractionResult,
        directSource: directSource,
        primaryDocumentRef: primaryDocumentRef,
      ),
    ];
    return BookDeconstructionNarrativeArtifactBundle(
      knowledgeCards: List<ProjectKnowledgeCard>.unmodifiable(knowledgeCards),
      designElements: List<DesignElementCard>.unmodifiable(designElements),
      researchNotes: List<ResearchNote>.unmodifiable(researchNotes),
      referenceWorks: List<ReferenceWorkRecord>.unmodifiable(referenceWorks),
      metadata: <String, Object?>{
        'analysis_namespace_roots': <String>[
          'analysis.deconstruction',
          'analysis.explainer',
        ],
        'promotion_path': BookDeconstructionNarrativeBridgeConstants
            .promotionPathUserOrPolicy,
        'source_title': extractionResult.sourceTitle,
        'extraction_id': extractionResult.extractionId,
        'information_bridge': <String, Object?>{
          'knowledge_card_count': knowledgeCards.length,
          'design_element_count': designElements.length,
          'research_note_count': researchNotes.length,
          'reference_work_count': referenceWorks.length,
        },
      },
    );
  }

  ProjectKnowledgeCard _storyOutlineKnowledgeCard({
    required BookDeconstructionExtractionResult extractionResult,
    required NarrativeSourceRef directSource,
    required NarrativeRef primaryDocumentRef,
  }) {
    return ProjectKnowledgeCard(
      cardId: 'knowledge_${extractionResult.extractionId}_story_outline',
      cardNamespace: 'analysis.deconstruction.story_outline',
      cardType: 'story_outline',
      title: '${extractionResult.sourceTitle} 故事总纲',
      summary: extractionResult.storyOutlineSummary,
      contentPayload: <String, Object?>{
        'source_title': extractionResult.sourceTitle,
        'story_outline_summary': extractionResult.storyOutlineSummary,
      },
      sourceRefs: <InformationSourceRef>[
        _informationSourceRef(
          directSource,
          sourceAuthority: 'source_text',
          roleAuthority: 'deconstruction_analysis',
          researchDepth: 'source_level',
        ),
      ],
      evidenceRefs: <NarrativeEvidenceRef>[
        _evidenceRef(
          evidenceId:
              'evidence_${extractionResult.extractionId}_story_outline_info',
          source: directSource,
          targetRef: primaryDocumentRef,
          summary: extractionResult.storyOutlineSummary,
        ),
      ],
      scopeRefs: <NarrativeRef>[primaryDocumentRef],
      activationPolicy: _activationPolicy(priority: 'reference'),
      usagePolicy: _analysisUsagePolicy(),
      confidence: 0.8,
      lifecycleStatus: InformationLifecycleStatuses.proposed,
      metadata: _artifactMetadata(
        analysisNamespace: 'analysis.deconstruction.story_outline',
        promotionTargetNamespace: 'writing.story_outline',
        primaryDocumentRef: primaryDocumentRef,
        extra: <String, Object?>{'bridge_artifact_kind': 'knowledge_card'},
      ),
    );
  }

  ProjectKnowledgeCard _chapterOutlineKnowledgeCard({
    required String extractionId,
    required String sourceTitle,
    required BookDeconstructionChapterOutline outline,
    required NarrativeSourceRef directSource,
    required NarrativeRef primaryDocumentRef,
  }) {
    final chapterRef = NarrativeRef(
      refType: NarrativeRefTypes.chapter,
      refId: outline.id,
      displayName: outline.title,
      chapterId: outline.id,
      metadata: <String, Object?>{'sequence': outline.sequence},
    );
    return ProjectKnowledgeCard(
      cardId: 'knowledge_${extractionId}_${outline.id}',
      cardNamespace: 'analysis.deconstruction.chapter_outline',
      cardType: 'chapter_outline',
      title: outline.title,
      summary: outline.summary,
      contentPayload: <String, Object?>{
        'source_title': sourceTitle,
        'chapter_id': outline.id,
        'sequence': outline.sequence,
        'summary': outline.summary,
      },
      sourceRefs: <InformationSourceRef>[
        _informationSourceRef(
          directSource,
          sourceAuthority: 'source_text',
          roleAuthority: 'deconstruction_analysis',
          researchDepth: 'source_level',
        ),
      ],
      evidenceRefs: <NarrativeEvidenceRef>[
        _evidenceRef(
          evidenceId: 'evidence_${extractionId}_${outline.id}_info',
          source: directSource,
          targetRef: chapterRef,
          summary: outline.summary,
        ),
      ],
      scopeRefs: <NarrativeRef>[chapterRef, primaryDocumentRef],
      activationPolicy: _activationPolicy(priority: 'background'),
      usagePolicy: _analysisUsagePolicy(),
      confidence: 0.76,
      lifecycleStatus: InformationLifecycleStatuses.proposed,
      metadata: _artifactMetadata(
        analysisNamespace: 'analysis.deconstruction.chapter_outline',
        promotionTargetNamespace: 'writing.chapter_outline',
        primaryDocumentRef: primaryDocumentRef,
        extra: <String, Object?>{'bridge_artifact_kind': 'knowledge_card'},
      ),
    );
  }

  List<DesignElementCard> _worldRuleDesignElements({
    required String extractionId,
    required String sourceTitle,
    required NarrativeSourceRef directSource,
    required NarrativeRef primaryDocumentRef,
    required BookDeconstructionExtractionResult extractionResult,
  }) {
    return extractionResult.worldRuleSets
        .map(
          (ruleSet) => DesignElementCard(
            designId: 'design_${extractionId}_world_${_safeSuffix(ruleSet.id)}',
            designNamespace: 'analysis.deconstruction.design.system_rule',
            designLabel: ruleSet.displayName,
            designPayload: <String, Object?>{
              'design_kind': 'system_rule',
              'source_title': sourceTitle,
              'rule_set_id': ruleSet.id,
              'summary': ruleSet.summary,
              'rules': List<String>.from(ruleSet.rules),
            },
            sourceRefs: <InformationSourceRef>[
              _informationSourceRef(
                directSource,
                sourceAuthority: 'source_text',
                roleAuthority: 'deconstruction_analysis',
                researchDepth: 'source_level',
              ),
            ],
            evidenceRefs: <NarrativeEvidenceRef>[
              _evidenceRef(
                evidenceId:
                    'evidence_${extractionId}_world_${_safeSuffix(ruleSet.id)}',
                source: directSource,
                targetRef: primaryDocumentRef,
                summary: ruleSet.summary,
              ),
            ],
            scopeRefs: <NarrativeRef>[primaryDocumentRef],
            activationPolicy: _activationPolicy(priority: 'reference'),
            usagePolicy: _analysisUsagePolicy(),
            confidence: 0.82,
            uncertainty: '',
            lifecycleStatus: InformationLifecycleStatuses.proposed,
            metadata: _artifactMetadata(
              analysisNamespace: 'analysis.deconstruction.design.system_rule',
              promotionTargetNamespace: 'writing.design.system_rule',
              primaryDocumentRef: primaryDocumentRef,
              extra: <String, Object?>{
                'bridge_artifact_kind': 'design_element',
              },
            ),
          ),
        )
        .toList(growable: false);
  }

  List<DesignElementCard> _styleDesignElements({
    required String extractionId,
    required String sourceTitle,
    required NarrativeSourceRef directSource,
    required NarrativeRef primaryDocumentRef,
    required BookDeconstructionExtractionResult extractionResult,
  }) {
    return extractionResult.styleProfiles
        .map(
          (profile) => DesignElementCard(
            designId: 'design_${extractionId}_style_${_safeSuffix(profile.id)}',
            designNamespace: 'analysis.deconstruction.design.style_pattern',
            designLabel: profile.displayName,
            designPayload: <String, Object?>{
              'design_kind': 'style_pattern',
              'source_title': sourceTitle,
              'style_profile_id': profile.id,
              'summary': profile.summary,
            },
            sourceRefs: <InformationSourceRef>[
              _informationSourceRef(
                directSource,
                sourceAuthority: 'source_text',
                roleAuthority: 'deconstruction_analysis',
                researchDepth: 'source_level',
              ),
            ],
            evidenceRefs: <NarrativeEvidenceRef>[
              _evidenceRef(
                evidenceId:
                    'evidence_${extractionId}_style_${_safeSuffix(profile.id)}',
                source: directSource,
                targetRef: primaryDocumentRef,
                summary: profile.summary,
              ),
            ],
            scopeRefs: <NarrativeRef>[primaryDocumentRef],
            activationPolicy: _activationPolicy(priority: 'background'),
            usagePolicy: _analysisUsagePolicy(),
            confidence: 0.74,
            lifecycleStatus: InformationLifecycleStatuses.proposed,
            metadata: _artifactMetadata(
              analysisNamespace: 'analysis.deconstruction.design.style_pattern',
              promotionTargetNamespace: 'writing.design.style_pattern',
              primaryDocumentRef: primaryDocumentRef,
              extra: <String, Object?>{
                'bridge_artifact_kind': 'design_element',
              },
            ),
          ),
        )
        .toList(growable: false);
  }

  List<DesignElementCard> _mechanicHintDesignElements({
    required String extractionId,
    required String sourceTitle,
    required BookDeconstructionContinuityHints continuityHints,
    required NarrativeSourceRef directSource,
    required NarrativeSourceRef interpretedSource,
    required NarrativeRef primaryDocumentRef,
  }) {
    return continuityHints.mechanicHints
        .map(
          (hint) => _mechanicHintDesignElement(
            extractionId: extractionId,
            sourceTitle: sourceTitle,
            hint: hint,
            source:
                hint.sourceKind == BookDeconstructionHintSourceKind.inferredHint
                ? interpretedSource
                : directSource,
            primaryDocumentRef: primaryDocumentRef,
          ),
        )
        .toList(growable: false);
  }

  DesignElementCard _mechanicHintDesignElement({
    required String extractionId,
    required String sourceTitle,
    required BookDeconstructionMechanicHint hint,
    required NarrativeSourceRef source,
    required NarrativeRef primaryDocumentRef,
  }) {
    final scopeRef = NarrativeRef(
      refType: NarrativeRefTypes.segment,
      refId: hint.id,
      displayName: hint.displayName,
      metadata: <String, Object?>{
        if (hint.scopeHintId.trim().isNotEmpty)
          'scope_hint_id': hint.scopeHintId,
      },
    );
    final analysisNamespace =
        source.sourceType == NarrativeSourceTypes.explainerInterpreted
        ? 'analysis.explainer.design.pattern_hint'
        : 'analysis.deconstruction.design.pattern_hint';
    return DesignElementCard(
      designId: 'design_${extractionId}_pattern_${_safeSuffix(hint.id)}',
      designNamespace: analysisNamespace,
      designLabel: hint.displayName,
      designPayload: <String, Object?>{
        'design_kind': 'pattern_hint',
        'legacy_kind': 'mechanic_hint',
        'source_title': sourceTitle,
        'scope_hint_id': hint.scopeHintId,
        'identity_mode_hint': hint.identityModeHint?.name ?? '',
        'memory_mode_hint': hint.memoryModeHint?.name ?? '',
        'state_mode_hint': hint.stateModeHint?.name ?? '',
        'causal_mode_hint': hint.causalModeHint?.name ?? '',
        'branch_mode_hint': hint.branchModeHint?.name ?? '',
        'visibility_mode_hint': hint.visibilityModeHint?.name ?? '',
        'chapter_start': hint.chapterStart,
        'chapter_end': hint.chapterEnd,
        'source_paths': List<String>.from(hint.sourcePaths),
        'notes': hint.notes,
        'metadata': ValueReaders.deepCopyMap(hint.metadata),
      },
      sourceRefs: <InformationSourceRef>[
        _informationSourceRef(
          source,
          sourceAuthority:
              source.sourceType == NarrativeSourceTypes.explainerInterpreted
              ? 'interpreted_analysis'
              : 'source_text',
          roleAuthority: 'deconstruction_analysis',
          researchDepth:
              source.sourceType == NarrativeSourceTypes.explainerInterpreted
              ? 'analysis_inferred'
              : 'source_level',
        ),
      ],
      evidenceRefs: <NarrativeEvidenceRef>[
        _evidenceRef(
          evidenceId:
              'evidence_${extractionId}_pattern_${_safeSuffix(hint.id)}',
          source: source,
          targetRef: primaryDocumentRef,
          summary: hint.notes.trim().isNotEmpty ? hint.notes : hint.displayName,
        ),
      ],
      scopeRefs: <NarrativeRef>[scopeRef, primaryDocumentRef],
      linkedRefs: <NarrativeRef>[scopeRef],
      activationPolicy: _activationPolicy(priority: 'reference'),
      usagePolicy: _analysisUsagePolicy(
        requiresConfirmation:
            source.sourceType == NarrativeSourceTypes.explainerInterpreted,
      ),
      confidence: source.sourceType == NarrativeSourceTypes.explainerInterpreted
          ? 0.58
          : 0.72,
      uncertainty:
          source.sourceType == NarrativeSourceTypes.explainerInterpreted
          ? '解释性 pattern hint，提升到正式写作规则前应先确认。'
          : '',
      lifecycleStatus: InformationLifecycleStatuses.proposed,
      metadata: _artifactMetadata(
        analysisNamespace: analysisNamespace,
        promotionTargetNamespace: 'writing.design.pattern_hint',
        primaryDocumentRef: primaryDocumentRef,
        extra: <String, Object?>{
          'bridge_artifact_kind': 'design_element',
          'legacy_mechanic_hint_id': hint.id,
          'legacy_mechanic_namespace': 'continuity.foundation.mechanic_hint',
        },
      ),
    );
  }

  bool _hasResearchNoteDraft(
    BookDeconstructionExtractionResult extractionResult,
  ) {
    return extractionResult.notes.trim().isNotEmpty ||
        extractionResult.continuityHints.notes.trim().isNotEmpty;
  }

  ResearchNote _researchNoteDraft({
    required BookDeconstructionExtractionResult extractionResult,
    required NarrativeSourceRef directSource,
    required NarrativeRef primaryDocumentRef,
  }) {
    final summaryParts = <String>[
      if (extractionResult.notes.trim().isNotEmpty)
        extractionResult.notes.trim(),
      if (extractionResult.continuityHints.notes.trim().isNotEmpty)
        extractionResult.continuityHints.notes.trim(),
    ];
    final summary = summaryParts.join('\n');
    return ResearchNote(
      researchId: 'research_${extractionResult.extractionId}_deconstruction',
      query: '${extractionResult.sourceTitle} 拆书研究提要',
      sourceKind: 'deconstruction_analysis',
      sourceUrlOrRef: primaryDocumentRef.relativePath.isNotEmpty
          ? primaryDocumentRef.relativePath
          : primaryDocumentRef.refId,
      citation: extractionResult.sourceTitle,
      summary: summary,
      usableFacts: <Object?>[
        if (extractionResult.notes.trim().isNotEmpty)
          <String, Object?>{
            'fact_kind': 'operator_note',
            'summary': extractionResult.notes.trim(),
          },
        if (extractionResult.continuityHints.notes.trim().isNotEmpty)
          <String, Object?>{
            'fact_kind': 'continuity_hint_note',
            'summary': extractionResult.continuityHints.notes.trim(),
          },
      ],
      creativeSuggestions: const <Object?>[],
      uncertainty: extractionResult.continuityHints.hasInferredHints
          ? '包含解释性推断，建议作为 research note draft 保留。'
          : '',
      licenseOrUsageNote: '仅作为 analysis namespace 研究草稿保留，未自动提升。',
      createdBy: 'book_deconstruction_analysis_bridge',
      linkedCards: <NarrativeRef>[primaryDocumentRef],
      usagePolicy: _analysisUsagePolicy(),
      metadata: _artifactMetadata(
        analysisNamespace: 'analysis.deconstruction.research_note',
        promotionTargetNamespace: 'writing.research_note',
        primaryDocumentRef: primaryDocumentRef,
        extra: <String, Object?>{
          'bridge_artifact_kind': 'research_note',
          'draft_origin': 'deconstruction',
        },
      ),
    );
  }

  ReferenceWorkRecord _referenceWorkRecord({
    required BookDeconstructionExtractionResult extractionResult,
    required NarrativeSourceRef directSource,
    required NarrativeRef primaryDocumentRef,
  }) {
    return ReferenceWorkRecord(
      referenceWorkId: 'reference_${extractionResult.extractionId}',
      title: extractionResult.sourceTitle,
      creator: '',
      version: '',
      sourceRefs: <InformationSourceRef>[
        _informationSourceRef(
          directSource,
          sourceAuthority: 'source_text',
          roleAuthority: 'deconstruction_analysis',
          researchDepth: 'source_level',
        ),
      ],
      relationshipToProject: 'deconstruction_source_work',
      declaredUsageIntent: 'analysis_and_continuation_reference_boundary',
      allowedUsageSummary: '当前仅作为拆书来源边界记录，不自动提升为写作接受态。',
      riskNotes: <Object?>[
        <String, Object?>{
          'risk_kind': 'source_work_boundary',
          'summary': '拆书来源作品需与写作主 ledger 分离，保留在 analysis namespace。',
        },
      ],
      requiresConfirmation: true,
      metadata: _artifactMetadata(
        analysisNamespace: 'analysis.deconstruction.reference_work',
        promotionTargetNamespace: 'writing.reference_work',
        primaryDocumentRef: primaryDocumentRef,
        extra: <String, Object?>{'bridge_artifact_kind': 'reference_work'},
      ),
    );
  }

  InformationSourceRef _informationSourceRef(
    NarrativeSourceRef sourceRef, {
    required String sourceAuthority,
    required String roleAuthority,
    required String researchDepth,
  }) {
    return InformationSourceRef(
      sourceRef: sourceRef,
      sourceAuthority: sourceAuthority,
      roleAuthority: roleAuthority,
      researchDepth: researchDepth,
      metadata: <String, Object?>{
        BookDeconstructionNarrativeBridgeConstants.metadataPromotionPath:
            BookDeconstructionNarrativeBridgeConstants
                .promotionPathUserOrPolicy,
      },
    );
  }

  InformationActivationPolicy _activationPolicy({required String priority}) {
    return InformationActivationPolicy(
      activationPriority: priority,
      requiresExplicitSelection: false,
      preferredBudgetChars: priority == 'reference' ? 480 : 240,
      metadata: const <String, Object?>{'source_namespace': 'analysis'},
    );
  }

  InformationUsagePolicy _analysisUsagePolicy({
    bool requiresConfirmation = true,
  }) {
    return InformationUsagePolicy(
      usageMode: 'analysis_reference_only',
      citationRiskLevel: 'medium',
      requiresConfirmation: requiresConfirmation,
      allowsDerivativeUse: true,
      allowsDirectQuote: false,
      referenceScope: const <String, Object?>{
        'source_namespace': 'analysis',
        'writing_namespace': 'separate',
      },
      metadata: <String, Object?>{
        BookDeconstructionNarrativeBridgeConstants.metadataPromotionPath:
            BookDeconstructionNarrativeBridgeConstants
                .promotionPathUserOrPolicy,
      },
    );
  }

  JsonMap _artifactMetadata({
    required String analysisNamespace,
    required String promotionTargetNamespace,
    required NarrativeRef primaryDocumentRef,
    JsonMap extra = const <String, Object?>{},
  }) {
    return <String, Object?>{
      BookDeconstructionNarrativeBridgeConstants.metadataAnalysisNamespace:
          analysisNamespace,
      BookDeconstructionNarrativeBridgeConstants.metadataAnalysisStatus:
          BookDeconstructionNarrativeBridgeConstants.proposedStatus,
      BookDeconstructionNarrativeBridgeConstants.metadataPromotionPath:
          BookDeconstructionNarrativeBridgeConstants.promotionPathUserOrPolicy,
      BookDeconstructionNarrativeBridgeConstants
              .metadataPromotionTargetNamespace:
          promotionTargetNamespace,
      BookDeconstructionNarrativeBridgeConstants
              .metadataInheritedByDerivedProjects:
          true,
      'source_namespace_root': 'analysis.deconstruction',
      'writing_namespace_root': 'writing',
      'source_document_ref': primaryDocumentRef.toJson(),
      ...ValueReaders.deepCopyMap(extra),
    };
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
      textSpan: NarrativeTextSpanRef(
        targetRef: targetRef,
        excerpt: summary.trim(),
      ),
      summary: summary.trim(),
      metadata: <String, Object?>{
        'analysis_namespace_root': 'analysis.deconstruction',
      },
    );
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
