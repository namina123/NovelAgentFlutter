import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../prompts/prompt_template_normalizer_service.dart';
import 'bundle_header_builder_service.dart';
import 'bundle_kind.dart';
import 'bundle_validation_result.dart';
import 'bundle_validation_service.dart';

class PromptTemplateBundleDocumentService {
  PromptTemplateBundleDocumentService({
    PromptTemplateNormalizerService? templateNormalizerService,
    BundleHeaderBuilderService? headerBuilderService,
    BundleValidationService? validationService,
  }) : _templateNormalizerService =
           templateNormalizerService ?? PromptTemplateNormalizerService(),
       _headerBuilderService =
           headerBuilderService ?? BundleHeaderBuilderService(),
       _validationService = validationService ?? BundleValidationService();

  final PromptTemplateNormalizerService _templateNormalizerService;
  final BundleHeaderBuilderService _headerBuilderService;
  final BundleValidationService _validationService;

  JsonMap buildBundle({
    required List<JsonMap> templates,
    String title = '',
    String description = '',
    String bundleVersion = '1.0.0',
    String createdAt = '',
  }) {
    // 中文注释: 模板包只承载模板本体和变量槽位，不掺入运行时拼装结果，便于后续做本地工坊和跨项目共享。
    return _headerBuilderService.attachHeader(
      bundleKind: BundleKind.promptTemplateBundle,
      title: title.trim().isEmpty ? 'NOVEL Agent 模板包' : title.trim(),
      description: description,
      bundleVersion: bundleVersion,
      createdAt: createdAt.trim().isEmpty
          ? DateTime.now().toIso8601String()
          : createdAt.trim(),
      payload: <String, Object?>{
        'templates': templates
            .map(_templateNormalizerService.normalizeTemplate)
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
      },
    );
  }

  String encodeBundle(JsonMap bundle) {
    return '${const JsonEncoder.withIndent('  ').convert(bundle)}\n';
  }

  JsonMap parseBundle(String content) {
    try {
      return ValueReaders.mapValue(jsonDecode(content));
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  BundleValidationResult validateBundle(String content) {
    final bundle = parseBundle(content);
    if (bundle.isEmpty) {
      return const BundleValidationResult(ok: false);
    }
    return _validationService.validateBundle(
      bundle,
      expectedKind: BundleKind.promptTemplateBundle,
    );
  }
}
