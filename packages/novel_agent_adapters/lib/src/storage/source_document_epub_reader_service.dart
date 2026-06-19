import 'reference_source_document_file_read_result.dart';
import 'source_document_format_catalog_service.dart';
import 'source_document_isolate_reader_service.dart';

class SourceDocumentEpubReaderService {
  const SourceDocumentEpubReaderService({
    SourceDocumentFormatCatalogService? formatCatalogService,
    SourceDocumentIsolateReaderService? isolateReaderService,
  }) : _formatCatalogService =
           formatCatalogService ?? const SourceDocumentFormatCatalogService(),
       _isolateReaderService =
           isolateReaderService ?? const SourceDocumentIsolateReaderService();

  final SourceDocumentFormatCatalogService _formatCatalogService;
  final SourceDocumentIsolateReaderService _isolateReaderService;

  bool supports(String sourceFilePath) {
    // 中文注释: EPUB reader 只承接 epub 格式，避免和普通文本 reader 互相抢路由。
    return _formatCatalogService.readerKindForPath(sourceFilePath) ==
        SourceDocumentFormatCatalogService.epubFormatId;
  }

  Future<ReferenceSourceDocumentFileReadResult> read({
    required String sourceFilePath,
  }) async {
    // 中文注释: EPUB 解压和 XHTML 抽取统一移到 isolate，避免 zip 解析把窗口线程压死。
    return _isolateReaderService.readEpub(sourceFilePath: sourceFilePath);
  }
}
