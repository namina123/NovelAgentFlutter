import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'frontmatter_yaml_writer_service.dart';
import 'skill_markdown_package_parser_service.dart';
import 'skill_package_metadata_profile_service.dart';

class SkillMarkdownPackageRendererService {
  SkillMarkdownPackageRendererService({
    SkillMarkdownPackageParserService? parserService,
    FrontmatterYamlWriterService? yamlWriterService,
    SkillPackageMetadataProfileService? metadataProfileService,
  }) : _parserService = parserService ?? SkillMarkdownPackageParserService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService(),
       _metadataProfileService =
           metadataProfileService ?? const SkillPackageMetadataProfileService();

  final SkillMarkdownPackageParserService _parserService;
  final FrontmatterYamlWriterService _yamlWriterService;
  final SkillPackageMetadataProfileService _metadataProfileService;

  String renderPackage(JsonMap skill) {
    // 中文注释: 技能包渲染输出标准 SKILL.md，避免项目级技能继续漂回散乱 JSON 文件布局。
    final normalized = _parserService.parsePackage(
      _toJsonText(skill),
      fallbackId: ValueReaders.stringValue(skill['id']),
    );
    final body = ValueReaders.stringValue(
      normalized['instruction_markdown'],
    ).trim();
    final frontmatter = <String, Object?>{
      'id': normalized['id'],
      'name': normalized['name'],
      'description': normalized['description'],
      'version': normalized['version'],
      'tags': normalized['tags'],
      'resource_hints': normalized['resource_hints'],
      'metadata': _metadataProfileService.buildRendererMetadata(normalized),
    };
    final markdownBody = body.isEmpty
        ? '# ${ValueReaders.stringValue(normalized["name"], ValueReaders.stringValue(normalized["id"]))}\n\n请补充这个技能的说明。\n'
        : body;
    return '---\n${_yamlWriterService.write(frontmatter)}\n---\n\n$markdownBody\n';
  }

  String _toJsonText(JsonMap value) {
    // 中文注释: 解析器期待的是合法 JSON 文本，这里统一编码，避免结构化字段在渲染前丢失。
    return jsonEncode(value);
  }
}
