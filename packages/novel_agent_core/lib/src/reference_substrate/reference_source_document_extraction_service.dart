import '../common/source_asset_identity.dart';
import '../continuity/narrative_state/narrative_source_ref.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import '../continuity/narrative_state/narrative_text_span_ref.dart';
import '../information/information_activation_policy.dart';
import '../information/information_policy_constants.dart';
import '../information/information_source_ref.dart';
import '../information/information_usage_policy.dart';
import '../source_analysis/source_analysis_entity_extractor_service.dart';
import '../source_analysis/source_analysis_entity_rank.dart';
import '../source_analysis/source_analysis_narrative_asset_inference_service.dart';
import '../source_analysis/source_analysis_outline_service.dart';
import '../source_analysis/source_analysis_style_signal_service.dart';
import 'reference_package_models.dart';
import 'reference_source_document_models.dart';
import 'reference_source_document_structure_service.dart';
import 'reference_substrate_constants.dart';

class ReferenceSourceDocumentExtractionService {
  const ReferenceSourceDocumentExtractionService({
    ReferenceSourceDocumentStructureService structureService =
        const ReferenceSourceDocumentStructureService(),
    SourceAnalysisOutlineService outlineService =
        const SourceAnalysisOutlineService(),
    SourceAnalysisEntityExtractorService entityExtractorService =
        const SourceAnalysisEntityExtractorService(),
    SourceAnalysisNarrativeAssetInferenceService narrativeInferenceService =
        const SourceAnalysisNarrativeAssetInferenceService(),
    SourceAnalysisStyleSignalService styleSignalService =
        const SourceAnalysisStyleSignalService(),
  }) : _structureService = structureService,
       _outlineService = outlineService,
       _entityExtractorService = entityExtractorService,
       _narrativeInferenceService = narrativeInferenceService,
       _styleSignalService = styleSignalService;

  final ReferenceSourceDocumentStructureService _structureService;
  final SourceAnalysisOutlineService _outlineService;
  final SourceAnalysisEntityExtractorService _entityExtractorService;
  final SourceAnalysisNarrativeAssetInferenceService
  _narrativeInferenceService;
  final SourceAnalysisStyleSignalService _styleSignalService;

