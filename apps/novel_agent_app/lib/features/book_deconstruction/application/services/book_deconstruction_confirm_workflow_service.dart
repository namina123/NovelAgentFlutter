import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_narrative_persistence_service.dart';
import 'book_deconstruction_preview_markdown_service.dart';

class BookDeconstructionConfirmWorkflowService {
  BookDeconstructionConfirmWorkflowService({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required BookDeconstructionNarrativePersistenceService
    narrativePersistenceService,
    BookDeconstructionPreviewMarkdownService? previewMarkdownService,
    BookDeconstructionTargetPathService? targetPathService,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _narrativePersistenceService = narrativePersistenceService,
       _previewMarkdownService =
           previewMarkdownService ??
           const BookDeconstructionPreviewMarkdownService(),
       _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService();

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final BookDeconstructionNarrativePersistenceService
  _narrativePersistenceService;
  final BookDeconstructionPreviewMarkdownService _previewMarkdownService;
  final BookDeconstructionTargetPathService _targetPathService;

  Future<BookDeconstructionConfirmWorkflowResult> execute({
    required ProjectDescriptor project,
    required BookDeconstructionDraftBuildResult buildResult,
    required Set<String> selectedItemIds,
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
    return BookDeconstructionConfirmWorkflowResult(
      previewPath: previewPath,
      changedPaths: changedPaths,
    );
  }
}

class BookDeconstructionConfirmWorkflowResult {
  const BookDeconstructionConfirmWorkflowResult({
    required this.previewPath,
    required this.changedPaths,
  });

  final String previewPath;
  final List<String> changedPaths;
}
