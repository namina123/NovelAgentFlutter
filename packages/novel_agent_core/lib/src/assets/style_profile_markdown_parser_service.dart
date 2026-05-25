import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/frontmatter_metadata_reader_service.dart';
import 'style_profile_normalizer_service.dart';

class StyleProfileMarkdownParserService {
  StyleProfileMarkdownParserService({
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
    StyleProfileNormalizerService? normalizerService,
  }) : _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService(),
       _normalizerService =
           normalizerService ?? const StyleProfileNormalizerService();

  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;
  final StyleProfileNormalizerService _normalizerService;

  JsonMap parseDocument(
    String content, {
    String fallbackId = '',
    String relativePath = '',
  }) {
    // 中文注释: 风格资产解析统一兼容 frontmatter + Markdown 正文，避免 GUI/CLI 各自手拆文本。
    final frontmatter = _frontmatterMetadataReaderService.readMetadata(content);
    final body = _frontmatterMetadataReaderService.removeMetadataBlock(content);
    final title = _extractHeading(body);
    final summary = _summaryFromBody(body, title);
    final normalized = _normalizerService.toDocument(
      _normalizerService.normalize(<String, Object?>{
        ...frontmatter,
        'id': ValueReaders.stringValue(frontmatter['id'], fallbackId).trim(),
        'display_name': ValueReaders.stringValue(
          frontmatter['display_name'],
          title,
        ).trim(),
        'summary': ValueReaders.stringValue(
          frontmatter['summary'],
          summary,
        ).trim(),
        'source_path': ValueReaders.stringValue(
          frontmatter['source_path'],
          relativePath,
        ).trim(),
      }),
    )..['relative_path'] = relativePath.trim();
    return normalized;
  }

  String _extractHeading(String body) {
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    return '';
  }

  String _summaryFromBody(String body, String heading) {
    final normalized = body.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final kept = <String>[];
    var skippedHeading = false;
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (!skippedHeading && trimmed.trim() == '# $heading'.trim()) {
        skippedHeading = true;
        continue;
      }
      kept.add(trimmed);
    }
    return kept.join('\n').trim();
  }
}
