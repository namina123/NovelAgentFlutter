import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionInformationPersistenceBundle {
  BookDeconstructionInformationPersistenceBundle({
    required this.knowledgeCardRepository,
    required this.designElementRepository,
    required this.researchNoteRepository,
    required this.referenceWorkRepository,
    required this.projectionWriterService,
  });

  final KnowledgeCardRepository knowledgeCardRepository;
  final DesignElementRepository designElementRepository;
  final ResearchNoteRepository researchNoteRepository;
  final ReferenceWorkRepository referenceWorkRepository;
  final ProjectInformationProjectionWriterService projectionWriterService;
}

class BookDeconstructionInformationPersistenceBundleFactory {
  BookDeconstructionInformationPersistenceBundleFactory({
    required ProjectWorkspacePort workspacePort,
    SqliteProjectInformationRecordStore? sqliteRecordStore,
  }) : _workspacePort = workspacePort,
       _sqliteRecordStore =
           sqliteRecordStore ?? SqliteProjectInformationRecordStore();

  final ProjectWorkspacePort _workspacePort;
  final SqliteProjectInformationRecordStore _sqliteRecordStore;

  BookDeconstructionInformationPersistenceBundle create(
    ProjectStorageStrategy storageStrategy,
  ) {
    switch (storageStrategy) {
      case ProjectStorageStrategy.sqliteProjectStore:
        final knowledgeCardRepository = SqliteKnowledgeCardRepository(
          recordStore: _sqliteRecordStore,
        );
        final designElementRepository = SqliteDesignElementRepository(
          recordStore: _sqliteRecordStore,
        );
        final researchNoteRepository = SqliteResearchNoteRepository(
          recordStore: _sqliteRecordStore,
        );
        final referenceWorkRepository = SqliteReferenceWorkRepository(
          recordStore: _sqliteRecordStore,
        );
        return BookDeconstructionInformationPersistenceBundle(
          knowledgeCardRepository: knowledgeCardRepository,
          designElementRepository: designElementRepository,
          researchNoteRepository: researchNoteRepository,
          referenceWorkRepository: referenceWorkRepository,
          projectionWriterService: ProjectInformationProjectionWriterService(
            workspacePort: _workspacePort,
            knowledgeCardRepository: knowledgeCardRepository,
            designElementRepository: designElementRepository,
            researchNoteRepository: researchNoteRepository,
            referenceWorkRepository: referenceWorkRepository,
          ),
        );
      case ProjectStorageStrategy.markdownProjectStore:
        final knowledgeCardRepository = LocalKnowledgeCardRepository(
          workspacePort: _workspacePort,
        );
        final designElementRepository = LocalDesignElementRepository(
          workspacePort: _workspacePort,
        );
        final researchNoteRepository = LocalResearchNoteRepository(
          workspacePort: _workspacePort,
        );
        final referenceWorkRepository = LocalReferenceWorkRepository(
          workspacePort: _workspacePort,
        );
        return BookDeconstructionInformationPersistenceBundle(
          knowledgeCardRepository: knowledgeCardRepository,
          designElementRepository: designElementRepository,
          researchNoteRepository: researchNoteRepository,
          referenceWorkRepository: referenceWorkRepository,
          projectionWriterService: ProjectInformationProjectionWriterService(
            workspacePort: _workspacePort,
            knowledgeCardRepository: knowledgeCardRepository,
            designElementRepository: designElementRepository,
            researchNoteRepository: researchNoteRepository,
            referenceWorkRepository: referenceWorkRepository,
          ),
        );
    }
  }
}
