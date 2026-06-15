import 'reference_source_document_file_read_result.dart';
import 'source_document_epub_reader_service.dart';
import 'source_document_format_catalog_service.dart';
import 'source_document_text_reader_service.dart';

class ReferenceSourceDocumentFileReaderService {
  const ReferenceSourceDocumentFileReaderService({
    SourceDocumentFormatCatalogService? formatCatalogService,
    SourceDocumentTextReaderService? textReaderService,
    SourceDocumentEpubReaderService? epubReaderService,
  }) : _formatCatalogService =
           formatCatalogService ?? const SourceDocumentFormatCatalogService(),
       _textReaderService =
           textReaderService ?? const SourceDocumentTextReaderService(),
       _epubReaderService =
           epubReaderService ?? const SourceDocumentEpubReaderService();

  final SourceDocumentFormatCatalogService _formatCatalogService;
  final SourceDocumentTextReaderService _textReaderService;
  final SourceDocumentEpubReaderService _epubReaderService;

  Future<ReferenceSourceDocumentFileReadResult> read({
    required String sourceFilePath,
  }) async {
    // 中文注释: 这里是唯一的 source document reader 正式入口，按格式目录把文件路由到对应 reader。
    final descriptor = _formatCatalogService.resolveByPath(sourceFilePath);
    if (descriptor == null) {
      throw StateError('Unsupported source document format: $sourceFilePath');
    }
    switch (descriptor.readerKind) {
      case SourceDocumentFormatCatalogService.epubFormatId:
        return _epubReaderService.read(sourceFilePath: sourceFilePath);
      case SourceDocumentFormatCatalogService.plainTextFormatId:
      default:
        return _textReaderService.read(sourceFilePath: sourceFilePath);
    }
  }
}
