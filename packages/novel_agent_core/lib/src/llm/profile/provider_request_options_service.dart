import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_custom_parameter_service.dart';
import 'provider_model_metadata_service.dart';
import 'provider_thinking_parameter_service.dart';

class ProviderRequestOptionsService {
  ProviderRequestOptionsService({
    ProviderModelMetadataService? metadataService,
    ProviderThinkingParameterService? thinkingService,
    ProviderCustomParameterService? customParameterService,
  }) : _metadataService = metadataService ?? ProviderModelMetadataService(),
       _thinkingService = thinkingService ?? ProviderThinkingParameterService(),
       _customParameterService =
           customParameterService ?? ProviderCustomParameterService();

  final ProviderModelMetadataService _metadataService;
  final ProviderThinkingParameterService _thinkingService;
  final ProviderCustomParameterService _customParameterService;

  JsonMap buildRequestOptions(
    JsonMap runtimeProfile, {
    String apiMode = 'chat',
    JsonMap baseOptions = const <String, Object?>{},
  }) {
    // 中文注释: 这个服务只负责把运行态模型配置翻译成网关请求参数，不处理设置来源。
    final metadata = _metadataService.buildEditorMetadata(runtimeProfile);
    final result = ValueReaders.deepCopyMap(baseOptions);
    result['api_mode'] = apiMode.trim().isEmpty ? 'chat' : apiMode.trim();
    result['stream'] = ValueReaders.boolValue(
      runtimeProfile['streaming_enabled'],
      true,
    );
    if (ValueReaders.boolValue(metadata['supports_temperature'], true)) {
      result['temperature'] = ValueReaders.doubleValue(
        runtimeProfile['temperature'],
      );
    }
    if (ValueReaders.boolValue(metadata['supports_top_p'], true)) {
      result['top_p'] = ValueReaders.doubleValue(runtimeProfile['top_p']);
    }
    if (ValueReaders.boolValue(metadata['supports_top_k'])) {
      result['top_k'] = ValueReaders.intValue(runtimeProfile['top_k']);
    }
    result.addAll(
      _thinkingService.thinkingRequestParameters(
        ValueReaders.boolValue(runtimeProfile['thinking_enabled']),
        ValueReaders.stringValue(runtimeProfile['thinking_effort'], 'high'),
        ValueReaders.stringValue(runtimeProfile['thinking_parameter_format']),
      ),
    );
    for (final rawEntry in _customParameterService.normalizeCustomParameters(
      runtimeProfile['custom_parameters'],
    )) {
      final entry = ValueReaders.mapValue(rawEntry);
      final key = ValueReaders.stringValue(entry['key']).trim();
      if (key.isEmpty) {
        continue;
      }
      final value = entry['value'];
      if (_shouldSkipValue(value)) {
        continue;
      }
      result[key] = value;
    }
    return result;
  }

  bool _shouldSkipValue(Object? value) {
    // 中文注释: 空字符串参数不应被透传，避免“未填写”被误判为显式覆盖。
    if (value == null) {
      return true;
    }
    if (value is String) {
      return value.trim().isEmpty;
    }
    return false;
  }
}
