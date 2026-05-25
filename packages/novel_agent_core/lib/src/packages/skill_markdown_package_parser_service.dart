import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'frontmatter_metadata_reader_service.dart';
import 'markdown_package_metadata_reader_service.dart';
import 'skill_package_metadata_profile_service.dart';

class SkillMarkdownPackageParserService {
  SkillMarkdownPackageParserService({
    MarkdownPackageMetadataReaderService? metadataReaderService,
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
    SkillPackageMetadataProfileService? metadataProfileService,
  }) : _metadataReaderService =
           metadataReaderService ?? MarkdownPackageMetadataReaderService(),
       _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService(),
       _metadataProfileService =
           metadataProfileService ?? const SkillPackageMetadataProfileService();

  final MarkdownPackageMetadataReaderService _metadataReaderService;
  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;
  final SkillPackageMetadataProfileService _metadataProfileService;

  JsonMap parsePackage(String content, {String fallbackId = ''}) {
    // 中文注释: 技能包解析和智能体保持同一原则：既支持 JSON，也支持带元数据代码块的 SKILL.md。
    final trimmed = content.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = ValueReaders.mapValue(jsonDecode(trimmed));
        return _normalizeSkill(decoded, fallbackId: fallbackId);
      } catch (_) {
        return _fallbackPackage(trimmed, fallbackId: fallbackId);
      }
    }
    final frontmatter = _frontmatterMetadataReaderService.readMetadata(content);
    final hasFrontmatter = frontmatter.isNotEmpty;
    final metadata = hasFrontmatter
        ? frontmatter
        : _metadataReaderService.readMetadata(
            content,
            acceptedFenceLabels: const <String>['skill', 'json'],
          );
    final body = hasFrontmatter
        ? _frontmatterMetadataReaderService.removeMetadataBlock(content)
        : _metadataReaderService.removeMetadataBlock(
            content,
            acceptedFenceLabels: const <String>['skill', 'json'],
          );
    final heading = _metadataReaderService.readFirstHeading(body);
    return _normalizeSkill(<String, Object?>{
      ...metadata,
      if (ValueReaders.stringValue(metadata['id']).trim().isEmpty &&
          fallbackId.trim().isNotEmpty)
        'id': fallbackId.trim(),
      if (ValueReaders.stringValue(metadata['name']).trim().isEmpty &&
          heading.isNotEmpty)
        'name': heading,
      if (body.trim().isNotEmpty) 'instruction_markdown': body.trim(),
    }, fallbackId: fallbackId);
  }

  JsonMap _normalizeSkill(JsonMap rawSkill, {required String fallbackId}) {
    // 中文注释: 技能卡需要表达触发条件、资源提示和能力依赖，避免技能内容默认绑死某个具体工具。
    final resolvedId = ValueReaders.stringValue(
      rawSkill['id'] ?? rawSkill['name'],
      fallbackId.trim().isEmpty ? 'skill_package' : fallbackId.trim(),
    ).trim();
    final normalizedId = _normalizeId(
      resolvedId.isEmpty ? 'skill_package' : resolvedId,
    );
    final resourceHints = _normalizeResourceHints(rawSkill['resource_hints']);
    final extensions = _metadataProfileService.extractExtensions(rawSkill);
    final metadata = _metadataProfileService.extractPlainMetadata(rawSkill);
    return <String, Object?>{
      'id': normalizedId,
      'name': ValueReaders.stringValue(rawSkill['name'], normalizedId),
      'description': ValueReaders.stringValue(rawSkill['description']),
      'version': ValueReaders.stringValue(rawSkill['version'], '1'),
      'instruction_markdown': ValueReaders.stringValue(
        rawSkill['instruction_markdown'],
        ValueReaders.stringValue(rawSkill['content']),
      ),
      'tags': ValueReaders.stringList(rawSkill['tags']),
      'activation_hints': ValueReaders.stringList(
        extensions['activation_hints'],
      ),
      'inputs': ValueReaders.stringList(extensions['inputs']),
      'outputs': ValueReaders.stringList(extensions['outputs']),
      'required_capabilities': ValueReaders.stringList(
        extensions['required_capabilities'],
      ),
      'optional_capabilities': ValueReaders.stringList(
        extensions['optional_capabilities'],
      ),
      'safe_without_tools': ValueReaders.boolValue(
        extensions['safe_without_tools'],
        true,
      ),
      'resource_hints': resourceHints,
      'preferred_output': ValueReaders.stringValue(
        extensions['preferred_output'],
      ),
      'source': ValueReaders.stringValue(extensions['source'], 'package'),
      'source_scope': ValueReaders.stringValue(extensions['source_scope']),
      'tool_schema': ValueReaders.mapValue(extensions['tool_schema']),
      'metadata': metadata,
      'portable_core': _metadataProfileService.buildPortableCore(
        rawSkill,
        normalizedId: normalizedId,
        normalizedName: ValueReaders.stringValue(
          rawSkill['name'],
          normalizedId,
        ),
        resourceHints: resourceHints,
      ),
      'novel_agent_extensions': extensions,
    };
  }

  JsonMap _fallbackPackage(String content, {required String fallbackId}) {
    // 中文注释: 没有结构化元数据时，至少保留技能正文，让包不会因为格式不完美而失效。
    final heading = _metadataReaderService.readFirstHeading(content);
    return _normalizeSkill(<String, Object?>{
      'id': fallbackId.trim().isEmpty ? 'skill_package' : fallbackId.trim(),
      'name': heading.isEmpty ? '未命名技能' : heading,
      'instruction_markdown': content.trim(),
    }, fallbackId: fallbackId);
  }

  JsonMap _normalizeResourceHints(Object? rawValue) {
    // 中文注释: 资源提示只描述技能包内部可选资源，不把具体宿主工具实现硬编码进技能元数据。
    final rawMap = ValueReaders.mapValue(rawValue);
    return <String, Object?>{
      'scripts': ValueReaders.stringList(rawMap['scripts']),
      'references': ValueReaders.stringList(rawMap['references']),
      'assets': ValueReaders.stringList(rawMap['assets']),
    };
  }

  String _normalizeId(String value) {
    // 中文注释: 技能 ID 统一收敛为 kebab-case 风格，便于跨平台目录与引用稳定一致。
    var result = value.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'\s+'), '-');
    result = result.replaceAll(RegExp(r'[^a-z0-9_-]'), '-');
    result = result.replaceAll(RegExp(r'-+'), '-');
    result = result.replaceAll(RegExp(r'^-+|-+$'), '');
    return result.isEmpty ? 'skill-package' : result;
  }
}
