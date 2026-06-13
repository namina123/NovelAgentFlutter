import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/local_design_element_repository.dart';
import '../storage/local_information_event_repository.dart';
import '../storage/local_knowledge_card_repository.dart';
import '../storage/local_reference_work_repository.dart';
import '../storage/local_research_note_repository.dart';
import '../storage/project_information_path_service.dart';
import '../storage/project_information_projection_writer_service.dart';
import 'project_information_import_collection_result.dart';

class ProjectInformationImportCollectionService {
  ProjectInformationImportCollectionService({
    required ProjectWorkspacePort workspacePort,
    ResearchNoteRepository? researchNoteRepository,
    InformationEventRepository? informationEventRepository,
    ProjectInformationProjectionWriterService? projectionWriterService,
    ProjectInformationPathService? pathService,
    InformationCollectionPolicyService? collectionPolicyService,
    InformationSourceQualityService? sourceQualityService,
  }) : _workspacePort = workspacePort,
       _researchNoteRepository =
           researchNoteRepository ??
           LocalResearchNoteRepository(workspacePort: workspacePort),
       _informationEventRepository =
           informationEventRepository ??
           LocalInformationEventRepository(workspacePort: workspacePort),
       _projectionWriterService =
           projectionWriterService ??
           ProjectInformationProjectionWriterService(
             workspacePort: workspacePort,
             knowledgeCardRepository: LocalKnowledgeCardRepository(
               workspacePort: workspacePort,
             ),
             designElementRepository: LocalDesignElementRepository(
               workspacePort: workspacePort,
             ),
             researchNoteRepository:
                 researchNoteRepository ??
                 LocalResearchNoteRepository(workspacePort: workspacePort),
             referenceWorkRepository: LocalReferenceWorkRepository(
               workspacePort: workspacePort,
             ),
           ),
       _pathService = pathService ?? ProjectInformationPathService(),
       _collectionPolicyService =
           collectionPolicyService ??
           const InformationCollectionPolicyService(),
       _sourceQualityService =
           sourceQualityService ?? const InformationSourceQualityService();

  final ProjectWorkspacePort _workspacePort;
  final ResearchNoteRepository _researchNoteRepository;
  final InformationEventRepository _informationEventRepository;
  final ProjectInformationProjectionWriterService _projectionWriterService;
  final ProjectInformationPathService _pathService;
  final InformationCollectionPolicyService _collectionPolicyService;
  final InformationSourceQualityService _sourceQualityService;

  Future<ProjectInformationImportCollectionResult> collectProjectFile(
    ProjectDescriptor project, {
    required String relativePath,
    required String query,
    String purpose = '',
    String requestedDepth = '',
    String informationDomain = '',
    String referenceRelationship = '',
    JsonMap sourceRequirements = const <String, Object?>{},
    JsonMap extractionPolicy = const <String, Object?>{},
    List<NarrativeRef> targetRefs = const <NarrativeRef>[],
    JsonMap metadata = const <String, Object?>{},
  }) async {
    final content = await _workspacePort.readTextFile(
      project.rootPath,
      relativePath,
    );
    if (content == null || content.trim().isEmpty) {
      return ProjectInformationImportCollectionResult(
        saved: false,
        blockedReason: '导入文件不存在或内容为空：$relativePath',
        summary: '未导入资料：$relativePath',
      );
    }
    return collectText(
      project,
      query: query,
      sourceText: content,
      sourceKind: 'imported_document',
      sourceRef: relativePath,
      sourceTitle: relativePath.split('/').last,
      purpose: purpose,
      requestedDepth: requestedDepth,
      informationDomain: informationDomain,
      referenceRelationship: referenceRelationship,
      sourceRequirements: sourceRequirements,
      extractionPolicy: extractionPolicy,
      targetRefs: targetRefs,
      metadata: <String, Object?>{
        ...metadata,
        'import_relative_path': relativePath,
      },
    );
  }

