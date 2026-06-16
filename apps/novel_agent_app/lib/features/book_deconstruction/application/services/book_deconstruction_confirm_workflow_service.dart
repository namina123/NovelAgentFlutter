import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_followup_persistence_service.dart';
import 'book_deconstruction_narrative_persistence_service.dart';
import 'book_deconstruction_preview_markdown_service.dart';

class BookDeconstructionConfirmWorkflowService {
  BookDeconstructionConfirmWorkflowService({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required BookDeconstructionNarrativePersistenceService
    narrativePersistenceService,
    BookDeconstructionPreviewMarkdownService? previewMarkdownService,
    BookDeconstructionTargetPathService? targetPathService,
    BookDeconstructionFollowupPersistenceService? followupPersistenceService,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _narrativePersistenceService = narrativePersistenceService,
       _previewMarkdownService =
           previewMarkdownService ??
           const BookDeconstructionPreviewMarkdownService(),
       _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService(),
       _followupPersistenceService =
           followupPersistenceService ??
           BookDeconstructionFollowupPersistenceService(
             writeProjectTextFileUseCase: writeProjectTextFileUseCase,
             targetPathService:
                 targetPathService ??
                 const BookDeconstructionTargetPathService(),
           );

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final BookDeconstructionNarrativePersistenceService
  _narrativePersistenceService;
  final BookDeconstructionPreviewMarkdownService _previewMarkdownService;
  final BookDeconstructionTargetPathService _targetPathService;
  final BookDeconstructionFollowupPersistenceService
  _followupPersistenceService;

  Future<BookDeconstructionConfirmWorkflowResult> execute({
    required ProjectDescriptor project,
    required BookDeconstructionDraftBuildResult buildResult,
    required Set<String> selectedItemIds,
    required String selectedFollowupOptionId,
  }) async {
    // 中文注释: 预演确认的正式写入编排集中在这里，controller 只负责状态推进与结果消费。
    final previewPath = _targetPathService.previewPath();
    final markdown = _previewMarkdownService.render(
      buildResult: buildResult,
      selectedItemIds: selectedItemIds,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: previewPath,
      content: markdown,
    );
    final changedPaths = await _narrativePersistenceService.persist(
      project: project,
      narrativeArtifacts: buildResult.narrativeArtifacts,
    );
    final followupResult = await _followupPersistenceService.persist(
      project: project,
      buildResult: buildResult,
      followupOptionId: selectedFollowupOptionId,
    );
    return BookDeconstructionConfirmWorkflowResult(
      previewPath: previewPath,
      guidePath: followupResult.guidePath,
      selectedFollowupOptionId: followupResult.option.id,
      selectedFollowupOptionTitle: followupResult.option.title,
      inheritedChapterPaths: followupResult.inheritedChapterPaths,
      changedPaths: <String>[
        ...changedPaths,
        followupResult.planPath,
        followupResult.guidePath,
        ...followupResult.inheritedChapterPaths,
      ],
    );
  }
}

class BookDeconstructionConfirmWorkflowResult {
  const BookDeconstructionConfirmWorkflowResult({
    required this.previewPath,
    required this.guidePath,
    required this.selectedFollowupOptionId,
    required this.selectedFollowupOptionTitle,
    required this.inheritedChapterPaths,
    required this.changedPaths,
  });

  final String previewPath;
  final String guidePath;
  final String selectedFollowupOptionId;
  final String selectedFollowupOptionTitle;
  final List<String> inheritedChapterPaths;
  final List<String> changedPaths;
}
