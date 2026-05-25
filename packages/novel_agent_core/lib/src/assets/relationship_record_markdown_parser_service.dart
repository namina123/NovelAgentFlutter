import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/frontmatter_metadata_reader_service.dart';
import 'relationship_record_normalizer_service.dart';

class RelationshipRecordMarkdownParserService {
  RelationshipRecordMarkdownParserService({
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
    RelationshipRecordNormalizerService? normalizerService,
  }) : _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService(),
       _normalizerService =
           normalizerService ?? const RelationshipRecordNormalizerService();

  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;
  final RelationshipRecordNormalizerService _normalizerService;

  JsonMap parseDocument(
    String content, {
    String fallbackId = '',
    String relativePath = '',
  }) {
    // 中文注释: 关系资产解析结果只保留共享合同，不把图谱布局、坐标这类纯界面信息混入核心层。
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

  _RelationshipBodyParts _splitBody(String body, String heading) {
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
    return _RelationshipBodyParts(
      summary: summaryLines.join('\n').trim(),
      notes: notesLines.join('\n').trim(),
    );
  }
}

class _RelationshipBodyParts {
  const _RelationshipBodyParts({required this.summary, required this.notes});

  final String summary;
  final String notes;
}
