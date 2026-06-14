import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_reference_alignment_summary_service.dart';
import 'project_information_projection_compatibility_exporter.dart';
import 'project_information_projection_writer_service.dart';
import 'project_reference_projection_port.dart';

class ProjectReferenceProjectionService
    implements ProjectReferenceProjectionPort {
  ProjectReferenceProjectionService({
    required ReferenceEvidenceSubstrate substrate,
    required ProjectReferenceAttachmentLayer attachmentLayer,
    required ProjectWorkspacePort workspacePort,
    required KnowledgeCardRepository knowledgeCardRepository,
    required DesignElementRepository designElementRepository,
    required ResearchNoteRepository researchNoteRepository,
    required ReferenceWorkRepository referenceWorkRepository,
    required ProjectInformationProjectionWriterService projectionWriterService,
    ProjectReferenceAlignmentSummaryService? alignmentSummaryService,
    ProjectInformationProjectionCompatibilityExporter? compatibilityExporter,
    ProjectReferenceAccessPolicyService? accessPolicyService,
    ReferenceEntryProjectionMapperService? entryProjectionMapperService,
  }) : _substrate = substrate,
       _attachmentLayer = attachmentLayer,
       _workspacePort = workspacePort,
       _knowledgeCardRepository = knowledgeCardRepository,
       _designElementRepository = designElementRepository,
       _researchNoteRepository = researchNoteRepository,
       _referenceWorkRepository = referenceWorkRepository,
       _projectionWriterService = projectionWriterService,
       _alignmentSummaryService =
           alignmentSummaryService ?? const ProjectReferenceAlignmentSummaryService(),
       _compatibilityExporter = compatibilityExporter,
       _accessPolicyService =
           accessPolicyService ?? const ProjectReferenceAccessPolicyService(),
       _entryProjectionMapperService =
           entryProjectionMapperService ??
           const ReferenceEntryProjectionMapperService();

  final ReferenceEvidenceSubstrate _substrate;
  final ProjectReferenceAttachmentLayer _attachmentLayer;
  final ProjectWorkspacePort _workspacePort;
  final KnowledgeCardRepository _knowledgeCardRepository;
  final DesignElementRepository _designElementRepository;
  final ResearchNoteRepository _researchNoteRepository;
  final ReferenceWorkRepository _referenceWorkRepository;
  final ProjectInformationProjectionWriterService _projectionWriterService;
  final ProjectReferenceAlignmentSummaryService _alignmentSummaryService;
  final ProjectInformationProjectionCompatibilityExporter?
  _compatibilityExporter;
  final ProjectReferenceAccessPolicyService _accessPolicyService;
  final ReferenceEntryProjectionMapperService _entryProjectionMapperService;

  @override
  Future<ReferenceProjectionResult> projectMountedEntries(
    ProjectDescriptor project,
    ReferenceProjectionRequest request,
  ) async {
    final attachment = await _attachmentLayer.readAttachment(
      project,
      packageId: request.packageId,
    );
    final decision = _accessPolicyService.decide(
      request: ProjectReferenceAccessRequest(
        projectId: project.id,
        packageId: request.packageId,
        packageVersionId: request.packageVersionId,
        operation: ReferenceAccessOperations.projectEntry,
        explicitConfirmationGranted: request.explicitConfirmationGranted,
      ),
      attachment: attachment,
    );
    if (!decision.allowed || attachment == null) {
      return ReferenceProjectionResult(
        status: attachment == null
            ? ReferenceProjectionStatuses.missingAttachment
            : ReferenceProjectionStatuses.denied,
        packageId: request.packageId,
        packageVersionId: request.packageVersionId,
        warnings: <String>[decision.reasonCode],
      );
    }
    final packageVersionId = request.packageVersionId.isEmpty
        ? attachment.packageVersionId
        : request.packageVersionId;
    final snapshot = await _substrate.readPackageSnapshot(
      packageId: request.packageId,
      packageVersionId: packageVersionId,
    );
    if (snapshot == null) {
      return ReferenceProjectionResult(
        status: ReferenceProjectionStatuses.missingPackage,
        packageId: request.packageId,
        packageVersionId: packageVersionId,
        warnings: const <String>['package_snapshot_missing'],
      );
    }
    final filteredEntries = request.entryIds.isEmpty
        ? snapshot.entries
        : snapshot.entries
              .where((entry) => request.entryIds.contains(entry.entryId))
              .toList(growable: false);
    final bundle = _entryProjectionMapperService.buildDraftBundle(
      packageRecord: snapshot.packageRecord,
      packageVersionRecord: snapshot.packageVersionRecord,
      entries: filteredEntries,
    );
    for (final card in bundle.knowledgeCardDrafts) {
      await _knowledgeCardRepository.updateKnowledgeCard(project, card);
    }
    for (final card in bundle.designElementDrafts) {
      await _designElementRepository.updateDesignElement(project, card);
    }
    for (final note in bundle.researchNoteDrafts) {
      await _researchNoteRepository.updateResearchNote(project, note);
    }
    for (final record in bundle.referenceWorkDrafts) {
      await _referenceWorkRepository.updateReferenceWork(project, record);
    }
    if (_compatibilityExporter != null) {
      await _compatibilityExporter.exportDraftBundle(project, bundle);
    }
    final projections = await _projectionWriterService.writeProjection(project);
    final alignmentSummaryPath = await _writeAlignmentSummary(
      project: project,
      attachment: attachment,
      packageRecord: snapshot.packageRecord,
      packageVersionRecord: snapshot.packageVersionRecord,
      bundle: bundle,
    );
    return ReferenceProjectionResult(
      status: ReferenceProjectionStatuses.applied,
      packageId: request.packageId,
      packageVersionId: packageVersionId,
      knowledgeCardIds: bundle.knowledgeCardDrafts
          .map((item) => item.cardId)
          .toList(growable: false),
      designElementIds: bundle.designElementDrafts
          .map((item) => item.designId)
          .toList(growable: false),
      researchNoteIds: bundle.researchNoteDrafts
          .map((item) => item.researchId)
          .toList(growable: false),
      referenceWorkIds: bundle.referenceWorkDrafts
          .map((item) => item.referenceWorkId)
          .toList(growable: false),
      generatedProjectionPaths: projections
          .map((item) => item.relativePath)
          .followedBy(<String>[alignmentSummaryPath])
          .toList(growable: false),
    );
  }

  Future<String> _writeAlignmentSummary({
    required ProjectDescriptor project,
    required ProjectReferenceAttachment attachment,
    required ReferencePackageRecord packageRecord,
    required ReferencePackageVersionRecord packageVersionRecord,
    required InformationProjectionDraftBundle bundle,
  }) async {
    // 中文注释: 对齐摘要文件由独立服务生成，主 projection service 只负责把它落到知识目录。
    final markdown = _alignmentSummaryService.buildMarkdown(
      project: project,
      attachment: attachment,
      packageRecord: packageRecord,
      packageVersionRecord: packageVersionRecord,
      bundle: bundle,
    );
    await _workspacePort.createDirectory(project.rootPath, 'knowledge');
    await _workspacePort.writeTextFile(
      project.rootPath,
      ProjectReferenceAlignmentSummaryService.summaryRelativePath,
      markdown,
    );
    return ProjectReferenceAlignmentSummaryService.summaryRelativePath;
  }
}