  Future<ProjectInformationImportCollectionResult> collectText(
    ProjectDescriptor project, {
    required String query,
    required String sourceText,
    String sourceKind = 'imported_text',
    String sourceRef = '',
    String sourceTitle = '',
    String purpose = '',
    String requestedDepth = '',
    String informationDomain = '',
    String referenceRelationship = '',
    JsonMap sourceRequirements = const <String, Object?>{},
    JsonMap extractionPolicy = const <String, Object?>{},
    List<NarrativeRef> targetRefs = const <NarrativeRef>[],
    JsonMap metadata = const <String, Object?>{},
  }) async {
    final normalizedQuery = query.trim();
    final normalizedText = sourceText.trim();
    if (normalizedQuery.isEmpty || normalizedText.isEmpty) {
      return const ProjectInformationImportCollectionResult(
        saved: false,
        blockedReason: '导入收集需要非空 query 和 sourceText。',
        summary: '未导入资料。',
      );
    }
    final collectionRequest = _collectionPolicyService.normalize(
      InformationCollectionRequest(
        query: normalizedQuery,
        purpose: purpose,
        requestedDepth: requestedDepth,
        referenceRelationship: referenceRelationship,
        collectionMode: InformationCollectionModes.import,
        informationDomain: informationDomain,
        targetRefs: targetRefs,
        sourceRequirements: InformationSourceRequirements.fromJson(
          sourceRequirements,
        ),
        extractionPolicy: InformationExtractionPolicy.fromJson(
          extractionPolicy,
        ),
        metadata: metadata,
      ),
    );
    final assessment = _sourceQualityService.assessImportedSource(
      sourceKind: sourceKind,
      sourceRef: sourceRef,
      requirements: collectionRequest.sourceRequirements,
      informationDomain: collectionRequest.informationDomain,
    );
    final excerpts = _candidateExcerpts(
      normalizedText,
      maxCount: collectionRequest.extractionPolicy.maxCandidateCount,
    );
    final noteId = _researchNoteId(sourceRef, sourceTitle);
    final note = ResearchNote(
      researchId: noteId,
      query: normalizedQuery,
      sourceKind: sourceKind.trim().isEmpty ? 'imported_text' : sourceKind,
      sourceUrlOrRef: sourceRef.trim().isEmpty
          ? 'imported_text:$noteId'
          : sourceRef.trim(),
      citation: sourceTitle.trim().isEmpty
          ? 'Imported source: $normalizedQuery'
          : sourceTitle.trim(),
      summary:
          '已导入资料 ${normalizedText.length} 字符，保留 ${excerpts.length} 个候选片段，等待后续抽取/提升。',
      usableFacts: <Object?>[
        for (var index = 0; index < excerpts.length; index += 1)
          <String, Object?>{
            'kind': 'imported_source_excerpt',
            'rank': index + 1,
            'excerpt': excerpts[index],
            'source_ref': sourceRef,
            'source_quality': assessment.toJson(),
            'verification_status': assessment.isRigorous
                ? 'rigorous_imported_source_candidate'
                : 'imported_source_needs_review',
          },
      ],
      creativeSuggestions: const <Object?>[],
      uncertainty:
          collectionRequest.sourceRequirements.requiresRigorousSources &&
              !assessment.isRigorous
          ? 'imported_source_requires_rigorous_review'
          : 'imported_source_preserved_pending_extraction',
      licenseOrUsageNote: '导入资料先作为 research note 保存；是否摘引、改写或提升为长期规则需后续策略确认。',
      createdBy: 'project_information_import_collection_service',
      linkedCards: targetRefs,
      usagePolicy: const InformationUsagePolicy(
        usageMode: InformationUsageModes.referenceOnly,
        citationRiskLevel: InformationCitationRiskLevels.normal,
        allowsDerivativeUse: true,
      ),
      metadata: <String, Object?>{
        'collection_request': collectionRequest.toJson(),
        'source_quality': assessment.toJson(),
        'source_title': sourceTitle,
        'source_ref': sourceRef,
        'source_text_char_count': normalizedText.length,
        'candidate_excerpt_count': excerpts.length,
        'collected_at': DateTime.now().toIso8601String(),
        ...metadata,
      },
    );
    await _researchNoteRepository.appendResearchNote(project, note);
    final changedPaths = <String>[
      _pathService.researchNotePath(note.researchId),
      _pathService.researchNotesIndexPath(),
    ];
    await _appendInformationEvent(project, note);
    changedPaths.add(_pathService.informationEventsLogPath());
    final documents = await _projectionWriterService.writeProjection(project);
    changedPaths.addAll(documents.map((entry) => entry.relativePath));
    return ProjectInformationImportCollectionResult(
      saved: true,
      researchNote: note,
      summary: '已导入资料为 research note：${note.researchId}',
      changedPaths: changedPaths.toSet().toList(growable: false),
    );
  }

  Future<void> _appendInformationEvent(
    ProjectDescriptor project,
    ResearchNote note,
  ) {
    final event = InformationEvent(
      eventId: 'import_research:${note.researchId}',
      eventType: 'import_research_completed',
      subjectRef: NarrativeRef(
        refType: InformationLinkedRefTypes.researchNote,
        refId: note.researchId,
      ),
      lifecycleStatus: InformationLifecycleStatuses.accepted,
      actorRef: const NarrativeRef(
        refType: NarrativeRefTypes.toolRound,
        refId: 'import_collection',
      ),
      summary: '导入资料已生成 research note：${note.query}',
      occurredAt: DateTime.now().toIso8601String(),
      metadata: <String, Object?>{
        'generated_research_note_id': note.researchId,
      },
    );
    return _informationEventRepository.appendInformationEvent(project, event);
  }

  List<String> _candidateExcerpts(String value, {required int maxCount}) {
    final targetCount = maxCount <= 0 ? 8 : maxCount.clamp(1, 24).toInt();
    final paragraphs = value
        .split(RegExp(r'\n\s*\n|\r\n\s*\r\n'))
        .map((entry) => entry.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final result = <String>[];
    for (final paragraph in paragraphs) {
      result.add(_trimText(paragraph, 700));
      if (result.length >= targetCount) {
        break;
      }
    }
    if (result.isEmpty) {
      result.add(_trimText(value.replaceAll(RegExp(r'\s+'), ' ').trim(), 700));
    }
    return result;
  }

  String _researchNoteId(String sourceRef, String sourceTitle) {
    final seed = sourceRef.trim().isNotEmpty ? sourceRef : sourceTitle;
    return 'import_${_safeId(seed, fallback: 'source')}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _safeId(String value, {required String fallback}) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? fallback : normalized;
  }

  String _trimText(String value, int maxChars) {
    final normalized = value.trim();
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return normalized.substring(0, maxChars);
  }
}
