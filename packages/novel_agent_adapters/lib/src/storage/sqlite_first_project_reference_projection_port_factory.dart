import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_information_json_compatibility_export_service.dart';
import 'project_information_projection_compatibility_exporter.dart';
import 'project_information_projection_writer_service.dart';
import 'project_reference_projection_port.dart';
import 'project_reference_projection_service.dart';
import 'sqlite_design_element_repository.dart';
import 'sqlite_knowledge_card_repository.dart';
import 'sqlite_project_information_record_store.dart';
import 'sqlite_reference_work_repository.dart';
import 'sqlite_research_note_repository.dart';

class SqliteFirstProjectReferenceProjectionPortFactory
    implements ProjectReferenceProjectionPortFactory {
  SqliteFirstProjectReferenceProjectionPortFactory({
    required ProjectWorkspacePort workspacePort,
    SqliteProjectInformationRecordStore? recordStore,
    ProjectInformationProjectionCompatibilityExporter? compatibilityExporter,
    bool enableJsonCompatibilityExport = false,
  }) : _workspacePort = workspacePort,
       _recordStore = recordStore ?? SqliteProjectInformationRecordStore(),
       _compatibilityExporter = compatibilityExporter,
       _enableJsonCompatibilityExport = enableJsonCompatibilityExport;

  final ProjectWorkspacePort _workspacePort;
  final SqliteProjectInformationRecordStore _recordStore;
  final ProjectInformationProjectionCompatibilityExporter?
  _compatibilityExporter;
  final bool _enableJsonCompatibilityExport;

  @override
  ProjectReferenceProjectionPort create({
    required ReferenceEvidenceSubstrate substrate,
    required ProjectReferenceAttachmentLayer attachmentLayer,
  }) {
    final knowledgeCardRepository = SqliteKnowledgeCardRepository(
      recordStore: _recordStore,
    );
    final designElementRepository = SqliteDesignElementRepository(
      recordStore: _recordStore,
    );
    final researchNoteRepository = SqliteResearchNoteRepository(
      recordStore: _recordStore,
    );
    final referenceWorkRepository = SqliteReferenceWorkRepository(
      recordStore: _recordStore,
    );
    final projectionWriterService = ProjectInformationProjectionWriterService(
      workspacePort: _workspacePort,
      knowledgeCardRepository: knowledgeCardRepository,
      designElementRepository: designElementRepository,
      researchNoteRepository: researchNoteRepository,
      referenceWorkRepository: referenceWorkRepository,
    );
    return ProjectReferenceProjectionService(
      substrate: substrate,
      attachmentLayer: attachmentLayer,
      knowledgeCardRepository: knowledgeCardRepository,
      designElementRepository: designElementRepository,
      researchNoteRepository: researchNoteRepository,
      referenceWorkRepository: referenceWorkRepository,
      projectionWriterService: projectionWriterService,
      compatibilityExporter:
          _compatibilityExporter ??
          (_enableJsonCompatibilityExport
              ? ProjectInformationJsonCompatibilityExportService(
                  workspacePort: _workspacePort,
                )
              : null),
    );
  }
}
