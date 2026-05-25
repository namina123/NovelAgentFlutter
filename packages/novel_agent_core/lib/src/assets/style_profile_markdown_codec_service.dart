import '../packages/frontmatter_yaml_writer_service.dart';
import 'style_profile.dart';
import 'style_profile_normalizer_service.dart';

class StyleProfileMarkdownCodecService {
  StyleProfileMarkdownCodecService({
    StyleProfileNormalizerService? normalizerService,
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _normalizerService =
           normalizerService ?? const StyleProfileNormalizerService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  final StyleProfileNormalizerService _normalizerService;
  final FrontmatterYamlWriterService _yamlWriterService;

  String encode(StyleProfile style) {
    // 中文注释: 风格资产既要让人可读，也要保留可结构化导入导出的 frontmatter。
    final document = _normalizerService.toDocument(style);
    final frontmatter = <String, Object?>{
      'id': document['id'],
      'display_name': document['display_name'],
      'genre': document['genre'],
      'tone': document['tone'],
      'audience': document['audience'],
      'guardrails': document['guardrails'],
      'tags': document['tags'],
      'example_paths': document['example_paths'],
      'inherited_from_ids': document['inherited_from_ids'],
      'default_for_project': document['default_for_project'],
      'source_path': document['source_path'],
      'metadata': document['metadata'],
    };
    final body = style.summary.trim().isEmpty
        ? '请补充风格说明。'
        : style.summary.trim();
    return '---\n${_yamlWriterService.write(frontmatter)}\n---\n\n# ${style.displayName}\n\n$body\n';
  }
}
