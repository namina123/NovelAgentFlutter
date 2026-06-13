import '../common/source_asset_identity.dart';
import '../continuity/narrative_state/narrative_source_ref.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import '../continuity/narrative_state/narrative_text_span_ref.dart';
import '../information/information_activation_policy.dart';
import '../information/information_policy_constants.dart';
import '../information/information_source_ref.dart';
import '../information/information_usage_policy.dart';
import 'reference_package_models.dart';
import 'reference_source_document_models.dart';
import 'reference_source_document_structure_service.dart';
import 'reference_substrate_constants.dart';

class ReferenceSourceDocumentExtractionService {
  const ReferenceSourceDocumentExtractionService({
    ReferenceSourceDocumentStructureService structureService =
        const ReferenceSourceDocumentStructureService(),
  }) : _structureService = structureService;

  final ReferenceSourceDocumentStructureService _structureService;

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
    final entityRanks = _extractNamedEntities(
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
    required List<_RankedEntity> entityRanks,
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
    final paragraphCount = normalizedText
        .split(RegExp(r'\n\s*\n|\r\n\s*\r\n'))
        .where((entry) => entry.trim().isNotEmpty)
        .length;
    final dialogueCount = RegExp(r'["“”]').allMatches(normalizedText).length;
    final avgSectionLength = sections.isEmpty
        ? normalizedText.length
        : (normalizedText.length / sections.length).round();
    final summary = targetLanguage.startsWith('zh')
        ? '该文本呈现出明显的章节推进结构，共识别 ${sections.length} 个章节/片段，约 ${paragraphCount} 个段落，含 ${dialogueCount} 处对话引号，适合作为叙事节奏与视角组织的风格依据。'
        : 'The document shows a chapter-based progression with ${sections.length} sections, about $paragraphCount paragraphs and $dialogueCount dialogue quotes.';
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
        'section_count': sections.length,
        'paragraph_count': paragraphCount,
        'dialogue_quote_count': dialogueCount,
        'average_section_length_chars': avgSectionLength,
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

  List<_RankedEntity> _extractNamedEntities(
    String sourceText, {
    required int maxCount,
  }) {
    final counts = <String, int>{};
    final entityPattern = RegExp(r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2}\b');
    final stopWords = <String>{
      'Chapter',
      'Mr',
      'Mrs',
      'The',
      'And',
      'But',
      'His',
      'Her',
      'Its',
      'Their',
      'There',
      'This',
      'That',
      'These',
      'Those',
      'Then',
      'When',
      'Where',
      'What',
      'Why',
      'How',
      'Well',
      'Now',
      'Look',
      'Come',
      'Into',
      'From',
      'With',
      'Without',
      'After',
      'Before',
      'Over',
      'Under',
      'Around',
      'About',
      'Through',
      'Because',
      'Though',
      'While',
      'Yes',
      'No',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'It',
      'He',
      'She',
      'They',
      'Them',
      'We',
      'You',
      'I',
      'A',
      'An',
    };
    for (final match in entityPattern.allMatches(sourceText)) {
      final value = match.group(0)?.trim() ?? '';
      if (value.isEmpty || stopWords.contains(value)) {
        continue;
      }
      counts[value] = (counts[value] ?? 0) + 1;
    }
    final ranked =
        counts.entries
            .where((entry) => entry.value >= 2)
            .map((entry) => _RankedEntity(entry.key, entry.value))
            .toList(growable: false)
          ..sort((left, right) {
            final countCompare = right.count.compareTo(left.count);
            if (countCompare != 0) {
              return countCompare;
            }
            return left.label.compareTo(right.label);
          });
    return ranked.take(maxCount.clamp(1, 12).toInt()).toList(growable: false);
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

class _RankedEntity {
  const _RankedEntity(this.label, this.count);

  final String label;
  final int count;
}
