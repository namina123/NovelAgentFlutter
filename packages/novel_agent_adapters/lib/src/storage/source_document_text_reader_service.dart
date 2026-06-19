import 'reference_source_document_file_read_result.dart';
import 'source_document_format_catalog_service.dart';
import 'source_document_isolate_reader_service.dart';

class SourceDocumentTextReaderService {
  const SourceDocumentTextReaderService({
    SourceDocumentFormatCatalogService? formatCatalogService,
    SourceDocumentIsolateReaderService? isolateReaderService,
  }) : _formatCatalogService =
           formatCatalogService ?? const SourceDocumentFormatCatalogService(),
       _isolateReaderService =
           isolateReaderService ?? const SourceDocumentIsolateReaderService();

  final SourceDocumentFormatCatalogService _formatCatalogService;
  final SourceDocumentIsolateReaderService _isolateReaderService;

  bool supports(String sourceFilePath) {
    // 中文注释: 文本 reader 只承接 txt 与 markdown，具体格式归属仍由统一格式目录决定。
    final readerKind = _formatCatalogService.readerKindForPath(sourceFilePath);
    return readerKind == SourceDocumentFormatCatalogService.plainTextFormatId;
  }

  Future<ReferenceSourceDocumentFileReadResult> read({
    required String sourceFilePath,
  }) async {
    // 中文注释: 重文本解码移到独立 isolate，避免大 txt / markdown 导入时把 UI isolate 卡死。
    return _isolateReaderService.readPlainText(sourceFilePath: sourceFilePath);
  }
}
