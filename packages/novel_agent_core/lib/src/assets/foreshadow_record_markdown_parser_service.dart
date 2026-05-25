import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/frontmatter_metadata_reader_service.dart';
import 'foreshadow_record_normalizer_service.dart';

class ForeshadowRecordMarkdownParserService {
  ForeshadowRecordMarkdownParserService({
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
    ForeshadowRecordNormalizerService? normalizerService,
  }) : _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService(),
       _normalizerService =
           normalizerService ?? const ForeshadowRecordNormalizerService();

  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;
  final ForeshadowRecordNormalizerService _normalizerService;

  JsonMap parseDocument(
    String content, {
    String fallbackId = '',
    String relativePath = '',
  }) {
    // 中文注释: 伏笔资产解析统一把 frontmatter、摘要和备注拆开，后续时间线与提醒才能直接消费。
    final frontmatter = _frontmatterMetadataReaderService.readMetadata(content);
    final body = _frontmatterMetadataReaderService.removeMetadataBlock(content);
    final title = _extractHeading(body);
    final bodyParts = _splitBody(body, title);
    final normalized =
        _normalizerService.toDocument(
            _normalizerService.normalize(<String, Object?>{
              ...frontmatter,
              'id': ValueReaders.stringValue(
                frontmatter['id'],
                fallbackId,
              ).trim(),
              'title': ValueReaders.stringValue(
                frontmatter['title'],
                title,
              ).trim(),
              'summary': ValueReaders.stringValue(
                frontmatter['summary'],
                bodyParts.summary,
              ).trim(),
              'notes': ValueReaders.stringValue(
                frontmatter['notes'],
                bodyParts.notes,
              ).trim(),
              'source_path': ValueReaders.stringValue(
                frontmatter['source_path'],
                relativePath,
              ).trim(),
              'metadata': ValueReaders.deepCopyMap(
                ValueReaders.mapValue(frontmatter['metadata']),
              ),
            }),
          )
          ..['source_path'] = relativePath.trim()
          ..['relative_path'] = relativePath.trim();
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

  _ForeshadowBodyParts _splitBody(String body, String heading) {
    final normalized = body.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final summaryLines = <String>[];
    final notesLines = <String>[];
    var skippedHeading = false;
    var inNotes = false;
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (!skippedHeading && trimmed.trim() == '# $heading'.trim()) {
        skippedHeading = true;
        continue;
      }
      if (trimmed.trim() == '## 备注') {
        inNotes = true;
        continue;
      }
      if (inNotes) {
        notesLines.add(trimmed);
      } else {
        summaryLines.add(trimmed);
      }
    }
    return _ForeshadowBodyParts(
      summary: summaryLines.join('\n').trim(),
      notes: notesLines.join('\n').trim(),
    );
  }
}

class _ForeshadowBodyParts {
  const _ForeshadowBodyParts({required this.summary, required this.notes});

  final String summary;
  final String notes;
}
