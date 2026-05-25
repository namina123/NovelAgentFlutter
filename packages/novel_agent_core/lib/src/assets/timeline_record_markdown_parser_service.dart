import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/frontmatter_metadata_reader_service.dart';
import 'timeline_record_normalizer_service.dart';

class TimelineRecordMarkdownParserService {
  TimelineRecordMarkdownParserService({
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
    TimelineRecordNormalizerService? normalizerService,
  }) : _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService(),
       _normalizerService =
           normalizerService ?? const TimelineRecordNormalizerService();

  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;
  final TimelineRecordNormalizerService _normalizerService;

  JsonMap parseDocument(
    String content, {
    String fallbackId = '',
    String relativePath = '',
  }) {
    // 中文注释: 时间线 Markdown 统一解析成“摘要 + 备注”，后续事件检查、上下文注入和图谱都只看结构化对象。
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
              'display_name': ValueReaders.stringValue(
                frontmatter['display_name'],
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

  _TimelineBodyParts _splitBody(String body, String heading) {
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
    return _TimelineBodyParts(
      summary: summaryLines.join('\n').trim(),
      notes: notesLines.join('\n').trim(),
    );
  }
}

class _TimelineBodyParts {
  const _TimelineBodyParts({required this.summary, required this.notes});

  final String summary;
  final String notes;
}
