import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_design_element_repository.dart';
import 'local_knowledge_card_repository.dart';
import 'local_reference_work_repository.dart';
import 'local_research_note_repository.dart';
import 'project_information_projection_compatibility_exporter.dart';

class ProjectInformationJsonCompatibilityExportService
    implements ProjectInformationProjectionCompatibilityExporter {
  ProjectInformationJsonCompatibilityExportService({
    required ProjectWorkspacePort workspacePort,
    LocalKnowledgeCardRepository? knowledgeCardRepository,
    LocalDesignElementRepository? designElementRepository,
    LocalResearchNoteRepository? researchNoteRepository,
    LocalReferenceWorkRepository? referenceWorkRepository,
  }) : _knowledgeCardRepository =
           knowledgeCardRepository ??
           LocalKnowledgeCardRepository(workspacePort: workspacePort),
       _designElementRepository =
           designElementRepository ??
           LocalDesignElementRepository(workspacePort: workspacePort),
       _researchNoteRepository =
           researchNoteRepository ??
           LocalResearchNoteRepository(workspacePort: workspacePort),
       _referenceWorkRepository =
           referenceWorkRepository ??
           LocalReferenceWorkRepository(workspacePort: workspacePort);

  final LocalKnowledgeCardRepository _knowledgeCardRepository;
  final LocalDesignElementRepository _designElementRepository;
  final LocalResearchNoteRepository _researchNoteRepository;
  final LocalReferenceWorkRepository _referenceWorkRepository;

  @override
  Future<void> exportDraftBundle(
    ProjectDescriptor project,
    InformationProjectionDraftBundle bundle,
  ) async {
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
  }
}