  ReferenceSourceDocumentIngestionResult extract(
    ReferenceSourceDocumentIngestionRequest request,
  ) {
    final normalizedText = request.sourceText.trim();
    final sourceLanguage = _resolveSourceLanguage(
      declaredLanguage: request.sourceLanguage,
      sourceText: normalizedText,
    );
    final targetLanguage = _resolveTargetLanguage(request.targetLanguage);
    final sourceIdentity = _sourceIdentityForRequest(request);
    final sourceInfoRef = InformationSourceRef(
      sourceRef: NarrativeSourceRef(
        sourceType: sourceIdentity.sourceKind,
        sourceId: sourceIdentity.sourceAssetId,
        label: sourceIdentity.displayName,
        sourceAssetId: sourceIdentity.sourceAssetId,
        displayName: sourceIdentity.displayName,
        sourceKind: sourceIdentity.sourceKind,
        resolverUri: sourceIdentity.resolverUri,
        localHintPath: sourceIdentity.localHintPath,
        sourceIdentityMetadata: <String, Object?>{
          ...sourceIdentity.metadata,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
        },
      ),
      sourceAuthority: InformationSourceAuthorities.sourceDocument,
      roleAuthority: InformationRoleAuthorities.deconstructor,
      researchDepth: InformationResearchDepths.deep,
    );
    final structure = _structureService.analyze(normalizedText);
    final sections = structure.sections;
    final outline = _outlineService.analyze(normalizedText);
    final entityRanks = _entityExtractorService.extractLatinNamedEntities(
      normalizedText,
      maxCount: request.maxEntityEntries,
    );
    final entries = <ReferenceEntryRecord>[
      ..._buildChapterEntries(
        request,
        sections: sections,
        sourceRef: sourceInfoRef,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
      ..._buildEntityEntries(
        request,
        entityRanks: entityRanks,
        sourceRef: sourceInfoRef,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
      ..._buildNarrativeAssetEntries(
        request,
        normalizedText: normalizedText,
        sourceRef: sourceInfoRef,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        chapterSummaries: outline.chapterSummaries,
      ),
      _buildStyleEntry(
        request,
        normalizedText: normalizedText,
        sections: sections,
        sourceRef: sourceInfoRef,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
      _buildReferenceBoundaryEntry(
        request,
        sourceRef: sourceInfoRef,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
    ];
    final snapshot = ReferencePackageSnapshot(
      packageRecord: ReferencePackageRecord(
        packageId: request.packageId,
        packageKind: request.packageKind,
        displayName: request.displayName,
        packageNamespace: request.packageNamespace,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        description: _packageDescription(
          request,
          targetLanguage: targetLanguage,
          entryCount: entries.length,
        ),
        latestVersionId: request.packageVersionId,
        lifecycleStatus: 'active',
        sourceSummary: request.sourceSummary.trim().isEmpty
            ? _sourceSummary(
                request.sourceTitle,
                targetLanguage: targetLanguage,
                charCount: normalizedText.length,
              )
            : request.sourceSummary.trim(),
        licenseSummary: request.licenseSummary.trim().isEmpty
            ? _defaultLicenseSummary(targetLanguage)
            : request.licenseSummary.trim(),
        createdAt: request.createdAt,
        updatedAt: request.createdAt,
      ),
      packageVersionRecord: ReferencePackageVersionRecord(
        packageVersionId: request.packageVersionId,
        packageId: request.packageId,
        versionLabel: request.versionLabel,
        createdAt: request.createdAt,
        createdBy: request.createdBy,
        sourceSummary: _sourceSummary(
          request.sourceTitle,
          targetLanguage: targetLanguage,
          charCount: normalizedText.length,
        ),
        licenseSummary: request.licenseSummary.trim().isEmpty
            ? _defaultLicenseSummary(targetLanguage)
            : request.licenseSummary.trim(),
      ),
      entries: entries,
    );
    return ReferenceSourceDocumentIngestionResult(
      packageId: request.packageId,
      packageVersionId: request.packageVersionId,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      generatedEntryCount: entries.length,
      snapshot: snapshot,
    );
  }

  List<ReferenceEntryRecord> _buildChapterEntries(
    ReferenceSourceDocumentIngestionRequest request, {
    required List<ReferenceSourceDocumentSection> sections,
    required InformationSourceRef sourceRef,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final maxCount = request.maxChapterEntries.clamp(1, 12).toInt();
    return sections
        .take(maxCount)
        .map((section) {
          final excerpt = _trimText(section.content, 220);
          return ReferenceEntryRecord(
            entryId:
                'chapter_${section.sectionIndex.toString().padLeft(2, '0')}',
            packageId: request.packageId,
            packageVersionId: request.packageVersionId,
            entryNamespace: 'source_chapters',
            entryKind: ReferenceEntryKinds.knowledgeFact,
            title: targetLanguage.startsWith('zh')
                ? '章节知识片段 ${section.sectionIndex.toString().padLeft(2, '0')}'
                : 'Chapter knowledge shard ${section.sectionIndex.toString().padLeft(2, '0')}',
            summary: targetLanguage.startsWith('zh')
                ? '来自《${request.sourceTitle}》的章节片段，保留原始叙事线索与情节证据。片段摘要：$excerpt'
                : 'A chapter shard extracted from ${request.sourceTitle}. Excerpt: $excerpt',
            payload: <String, Object?>{
              'heading': section.heading,
              'excerpt': excerpt,
              'source_language': sourceLanguage,
              'target_language': targetLanguage,
              'section_index': section.sectionIndex,
              'section_id': section.sectionId,
              'keywords': section.keywords,
            },
            sourceRefs: <InformationSourceRef>[sourceRef],
            evidenceRefs: <NarrativeEvidenceRef>[
              _sectionEvidenceRef(
                request: request,
                section: section,
                excerpt: excerpt,
              ),
            ],
            tags: <String>[
              'chapter',
              if (section.heading.isNotEmpty) section.heading,
              ...section.keywords,
            ],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.reference,
              preferredBudgetChars: 320,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.referenceOnly,
              citationRiskLevel: InformationCitationRiskLevels.highRisk,
              requiresConfirmation: true,
              allowsDerivativeUse: true,
              allowsDirectQuote: false,
            ),
            confidence: 0.82,
            lifecycleStatus: 'extracted',
          );
        })
        .toList(growable: false);
  }

  List<ReferenceEntryRecord> _buildEntityEntries(
    ReferenceSourceDocumentIngestionRequest request, {
    required List<SourceAnalysisEntityRank> entityRanks,
    required InformationSourceRef sourceRef,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    return entityRanks
        .asMap()
        .entries
        .map((entry) {
          final rank = entry.key + 1;
          final entity = entry.value;
          final entryKind = rank <= 3
              ? ReferenceEntryKinds.designElement
              : ReferenceEntryKinds.knowledgeFact;
          final title = targetLanguage.startsWith('zh')
              ? '高频专有名线索 ${entity.label}'
              : 'High-frequency entity clue ${entity.label}';
          final summary = targetLanguage.startsWith('zh')
              ? '源文档中高频出现专有名词“${entity.label}”，出现 ${entity.count} 次，适合后续精提为角色、地点、组织或象征线索。'
              : 'Entity ${entity.label} appears ${entity.count} times in the source document and can be refined later.';
          return ReferenceEntryRecord(
            entryId: 'entity_${_safeId(entity.label, fallback: 'item')}',
            packageId: request.packageId,
            packageVersionId: request.packageVersionId,
            entryNamespace: 'entity_clues',
            entryKind: entryKind,
            title: title,
            summary: summary,
            payload: <String, Object?>{
              'entity_label': entity.label,
              'occurrence_count': entity.count,
              'source_language': sourceLanguage,
              'target_language': targetLanguage,
            },
            sourceRefs: <InformationSourceRef>[sourceRef],
            tags: <String>['entity', entity.label],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.reference,
              preferredBudgetChars: 220,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.referenceOnly,
              citationRiskLevel: InformationCitationRiskLevels.highRisk,
              requiresConfirmation: true,
              allowsDerivativeUse: true,
              allowsDirectQuote: false,
            ),
            confidence: 0.68,
            lifecycleStatus: 'candidate',
          );
        })
        .toList(growable: false);
  }

  ReferenceEntryRecord _buildStyleEntry(
    ReferenceSourceDocumentIngestionRequest request, {
    required String normalizedText,
    required List<ReferenceSourceDocumentSection> sections,
    required InformationSourceRef sourceRef,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final metrics = _styleSignalService.analyze(
      normalizedText: normalizedText,
      sections: sections,
    );
    final summary = _styleSignalService.localizedSummary(
      metrics,
      targetLanguage: targetLanguage,
    );
    return ReferenceEntryRecord(
      entryId: 'style_profile_primary',
      packageId: request.packageId,
      packageVersionId: request.packageVersionId,
      entryNamespace: 'style_profile',
      entryKind: ReferenceEntryKinds.styleTechnique,
      title: targetLanguage.startsWith('zh')
          ? '原作叙事风格画像'
          : 'Narrative style profile',
      summary: summary,
      payload: <String, Object?>{
        'section_count': metrics.sectionCount,
        'paragraph_count': metrics.paragraphCount,
        'dialogue_quote_count': metrics.dialogueQuoteCount,
        'average_section_length_chars': metrics.averageSectionLengthChars,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
      },
      sourceRefs: <InformationSourceRef>[sourceRef],
      evidenceRefs: sections.isEmpty
          ? const <NarrativeEvidenceRef>[]
          : <NarrativeEvidenceRef>[
              _sectionEvidenceRef(
                request: request,
                section: sections.first,
                excerpt: _trimText(sections.first.content, 180),
              ),
            ],
      tags: const <String>['style', 'technique', 'narrative'],
      activationPolicy: const InformationActivationPolicy(
        activationPriority: InformationActivationPriorities.reference,
        preferredBudgetChars: 280,
      ),
      usagePolicy: const InformationUsagePolicy(
        usageMode: InformationUsageModes.referenceOnly,
        citationRiskLevel: InformationCitationRiskLevels.normal,
        requiresConfirmation: true,
        allowsDerivativeUse: true,
      ),
      confidence: 0.74,
      lifecycleStatus: 'extracted',
    );
  }

  List<ReferenceEntryRecord> _buildNarrativeAssetEntries(
    ReferenceSourceDocumentIngestionRequest request, {
    required String normalizedText,
    required InformationSourceRef sourceRef,
    required String sourceLanguage,
    required String targetLanguage,
    required dynamic chapterSummaries,
  }) {
    final characterProfiles = _narrativeInferenceService
        .inferCharacterProfilesFromSource(
          normalizedText,
          maxCount: request.maxEntityEntries,
        );
    final organizationProfiles = _narrativeInferenceService
        .inferOrganizationProfilesFromSource(normalizedText);
    final worldRuleSets = _narrativeInferenceService.inferWorldRuleSetsFromSource(
      normalizedText,
      chapterSummaries,
    );
    final relationshipRecords = _narrativeInferenceService
        .inferRelationshipRecords(
          characterProfiles,
          chapterSummaries,
          organizationProfiles,
        );
    final timelineRecords = _narrativeInferenceService
        .inferTimelineRecordsFromChapterSummaries(chapterSummaries);
    final foreshadowRecords = _narrativeInferenceService
        .inferForeshadowRecordsFromChapterSummaries(chapterSummaries);
    final entries = <ReferenceEntryRecord>[];
    entries.addAll(
      characterProfiles.take(4).map(
        (profile) => ReferenceEntryRecord(
          entryId: 'character_${_safeId(profile.displayName, fallback: profile.id)}',
          packageId: request.packageId,
          packageVersionId: request.packageVersionId,
          entryNamespace: 'character_clues',
          entryKind: ReferenceEntryKinds.designElement,
          title: targetLanguage.startsWith('zh')
              ? '角色线索 ${profile.displayName}'
              : 'Character clue ${profile.displayName}',
          summary: profile.summary.trim().isNotEmpty
              ? profile.summary
              : (targetLanguage.startsWith('zh')
                    ? '从原文高频线索中抽取的角色候选。'
                    : 'Character candidate extracted from the source text.'),
          payload: <String, Object?>{
            'display_name': profile.displayName,
            'source_language': sourceLanguage,
            'target_language': targetLanguage,
            ...profile.metadata,
          },
          sourceRefs: <InformationSourceRef>[sourceRef],
          tags: <String>['character', profile.displayName],
          activationPolicy: const InformationActivationPolicy(
            activationPriority: InformationActivationPriorities.reference,
            preferredBudgetChars: 220,
          ),
          usagePolicy: const InformationUsagePolicy(
            usageMode: InformationUsageModes.referenceOnly,
            citationRiskLevel: InformationCitationRiskLevels.highRisk,
            requiresConfirmation: true,
            allowsDerivativeUse: true,
            allowsDirectQuote: false,
          ),
          confidence: 0.7,
          lifecycleStatus: 'candidate',
        ),
      ),
    );
    entries.addAll(
      organizationProfiles.take(3).map(
        (profile) => ReferenceEntryRecord(
          entryId: 'organization_${_safeId(profile.displayName, fallback: profile.id)}',
          packageId: request.packageId,
          packageVersionId: request.packageVersionId,
          entryNamespace: 'organization_clues',
          entryKind: ReferenceEntryKinds.designElement,
          title: targetLanguage.startsWith('zh')
              ? '组织线索 ${profile.displayName}'
              : 'Organization clue ${profile.displayName}',
          summary: profile.summary.trim().isNotEmpty
              ? profile.summary
              : (targetLanguage.startsWith('zh')
                    ? '从原文高频线索中抽取的组织候选。'
                    : 'Organization candidate extracted from the source text.'),
          payload: <String, Object?>{
            'display_name': profile.displayName,
            'source_language': sourceLanguage,
            'target_language': targetLanguage,
            ...profile.metadata,
          },
          sourceRefs: <InformationSourceRef>[sourceRef],
          tags: <String>['organization', profile.displayName],
          activationPolicy: const InformationActivationPolicy(
            activationPriority: InformationActivationPriorities.reference,
            preferredBudgetChars: 220,
          ),
          usagePolicy: const InformationUsagePolicy(
            usageMode: InformationUsageModes.referenceOnly,
            citationRiskLevel: InformationCitationRiskLevels.highRisk,
            requiresConfirmation: true,
            allowsDerivativeUse: true,
            allowsDirectQuote: false,
          ),
          confidence: 0.68,
          lifecycleStatus: 'candidate',
        ),
      ),
    );
    entries.addAll(
      worldRuleSets.take(2).map(
        (item) => ReferenceEntryRecord(
          entryId: item.id,
          packageId: request.packageId,
          packageVersionId: request.packageVersionId,
          entryNamespace: 'world_rule_clues',
          entryKind: ReferenceEntryKinds.designElement,
          title: targetLanguage.startsWith('zh')
              ? item.displayName
              : 'World rule clue',
          summary: item.summary,
          payload: <String, Object?>{
            'rules': item.rules,
            'source_language': sourceLanguage,
            'target_language': targetLanguage,
          },
          sourceRefs: <InformationSourceRef>[sourceRef],
          tags: const <String>['world_rule'],
          activationPolicy: const InformationActivationPolicy(
            activationPriority: InformationActivationPriorities.reference,
            preferredBudgetChars: 240,
          ),
          usagePolicy: const InformationUsagePolicy(
            usageMode: InformationUsageModes.referenceOnly,
            citationRiskLevel: InformationCitationRiskLevels.highRisk,
            requiresConfirmation: true,
            allowsDerivativeUse: true,
            allowsDirectQuote: false,
          ),
          confidence: 0.66,
          lifecycleStatus: 'candidate',
        ),
      ),
    );
    entries.addAll(
      relationshipRecords.take(3).map(
        (item) => ReferenceEntryRecord(
          entryId: item.id,
          packageId: request.packageId,
          packageVersionId: request.packageVersionId,
          entryNamespace: 'relationship_clues',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: targetLanguage.startsWith('zh')
              ? '关系线索 ${item.displayName}'
              : 'Relationship clue ${item.displayName}',
          summary: item.summary,
          payload: <String, Object?>{
            'relationship_type': item.relationshipType,
            'left_entity_id': item.leftEntityId,
            'right_entity_id': item.rightEntityId,
            'source_language': sourceLanguage,
            'target_language': targetLanguage,
          },
          sourceRefs: <InformationSourceRef>[sourceRef],
          tags: <String>['relationship', item.displayName],
          activationPolicy: const InformationActivationPolicy(
            activationPriority: InformationActivationPriorities.reference,
            preferredBudgetChars: 220,
          ),
          usagePolicy: const InformationUsagePolicy(
            usageMode: InformationUsageModes.referenceOnly,
            citationRiskLevel: InformationCitationRiskLevels.highRisk,
            requiresConfirmation: true,
            allowsDerivativeUse: true,
            allowsDirectQuote: false,
          ),
          confidence: 0.64,
          lifecycleStatus: 'candidate',
        ),
      ),
    );
    entries.addAll(
      timelineRecords.take(3).map(
        (item) => ReferenceEntryRecord(
          entryId: item.id,
          packageId: request.packageId,
          packageVersionId: request.packageVersionId,
          entryNamespace: 'timeline_clues',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: targetLanguage.startsWith('zh')
              ? '时间线片段 ${item.displayName}'
              : 'Timeline shard ${item.displayName}',
          summary: item.summary,
          payload: <String, Object?>{
            'phase_label': item.phaseLabel,
            'sequence': item.sequence,
            'source_language': sourceLanguage,
            'target_language': targetLanguage,
          },
          sourceRefs: <InformationSourceRef>[sourceRef],
          tags: const <String>['timeline'],
          activationPolicy: const InformationActivationPolicy(
            activationPriority: InformationActivationPriorities.background,
            preferredBudgetChars: 180,
          ),
          usagePolicy: const InformationUsagePolicy(
            usageMode: InformationUsageModes.referenceOnly,
            citationRiskLevel: InformationCitationRiskLevels.highRisk,
            requiresConfirmation: true,
            allowsDerivativeUse: true,
            allowsDirectQuote: false,
          ),
          confidence: 0.62,
          lifecycleStatus: 'candidate',
        ),
      ),
    );
    entries.addAll(
      foreshadowRecords.take(3).map(
        (item) => ReferenceEntryRecord(
          entryId: item.id,
          packageId: request.packageId,
          packageVersionId: request.packageVersionId,
          entryNamespace: 'foreshadow_clues',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: targetLanguage.startsWith('zh')
              ? item.title
              : 'Foreshadow clue',
          summary: item.summary,
          payload: <String, Object?>{
            'status': item.status,
            'planted_chapter_path': item.plantedChapterPath,
            'source_language': sourceLanguage,
            'target_language': targetLanguage,
          },
          sourceRefs: <InformationSourceRef>[sourceRef],
          tags: const <String>['foreshadow'],
          activationPolicy: const InformationActivationPolicy(
            activationPriority: InformationActivationPriorities.background,
            preferredBudgetChars: 180,
          ),
          usagePolicy: const InformationUsagePolicy(
            usageMode: InformationUsageModes.referenceOnly,
            citationRiskLevel: InformationCitationRiskLevels.highRisk,
            requiresConfirmation: true,
            allowsDerivativeUse: true,
            allowsDirectQuote: false,
          ),
          confidence: 0.6,
          lifecycleStatus: 'candidate',
        ),
      ),
    );
    return entries;
  }

  ReferenceEntryRecord _buildReferenceBoundaryEntry(
    ReferenceSourceDocumentIngestionRequest request, {
    required InformationSourceRef sourceRef,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final title = targetLanguage.startsWith('zh')
        ? '原始文稿引用边界'
        : 'Source document boundary';
    final summary = targetLanguage.startsWith('zh')
        ? '该资料包直接来源于原始书稿《${request.sourceTitle}》，默认仅作为参考提取与风格分析依据，不应直接引用原文句段。'
        : 'The package comes from ${request.sourceTitle} and should be used as extracted reference rather than direct quoting.';
    return ReferenceEntryRecord(
      entryId: 'reference_boundary_primary',
      packageId: request.packageId,
      packageVersionId: request.packageVersionId,
      entryNamespace: 'reference_boundary',
      entryKind: ReferenceEntryKinds.referenceWorkBoundary,
      title: title,
      summary: summary,
      payload: <String, Object?>{
        'creator': '',
        'version': request.versionLabel,
        'relationship_to_project': request.packageKind,
        'declared_usage_intent': summary,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
        'risk_notes': <Object?>[
          targetLanguage.startsWith('zh')
              ? '默认只保留结构化提取结果与风格画像，不直接输出原文大段摘引。'
              : 'Keep structured extraction results only.',
        ],
      },
      sourceRefs: <InformationSourceRef>[sourceRef],
      tags: const <String>['boundary', 'reference'],
      activationPolicy: const InformationActivationPolicy(
        activationPriority: InformationActivationPriorities.background,
      ),
      usagePolicy: const InformationUsagePolicy(
        usageMode: InformationUsageModes.readOnly,
        citationRiskLevel: InformationCitationRiskLevels.highRisk,
        requiresConfirmation: true,
        allowsDerivativeUse: false,
        allowsDirectQuote: false,
      ),
      confidence: 0.9,
      lifecycleStatus: 'active',
    );
  }

  String _packageDescription(
    ReferenceSourceDocumentIngestionRequest request, {
    required String targetLanguage,
    required int entryCount,
  }) {
    if (targetLanguage.startsWith('zh')) {
      return '从原始文稿《${request.sourceTitle}》直接抽取得到的参考资料包，当前生成 $entryCount 条结构化条目。';
    }
    return 'Reference package extracted directly from ${request.sourceTitle} with $entryCount entries.';
  }

  String _sourceSummary(
    String sourceTitle, {
    required String targetLanguage,
    required int charCount,
  }) {
    if (targetLanguage.startsWith('zh')) {
      return '原始文稿《$sourceTitle》共 $charCount 字符，已转为结构化参考证据包。';
    }
    return 'Source document $sourceTitle ($charCount chars) has been converted into a structured reference package.';
  }

  String _defaultLicenseSummary(String targetLanguage) {
    if (targetLanguage.startsWith('zh')) {
      return '默认只保留结构化提取结果、风格画像与边界说明；直接引文需额外确认。';
    }
    return 'Keep structured extraction outputs only; direct quotation requires confirmation.';
  }

  String _resolveSourceLanguage({
    required String declaredLanguage,
    required String sourceText,
  }) {
    if (declaredLanguage.trim().isNotEmpty) {
      return declaredLanguage.trim();
    }
    final cjkMatches = RegExp(r'[\u4E00-\u9FFF]').allMatches(sourceText).length;
    final latinMatches = RegExp(r'[A-Za-z]').allMatches(sourceText).length;
    if (cjkMatches > latinMatches ~/ 2) {
      return 'zh-CN';
    }
    return 'en';
  }

  String _resolveTargetLanguage(String targetLanguage) {
    return targetLanguage.trim().isEmpty ? 'zh-CN' : targetLanguage.trim();
  }

  String _trimText(String text, int maxChars) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return '${normalized.substring(0, maxChars)}...';
  }

  String _safeId(String value, {required String fallback}) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? fallback : normalized.toLowerCase();
  }

  NarrativeEvidenceRef _sectionEvidenceRef({
    required ReferenceSourceDocumentIngestionRequest request,
    required ReferenceSourceDocumentSection section,
    required String excerpt,
  }) {
    final sourceIdentity = _sourceIdentityForRequest(request);
    final targetRef = NarrativeRef(
      refType: 'reference_source_section',
      refId: section.sectionId,
      displayName: section.heading,
      chapterId: 'section_${section.sectionIndex}',
      sourcePath: sourceIdentity.localHintPath,
      metadata: <String, Object?>{'structure_kind': section.structureKind},
    );
    return NarrativeEvidenceRef(
      evidenceType: 'reference_source_section',
      evidenceId: 'evidence_${section.sectionId}',
      sourceRef: NarrativeSourceRef(
        sourceType: sourceIdentity.sourceKind,
        sourceId: sourceIdentity.sourceAssetId,
        label: sourceIdentity.displayName,
        sourceAssetId: sourceIdentity.sourceAssetId,
        displayName: sourceIdentity.displayName,
        sourceKind: sourceIdentity.sourceKind,
        resolverUri: sourceIdentity.resolverUri,
        localHintPath: sourceIdentity.localHintPath,
        sourceIdentityMetadata: sourceIdentity.metadata,
      ),
      targetRef: targetRef,
      textSpan: NarrativeTextSpanRef(
        targetRef: targetRef,
        startOffset: section.startOffset,
        endOffset: section.endOffset,
        excerpt: excerpt,
      ),
      summary: excerpt,
    );
  }

  SourceAssetIdentity _sourceIdentityForRequest(
    ReferenceSourceDocumentIngestionRequest request,
  ) {
    final rawSourceRef = request.sourceRef.trim();
    final normalizedLocalHintPath = SourceAssetIdentity.normalizeLocalHintPath(
      rawSourceRef,
    );
    final resolverUri = normalizedLocalHintPath.isEmpty
        ? ''
        : 'workspace-file://${normalizedLocalHintPath.replaceAll(' ', '%20')}';
    final sourceAssetId = SourceAssetIdentity.resolveSourceAssetId(
      explicitSourceAssetId: '',
      legacySourceId: rawSourceRef,
      displayName: request.sourceTitle.trim(),
      sourceKind: 'source_document_file',
      resolverUri: resolverUri,
      localHintPath: normalizedLocalHintPath,
    );
    return SourceAssetIdentity(
      sourceAssetId: sourceAssetId,
      sourceKind: 'source_document_file',
      displayName: request.sourceTitle.trim(),
      resolverUri: resolverUri,
      localHintPath: normalizedLocalHintPath,
      metadata: const <String, Object?>{},
    );
  }
}
