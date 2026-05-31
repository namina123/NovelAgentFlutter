import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/frontmatter_metadata_reader_service.dart';
import 'organization_profile_normalizer_service.dart';

class OrganizationProfileMarkdownParserService {
  OrganizationProfileMarkdownParserService({
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
    OrganizationProfileNormalizerService? normalizerService,
  }) : _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService(),
       _normalizerService =
           normalizerService ?? const OrganizationProfileNormalizerService();

  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;
  final OrganizationProfileNormalizerService _normalizerService;

  JsonMap parseDocument(
    String content, {
    String fallbackId = '',
    String relativePath = '',
  }) {
    // 中文注释: 组织卡解析与角色卡一致，统一先拆 frontmatter，再从正文抽简介和成员列表。
    final frontmatter = _frontmatterMetadataReaderService.readMetadata(content);
    final body = _frontmatterMetadataReaderService.removeMetadataBlock(content);
    final heading = _extractHeading(body);
    final parts = _splitBody(body, heading);
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
              'member_character_ids':
                  ValueReaders.stringList(frontmatter['member_character_ids'])
                          .isNotEmpty
                  ? frontmatter['member_character_ids']
                  : parts.members,
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

  _OrganizationProfileBodyParts _splitBody(String body, String heading) {
    final normalized = body.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final summaryLines = <String>[];
    final memberLines = <String>[];
    var skippedHeading = false;
    var inMembers = false;
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (!skippedHeading && line.trim() == '# $heading'.trim()) {
        skippedHeading = true;
        continue;
      }
      if (line.trim() == '## 成员') {
        inMembers = true;
        continue;
      }
      if (inMembers) {
        final trimmed = line.trim();
        if (trimmed.startsWith('- ')) {
          memberLines.add(trimmed.substring(2).trim());
        }
      } else {
        summaryLines.add(line);
      }
    }
    return _OrganizationProfileBodyParts(
      summary: summaryLines.join('\n').trim(),
      members: memberLines
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class _OrganizationProfileBodyParts {
  const _OrganizationProfileBodyParts({
    required this.summary,
    required this.members,
  });

  final String summary;
  final List<String> members;
}
