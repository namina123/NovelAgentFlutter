import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/frontmatter_metadata_reader_service.dart';
import 'character_profile_normalizer_service.dart';

class CharacterProfileMarkdownParserService {
  CharacterProfileMarkdownParserService({
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
    CharacterProfileNormalizerService? normalizerService,
  }) : _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService(),
       _normalizerService =
           normalizerService ?? const CharacterProfileNormalizerService();

  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;
  final CharacterProfileNormalizerService _normalizerService;

  JsonMap parseDocument(
    String content, {
    String fallbackId = '',
    String relativePath = '',
  }) {
    // 中文注释: 主档解析把 frontmatter 和正文状态区拆开，避免运行态字段只能靠正文硬解析。
    final frontmatter = _frontmatterMetadataReaderService.readMetadata(content);
    final body = _frontmatterMetadataReaderService.removeMetadataBlock(content);
    final heading = _extractHeading(body);
    final parts = _splitBody(body, heading);
    final currentSection = parts.sections['当前状态'] ?? '';
    final normalized =
        _normalizerService.toDocument(
            _normalizerService.normalize(<String, Object?>{
              ...frontmatter,
              'id': ValueReaders.stringValue(
                frontmatter['id'],
                fallbackId,
              ).trim(),
              'display_name': ValueReaders.stringValue(
                frontmatter['display_name'] ?? frontmatter['name'],
                heading,
              ).trim(),
              'summary': ValueReaders.stringValue(
                frontmatter['summary'],
                parts.summary,
              ).trim(),
              'current_status': ValueReaders.stringValue(
                frontmatter['current_status'] ?? frontmatter['status'],
                _readBullet(currentSection, '状态'),
              ).trim(),
              'current_state_summary': ValueReaders.stringValue(
                frontmatter['current_state_summary'] ??
                    frontmatter['state_summary'],
                _removeKnownBullets(currentSection),
              ).trim(),
              'latest_stage_label': ValueReaders.stringValue(
                frontmatter['latest_stage_label'] ?? frontmatter['stage_label'],
                _readBullet(currentSection, '最近阶段'),
              ).trim(),
              'latest_updated_at': ValueReaders.stringValue(
                frontmatter['latest_updated_at'] ?? frontmatter['updated_at'],
                _readBullet(currentSection, '最近更新'),
              ).trim(),
              'latest_source_paths':
                  ValueReaders.stringList(
                    frontmatter['latest_source_paths'] ??
                        frontmatter['source_paths'],
                  ).isNotEmpty
                  ? frontmatter['latest_source_paths'] ??
                        frontmatter['source_paths']
                  : _splitSources(_readBullet(currentSection, '参考路径')),
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

  _CharacterProfileBodyParts _splitBody(String body, String heading) {
    final normalized = body.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final summaryLines = <String>[];
    final sections = <String, List<String>>{};
    String currentSection = '';
    var skippedHeading = false;
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (!skippedHeading && line.trim() == '# $heading'.trim()) {
        skippedHeading = true;
        continue;
      }
      if (line.startsWith('## ')) {
        currentSection = line.substring(3).trim();
        sections[currentSection] = <String>[];
        continue;
      }
      if (currentSection.isEmpty) {
        summaryLines.add(line);
      } else {
        sections[currentSection]!.add(line);
      }
    }
    return _CharacterProfileBodyParts(
      summary: summaryLines.join('\n').trim(),
      sections: <String, String>{
        for (final entry in sections.entries)
          entry.key: entry.value.join('\n').trim(),
      },
    );
  }

  String _readBullet(String block, String label) {
    for (final line in block.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- $label：')) {
        return trimmed.substring(label.length + 4).trim();
      }
    }
    return '';
  }

  String _removeKnownBullets(String block) {
    final lines = <String>[];
    for (final line in block.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- 状态：') ||
          trimmed.startsWith('- 最近阶段：') ||
          trimmed.startsWith('- 最近更新：') ||
          trimmed.startsWith('- 参考路径：')) {
        continue;
      }
      lines.add(line);
    }
    return lines.join('\n').trim();
  }

  List<String> _splitSources(String value) {
    if (value.trim().isEmpty) {
      return const <String>[];
    }
    return value
        .split(RegExp(r'[、,，]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class _CharacterProfileBodyParts {
  const _CharacterProfileBodyParts({
    required this.summary,
    required this.sections,
  });

  final String summary;
  final Map<String, String> sections;
}
