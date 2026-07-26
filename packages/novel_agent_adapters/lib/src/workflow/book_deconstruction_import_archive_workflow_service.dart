import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_structured_content_bridge_service.dart';
import '../storage/reference_source_document_file_reader_service.dart';

class BookDeconstructionImportArchiveWorkflowService {
  BookDeconstructionImportArchiveWorkflowService({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    ReferenceSourceDocumentFileReaderService? sourceDocumentReaderService,
    BookDeconstructionTargetPathService? targetPathService,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _sourceDocumentReaderService =
           sourceDocumentReaderService ??
           const ReferenceSourceDocumentFileReaderService(),
       _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService(),
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase;

  final ReferenceSourceDocumentFileReaderService _sourceDocumentReaderService;
  final BookDeconstructionTargetPathService _targetPathService;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;

  Future<BookDeconstructionImportArchiveResult> execute({
    required ProjectDescriptor project,
    required String sourceFilePath,
  }) async {
    // 中文注释: 导入归档编排只在这里做，controller 不再自己读文件、算路径和写入来源层。
    final sourceDocument = await _sourceDocumentReaderService.read(
      sourceFilePath: sourceFilePath,
    );
    final archivePath = _targetPathService.sourceArchivePath(
      sourceDocument.sourceFilePath,
      storageStrategy: project.storageStrategy,
    );
    final sourceText = sourceDocument.sourceText.trim();
    final previousDocument = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: archivePath);
    try {
      // SQLite source archives are the primary record; Markdown remains a
      // readable projection for the deconstruction workspace.
      await _structuredContentBridgeService.persistSourceOriginalArchive(
        project: project,
        archivePath: archivePath,
        archiveTitle: sourceDocument.sourceTitle,
        sourceContent: sourceText,
      );
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: archivePath,
        content: sourceText,
      );
    } catch (_) {
      try {
        await _structuredContentBridgeService.restoreStructuredDocument(
          project: project,
          documentPath: archivePath,
          snapshot: previousDocument,
        );
      } catch (_) {}
      rethrow;
    }
    return BookDeconstructionImportArchiveResult(
      sourceFilePath: sourceDocument.sourceFilePath,
      sourceTitle: sourceDocument.sourceTitle,
      sourceText: sourceText,
      archivePath: archivePath,
    );
  }
}

class BookDeconstructionImportArchiveResult {
  const BookDeconstructionImportArchiveResult({
    required this.sourceFilePath,
    required this.sourceTitle,
    required this.sourceText,
    required this.archivePath,
  });

  final String sourceFilePath;
  final String sourceTitle;
  final String sourceText;
  final String archivePath;
}
