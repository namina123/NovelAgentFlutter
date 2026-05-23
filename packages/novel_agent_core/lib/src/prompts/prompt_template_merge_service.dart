import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'prompt_template_catalog_service.dart';
import 'prompt_template_normalizer_service.dart';

class PromptTemplateMergeService {
  PromptTemplateMergeService({
    PromptTemplateCatalogService? catalogService,
    PromptTemplateNormalizerService? normalizerService,
  }) : _catalogService = catalogService ?? PromptTemplateCatalogService(),
       _normalizerService =
           normalizerService ?? PromptTemplateNormalizerService();

  final PromptTemplateCatalogService _catalogService;
  final PromptTemplateNormalizerService _normalizerService;

  List<JsonMap> listTemplates(
    List<Object?> projectTemplates, {
    bool includeDefaults = true,
  }) {
    // 中文注释: 项目模板同 id 时覆盖内置定义，核心只做内存态合并，不负责文件扫描。
    final byId = <String, JsonMap>{};
    if (includeDefaults) {
      for (final template in _catalogService.defaultTemplates()) {
        byId[ValueReaders.stringValue(template['id'])] =
            ValueReaders.deepCopyMap(template);
      }
    }
    for (final rawTemplate in projectTemplates) {
      final normalized = _normalizerService.normalizeTemplate(
        ValueReaders.mapValue(rawTemplate),
      );
      byId[ValueReaders.stringValue(normalized['id'])] = normalized;
    }
    final result = byId.values.toList(growable: false);
    result.sort(
      (left, right) => ValueReaders.stringValue(left['name'])
          .toLowerCase()
          .compareTo(ValueReaders.stringValue(right['name']).toLowerCase()),
    );
    return result;
  }
}
