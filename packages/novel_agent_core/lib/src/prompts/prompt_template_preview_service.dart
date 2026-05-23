import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'prompt_template_catalog_service.dart';
import 'prompt_template_merge_service.dart';
import 'prompt_template_normalizer_service.dart';
import 'prompt_template_renderer.dart';

class PromptTemplatePreviewService {
  PromptTemplatePreviewService({
    PromptTemplateCatalogService? catalogService,
    PromptTemplateMergeService? mergeService,
    PromptTemplateNormalizerService? normalizerService,
    PromptTemplateRenderer? renderer,
  }) : _catalogService = catalogService ?? PromptTemplateCatalogService(),
       _mergeService = mergeService ?? PromptTemplateMergeService(),
       _normalizerService =
           normalizerService ?? PromptTemplateNormalizerService(),
       _renderer = renderer ?? PromptTemplateRenderer();

  final PromptTemplateCatalogService _catalogService;
  final PromptTemplateMergeService _mergeService;
  final PromptTemplateNormalizerService _normalizerService;
  final PromptTemplateRenderer _renderer;

  JsonMap previewTemplate(JsonMap template, JsonMap variables) {
    // 中文注释: 预览不会落盘，只返回规范化模板和渲染结果，方便后续独立调试页直接复用。
    final normalized = _normalizerService.normalizeTemplate(template);
    final id = ValueReaders.stringValue(normalized['id']).trim();
    return <String, Object?>{
      'ok': id.isNotEmpty,
      'error': id.isNotEmpty ? '' : 'Template id is required.',
      'template': normalized,
      'content': _renderer.renderTemplate(normalized, variables),
    };
  }

  JsonMap previewById(
    String templateId,
    List<Object?> projectTemplates,
    JsonMap variables,
  ) {
    // 中文注释: 这里给运行层一个按 id 获取最终模板预览的入口，自动合并项目覆盖和内置模板。
    final allTemplates = _mergeService.listTemplates(projectTemplates);
    JsonMap template = <String, Object?>{};
    for (final item in allTemplates) {
      if (ValueReaders.stringValue(item['id']) == templateId.trim()) {
        template = item;
        break;
      }
    }
    if (template.isEmpty) {
      template = _catalogService.defaultTemplate(templateId);
    }
    if (template.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Template not found.',
        'content': '',
      };
    }
    return <String, Object?>{
      'ok': true,
      'template': template,
      'content': _renderer.renderTemplate(template, variables),
    };
  }
}
