import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectInformationProjectionWriterService {
  ProjectInformationProjectionWriterService({
    required ProjectWorkspacePort workspacePort,
    required KnowledgeCardRepository knowledgeCardRepository,
    required DesignElementRepository designElementRepository,
    required ResearchNoteRepository researchNoteRepository,
    required ReferenceWorkRepository referenceWorkRepository,
    InformationMarkdownProjectionService? projectionService,
    ProjectStructuredContentWritePolicy? structuredContentWritePolicy,
  }) : _workspacePort = workspacePort,
       _knowledgeCardRepository = knowledgeCardRepository,
       _designElementRepository = designElementRepository,
       _researchNoteRepository = researchNoteRepository,
       _referenceWorkRepository = referenceWorkRepository,
       _projectionService =
           projectionService ?? InformationMarkdownProjectionService(),
       _structuredContentWritePolicy =
           structuredContentWritePolicy ??
           const ProjectStructuredContentWritePolicy();

  final ProjectWorkspacePort _workspacePort;
  final KnowledgeCardRepository _knowledgeCardRepository;
  final DesignElementRepository _designElementRepository;
  final ResearchNoteRepository _researchNoteRepository;
  final ReferenceWorkRepository _referenceWorkRepository;
  final InformationMarkdownProjectionService _projectionService;
  final ProjectStructuredContentWritePolicy _structuredContentWritePolicy;

  Future<List<InformationProjectionDocument>> writeProjection(
    ProjectDescriptor project,
  ) async {
    if (!_structuredContentWritePolicy.shouldWriteToFilesystemPrimarySource(
      storageStrategy: project.storageStrategy,
      documentKind: 'knowledge',
    )) {
      return const <InformationProjectionDocument>[];
    }
    final source = InformationProjectionSource(
      knowledgeCards: await _knowledgeCardRepository.listKnowledgeCards(
        project,
      ),
      designElements: await _designElementRepository.listDesignElements(
        project,
      ),
      researchNotes: await _researchNoteRepository.listResearchNotes(project),
      referenceWorks: await _referenceWorkRepository.listReferenceWorks(
        project,
      ),
    );
    final documents = _projectionService.buildDocuments(source);
    for (final document in documents) {
      await _workspacePort.writeTextFile(
        project.rootPath,
        document.relativePath,
        document.markdown,
      );
    }
    return documents;
  }
}
