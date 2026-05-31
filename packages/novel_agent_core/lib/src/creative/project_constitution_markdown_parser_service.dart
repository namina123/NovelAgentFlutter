import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/frontmatter_metadata_reader_service.dart';
import 'project_constitution_normalizer_service.dart';

class ProjectConstitutionMarkdownParserService {
  ProjectConstitutionMarkdownParserService({
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
    ProjectConstitutionNormalizerService? normalizerService,
  }) : _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService(),
       _normalizerService =
           normalizerService ?? const ProjectConstitutionNormalizerService();

  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;
  final ProjectConstitutionNormalizerService _normalizerService;

  JsonMap parseDocument(
    String content, {
    String fallbackId = 'project_constitution',
    String relativePath = '',
  }) {
    // 中文注释: 创作宪法解析兼容 frontmatter 与纯 Markdown 标题/列表，方便旧规范文档平滑进入共享合同。
    final frontmatter = _frontmatterMetadataReaderService.readMetadata(content);
    final body = _frontmatterMetadataReaderService.removeMetadataBlock(content);
    final heading = _extractHeading(body);
    final sections = _extractSections(body);
    return _normalizerService.toDocument(
      _normalizerService.normalize(<String, Object?>{
        ...frontmatter,
        'id': ValueReaders.stringValue(frontmatter['id'], fallbackId).trim(),
        'title': ValueReaders.stringValue(frontmatter['title'], heading).trim(),
        'summary': ValueReaders.stringValue(
          frontmatter['summary'],
          _summaryFromBody(body, heading),
        ).trim(),
        'principles': _preferList(
          frontmatter['principles'],
          sections['principles'] ?? const <String>[],
        ),
        'prohibitions': _preferList(
          frontmatter['prohibitions'],
          sections['prohibitions'] ?? const <String>[],
        ),
        'natural_expression_rules': _preferList(
          frontmatter['natural_expression_rules'],
          sections['natural_expression_rules'] ?? const <String>[],
        ),
        'source_path': ValueReaders.stringValue(
          frontmatter['source_path'],
          relativePath,
        ).trim(),
      }),
    )..['relative_path'] = relativePath.trim();
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

  Map<String, List<String>> _extractSections(String body) {
    final principles = <String>[];
    final prohibitions = <String>[];
    final naturalRules = <String>[];
    List<String>? active;
    for (final rawLine in body.replaceAll('\r', '').split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith('#')) {
        final normalized = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        active = _targetListForHeading(
          normalized,
          principles: principles,
          prohibitions: prohibitions,
          naturalRules: naturalRules,
        );
        continue;
      }
      if ((line.startsWith('- ') || line.startsWith('* ')) && active != null) {
        final item = line.substring(2).trim();
        if (item.isNotEmpty) {
          active.add(item);
        }
      }
    }
    return <String, List<String>>{
      'principles': principles,
      'prohibitions': prohibitions,
      'natural_expression_rules': naturalRules,
    };
  }

  List<String>? _targetListForHeading(
    String heading, {
    required List<String> principles,
    required List<String> prohibitions,
    required List<String> naturalRules,
  }) {
    final lower = heading.toLowerCase();
    if (heading.contains('原则') || heading.contains('底线') || heading.contains('契约')) {
      return principles;
    }
    if (heading.contains('禁止') || heading.contains('边界') || heading.contains('绝不')) {
      return prohibitions;
    }
    if (heading.contains('自然') ||
        heading.contains('去AI') ||
        heading.contains('去 ai') ||
        lower.contains('natural')) {
      return naturalRules;
    }
    return null;
  }

  List<String> _preferList(Object? primary, List<String> fallback) {
    final values = ValueReaders.stringList(primary);
    return values.isNotEmpty ? values : fallback;
  }

  String _summaryFromBody(String body, String heading) {
    final lines = body.replaceAll('\r', '').split('\n');
    final kept = <String>[];
    var skippedHeading = false;
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (!skippedHeading && line.trim() == '# $heading'.trim()) {
        skippedHeading = true;
        continue;
      }
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        if (kept.isNotEmpty) {
          break;
        }
        continue;
      }
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        continue;
      }
      kept.add(trimmed);
    }
    return kept.join('\n').trim();
  }
}
