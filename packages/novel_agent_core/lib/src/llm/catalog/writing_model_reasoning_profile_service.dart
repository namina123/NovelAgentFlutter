import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'builtin_writing_model_catalog_service.dart';
import 'builtin_writing_model_descriptor.dart';
import 'writing_model_provider_offering_override.dart';

class WritingModelReasoningProfileService {
  WritingModelReasoningProfileService({
    BuiltinWritingModelCatalogService? catalogService,
  }) : _catalogService =
           catalogService ?? BuiltinWritingModelCatalogService.seeded();

  final BuiltinWritingModelCatalogService _catalogService;

  JsonMap resolve({
    required String providerId,
    required String modelId,
    required String baseUrl,
  }) {
    // 中文注释: 这里把 canonical 模型事实和 offering override 合并成统一 reasoning 投影，供 runtime 和 metadata 共用。
    final matched = _matchModel(providerId: providerId, modelId: modelId);
    if (matched == null) {
      return <String, Object?>{};
    }
    final offering = _matchOffering(
      matched,
      providerId: providerId,
      modelId: modelId,
      baseUrl: baseUrl,
    );
    final baseReasoning = matched.reasoning;
    final override = offering?.reasoningOverride ?? const <String, Object?>{};
    return <String, Object?>{
      'matched_canonical_model_id': matched.canonicalModelId,
      'matched_model_display_name': matched.displayName,
      'matched_vendor_id': matched.vendorId,
      'matched_vendor_label': matched.vendorLabel,
      'supports_reasoning': baseReasoning.supported,
      'reasoning_mode_behavior': _stringValue(
        override['mode_behavior'],
        baseReasoning.modeBehavior,
      ),
      'reasoning_can_toggle': _boolValue(
        override['can_toggle'],
        fallback: baseReasoning.canToggle,
      ),
      'reasoning_default_enabled': _boolValue(
        override['default_enabled'],
        fallback: baseReasoning.defaultEnabled,
      ),
      'reasoning_supports_effort': _boolValue(
        override['supports_effort'],
        fallback: baseReasoning.supportsEffort,
      ),
      'reasoning_effort_options': _stringList(
        override['effort_options'],
        fallback: baseReasoning.effortOptions,
      ),
      'reasoning_default_effort': _stringValue(
        override['default_effort'],
        baseReasoning.defaultEffort,
      ),
      'reasoning_toggle_parameter_strategy': _mapValue(
        override['toggle_parameter_strategy'],
        fallback: baseReasoning.toggleParameterStrategy,
      ),
      'reasoning_effort_parameter_strategy': _mapValue(
        override['effort_parameter_strategy'],
        fallback: baseReasoning.effortParameterStrategy,
      ),
      'matched_provider_offering_id': offering?.providerModelId ?? '',
      'matched_provider_offering_label': offering?.providerLabel ?? '',
    };
  }

  BuiltinWritingModelDescriptor? _matchModel({
    required String providerId,
    required String modelId,
  }) {
    // 中文注释: offering 精确命中优先，其次才退回别名命中，避免聚合平台模型被误识别到错误 canonical 条目。
    final byOffering = _catalogService.matchByProviderModelId(
      providerId: providerId,
      modelId: modelId,
    );
    if (byOffering != null) {
      return byOffering;
    }
    return _catalogService.matchByAlias(modelId);
  }

  WritingModelProviderOfferingOverride? _matchOffering(
    BuiltinWritingModelDescriptor model, {
    required String providerId,
    required String modelId,
    required String baseUrl,
  }) {
    // 中文注释: offering override 命中只按 provider+model/baseUrl 做保守判断，后续热更新再扩成更强规则引擎。
    final cleanProviderId = providerId.trim();
    final cleanModelId = modelId.trim().toLowerCase();
    final cleanBaseUrl = baseUrl.trim().toLowerCase();
    for (final offering in model.providerOfferings) {
      if (offering.providerId != cleanProviderId) {
        continue;
      }
      final matchesModel =
          offering.providerModelId.trim().toLowerCase() == cleanModelId;
      final matchesBaseUrl =
          offering.baseUrlHint.trim().isEmpty ||
          cleanBaseUrl.contains(offering.baseUrlHint.trim().toLowerCase());
      if (matchesModel && matchesBaseUrl) {
        return offering;
      }
    }
    return null;
  }

  bool _boolValue(Object? value, {required bool fallback}) {
    return value == null ? fallback : ValueReaders.boolValue(value, fallback);
  }

  String _stringValue(Object? value, String fallback) {
    final text = ValueReaders.stringValue(value);
    return text.trim().isEmpty ? fallback : text;
  }

  List<String> _stringList(Object? value, {required List<String> fallback}) {
    final list = ValueReaders.stringList(value);
    return list.isEmpty ? fallback : list;
  }

  JsonMap _mapValue(Object? value, {required JsonMap fallback}) {
    final result = ValueReaders.mapValue(value);
    return result.isEmpty ? ValueReaders.deepCopyMap(fallback) : result;
  }
}
