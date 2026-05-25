import 'dart:convert';

import '../assets/style_profile.dart';
import '../assets/style_profile_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'bundle_header_builder_service.dart';
import 'bundle_kind.dart';
import 'bundle_validation_result.dart';
import 'bundle_validation_service.dart';

class StyleBundleDocumentService {
  StyleBundleDocumentService({
    StyleProfileNormalizerService? styleNormalizerService,
    BundleHeaderBuilderService? headerBuilderService,
    BundleValidationService? validationService,
  }) : _styleNormalizerService =
           styleNormalizerService ?? const StyleProfileNormalizerService(),
       _headerBuilderService =
           headerBuilderService ?? BundleHeaderBuilderService(),
       _validationService = validationService ?? BundleValidationService();

  final StyleProfileNormalizerService _styleNormalizerService;
  final BundleHeaderBuilderService _headerBuilderService;
  final BundleValidationService _validationService;

  JsonMap buildBundle({
    required List<StyleProfile> styles,
    String title = '',
    String description = '',
    String bundleVersion = '1.0.0',
    String createdAt = '',
  }) {
    // 中文注释: 风格包只关心风格资产本体，项目级绑定与默认采用关系留给别的合同表达。
    return _headerBuilderService.attachHeader(
      bundleKind: BundleKind.styleBundle,
      title: title.trim().isEmpty ? 'NOVEL Agent 风格包' : title.trim(),
      description: description,
      bundleVersion: bundleVersion,
      createdAt: createdAt.trim().isEmpty
          ? DateTime.now().toIso8601String()
          : createdAt.trim(),
      payload: <String, Object?>{
        'styles': styles
            .map(_styleNormalizerService.toDocument)
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
      expectedKind: BundleKind.styleBundle,
    );
  }
}
