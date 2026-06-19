import 'dart:io';

import 'reference_source_document_file_reader_service.dart';
import 'source_document_format_catalog_service.dart';

class ProjectTextFileReadService {
  const ProjectTextFileReadService({
    SourceDocumentFormatCatalogService? formatCatalogService,
    ReferenceSourceDocumentFileReaderService? sourceDocumentReaderService,
  }) : _formatCatalogService =
           formatCatalogService ?? const SourceDocumentFormatCatalogService(),
       _sourceDocumentReaderService =
           sourceDocumentReaderService ??
           const ReferenceSourceDocumentFileReaderService();

  final SourceDocumentFormatCatalogService _formatCatalogService;
  final ReferenceSourceDocumentFileReaderService _sourceDocumentReaderService;

  Future<String?> readFile(String absolutePath) async {
    final file = File(absolutePath);
    if (!await file.exists()) {
      return null;
    }
    if (_formatCatalogService.supportsPath(absolutePath)) {
      try {
        final sourceDocument = await _sourceDocumentReaderService.read(
          sourceFilePath: absolutePath,
        );
        return sourceDocument.sourceText;
      } on FileSystemException catch (error) {
        if (_isUtf8DecodeFailure(error)) {
          return null;
        }
        rethrow;
      } catch (_) {
        return null;
      }
    }
    try {
      return await file.readAsString();
    } on FileSystemException catch (error) {
      if (_isUtf8DecodeFailure(error)) {
        return null;
      }
      rethrow;
    }
  }

  bool _isUtf8DecodeFailure(FileSystemException error) {
    final message = [
      error.message,
      error.osError?.message ?? '',
    ].join(' ').toLowerCase();
    return message.contains("decode data using encoding 'utf-8'") ||
        message.contains('encoding utf-8') ||
        message.contains("encoding 'utf-8'") ||
        message.contains('utf-8');
  }
}
