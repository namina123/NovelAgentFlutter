import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/local_design_element_repository.dart';
import '../storage/local_knowledge_card_repository.dart';
import '../storage/local_reference_work_repository.dart';
import '../storage/local_research_note_repository.dart';
import '../storage/project_information_path_service.dart';
import '../storage/project_information_projection_writer_service.dart';

class ProjectSemanticReviewInformationService {
  ProjectSemanticReviewInformationService({
    required ProjectWorkspacePort workspacePort,
    SemanticReviewInformationBridgeService? bridgeService,
    KnowledgeCardRepository? knowledgeCardRepository,
    DesignElementRepository? designElementRepository,
    ResearchNoteRepository? researchNoteRepository,
    ProjectInformationProjectionWriterService? projectionWriterService,
    ProjectInformationPathService? pathService,
  }) : _bridgeService =
           bridgeService ?? const SemanticReviewInformationBridgeService(),
       _knowledgeCardRepository =
           knowledgeCardRepository ??
           LocalKnowledgeCardRepository(workspacePort: workspacePort),
       _designElementRepository =
           designElementRepository ??
           LocalDesignElementRepository(workspacePort: workspacePort),
       _researchNoteRepository =
           researchNoteRepository ??
           LocalResearchNoteRepository(workspacePort: workspacePort),
       _projectionWriterService =
           projectionWriterService ??
           ProjectInformationProjectionWriterService(
             workspacePort: workspacePort,
             knowledgeCardRepository:
                 knowledgeCardRepository ??
                 LocalKnowledgeCardRepository(workspacePort: workspacePort),
             designElementRepository:
                 designElementRepository ??
                 LocalDesignElementRepository(workspacePort: workspacePort),
             researchNoteRepository:
                 researchNoteRepository ??
                 LocalResearchNoteRepository(workspacePort: workspacePort),
             referenceWorkRepository: LocalReferenceWorkRepository(
               workspacePort: workspacePort,
             ),
           ),
       _pathService = pathService ?? ProjectInformationPathService();

  final SemanticReviewInformationBridgeService _bridgeService;
  final KnowledgeCardRepository _knowledgeCardRepository;
  final DesignElementRepository _designElementRepository;
  final ResearchNoteRepository _researchNoteRepository;
  final ProjectInformationProjectionWriterService _projectionWriterService;
  final ProjectInformationPathService _pathService;

  Future<JsonMap> persist({
    required ProjectDescriptor project,
    required List<NarrativeSemanticReview> reviews,
  }) async {
    final changedPaths = <String>[];
    final knowledgeCardIds = <String>[];
    final designElementIds = <String>[];
    final researchNoteIds = <String>[];
    for (final review in reviews) {
      final result = _bridgeService.build(review: review);
      for (final card in result.knowledgeCards) {
        await _knowledgeCardRepository.appendKnowledgeCard(project, card);
        knowledgeCardIds.add(card.cardId);
        changedPaths
          ..add(_pathService.knowledgeCardPath(card.cardId))
          ..add(_pathService.knowledgeCardsIndexPath());
      }
      for (final card in result.designElements) {
        await _designElementRepository.appendDesignElement(project, card);
        designElementIds.add(card.designId);
        changedPaths
          ..add(_pathService.designElementPath(card.designId))
          ..add(_pathService.designElementsIndexPath());
      }
      for (final note in result.researchNotes) {
        await _researchNoteRepository.appendResearchNote(project, note);
        researchNoteIds.add(note.researchId);
        changedPaths
          ..add(_pathService.researchNotePath(note.researchId))
          ..add(_pathService.researchNotesIndexPath());
      }
    }
    if (knowledgeCardIds.isEmpty &&
        designElementIds.isEmpty &&
        researchNoteIds.isEmpty) {
      return const <String, Object?>{
        'knowledge_card_ids': <Object?>[],
        'design_element_ids': <Object?>[],
        'research_note_ids': <Object?>[],
        'changed_paths': <Object?>[],
        'output_paths': <Object?>[],
      };
    }
    final documents = await _projectionWriterService.writeProjection(project);
    changedPaths.addAll(documents.map((entry) => entry.relativePath));
    return <String, Object?>{
      'knowledge_card_ids': knowledgeCardIds.toSet().toList(growable: false),
      'design_element_ids': designElementIds.toSet().toList(growable: false),
      'research_note_ids': researchNoteIds.toSet().toList(growable: false),
      'changed_paths': changedPaths.toSet().toList(growable: false),
      'output_paths': documents
          .map((entry) => entry.relativePath)
          .toList(growable: false),
    };
  }
}
