import 'dart:convert';

import '../agents/agent_profile_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'frontmatter_metadata_reader_service.dart';
import 'markdown_package_metadata_reader_service.dart';

class AgentMarkdownPackageParserService {
  AgentMarkdownPackageParserService({
    AgentProfileNormalizerService? normalizerService,
    MarkdownPackageMetadataReaderService? metadataReaderService,
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
  }) : _normalizerService =
           normalizerService ?? AgentProfileNormalizerService(),
       _metadataReaderService =
           metadataReaderService ?? MarkdownPackageMetadataReaderService(),
       _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService();

  final AgentProfileNormalizerService _normalizerService;
  final MarkdownPackageMetadataReaderService _metadataReaderService;
  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;

  JsonMap parsePackage(String content, {String fallbackId = ''}) {
    // 中文注释: 智能体包优先走 YAML frontmatter + Markdown 正文；旧 JSON 与代码块结构继续兼容迁移。
    final trimmed = content.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = ValueReaders.mapValue(jsonDecode(trimmed));
        return _normalizerService.normalizeAgentProfile(decoded);
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
            acceptedFenceLabels: const <String>['agent', 'json'],
          );
    final body = hasFrontmatter
        ? _frontmatterMetadataReaderService.removeMetadataBlock(content)
        : _metadataReaderService.removeMetadataBlock(
            content,
            acceptedFenceLabels: const <String>['agent', 'json'],
          );
    final heading = _metadataReaderService.readFirstHeading(body);
    final package = <String, Object?>{
      ...metadata,
      if (ValueReaders.stringValue(metadata['id']).trim().isEmpty &&
          fallbackId.trim().isNotEmpty)
        'id': fallbackId.trim(),
      if (ValueReaders.stringValue(metadata['name']).trim().isEmpty &&
          heading.isNotEmpty)
        'name': heading,
      if (body.trim().isNotEmpty) 'system_prompt': body.trim(),
      if (body.trim().isNotEmpty) 'operating_manual_markdown': body.trim(),
    };
    return _normalizerService.normalizeAgentProfile(package);
  }

  JsonMap _fallbackPackage(String content, {required String fallbackId}) {
    // 中文注释: 极简 Markdown 包至少能生成一个可用智能体，避免格式小问题直接让加载失败。
    final heading = _metadataReaderService.readFirstHeading(content);
    return _normalizerService.normalizeAgentProfile(<String, Object?>{
      'id': fallbackId.trim().isEmpty ? 'agent_package' : fallbackId.trim(),
      'name': heading.isEmpty ? '未命名智能体' : heading,
      'system_prompt': content.trim(),
      'operating_manual_markdown': content.trim(),
    });
  }
}
