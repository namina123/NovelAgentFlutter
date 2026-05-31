import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_custom_parameter_service.dart';
import 'provider_profile_constants.dart';
import 'provider_protocol_service.dart';
import 'provider_thinking_parameter_service.dart';

class ProviderProfileNormalizerService {
  ProviderProfileNormalizerService({
    required ProviderProtocolService protocolService,
    required ProviderThinkingParameterService thinkingService,
    required ProviderCustomParameterService customParameterService,
  }) : _protocolService = protocolService,
       _thinkingService = thinkingService,
       _customParameterService = customParameterService;

  final ProviderProtocolService _protocolService;
  final ProviderThinkingParameterService _thinkingService;
  final ProviderCustomParameterService _customParameterService;

  JsonMap blankCredential() {
    // 中文注释: 空 credential 骨架由归一化服务统一提供，确保各入口看到相同字段集合。
    final now = _now();
    return <String, Object?>{
      'id': '',
      'name': '',
      'provider_id': '',
      'base_url': '',
      'api_key': '',
      'created_at': now,
      'updated_at': now,
    };
  }

  JsonMap normalizeCredential(JsonMap credential) {
    // 中文注释: credential 归一化只处理字段清洗与默认值，不耦合能力映射和展示逻辑。
    final result = blankCredential()
      ..addAll(ValueReaders.deepCopyMap(credential));
    var id = ValueReaders.stringValue(result['id']).trim();
    if (id.isEmpty) {
      id = newCredentialId();
    }
    result['id'] = id;

    var name = ValueReaders.stringValue(result['name']).trim();
    if (name.isEmpty) {
      name = '未命名接口';
    }
    result['name'] = name;
    result['provider_id'] = ValueReaders.stringValue(
      result['provider_id'],
    ).trim();

    var kind = ValueReaders.stringValue(
      result['kind'],
      ProviderProfileConstants.kindOpenAiCompatible,
    ).trim();
    if (!_protocolService.isSupportedProtocol(kind)) {
      kind = ProviderProfileConstants.kindOpenAiCompatible;
    }
    result['kind'] = kind;
    result['base_url'] = ValueReaders.stringValue(
      result['base_url'],
    ).trim().replaceAll(RegExp(r'/$'), '');
    result['api_key'] = ValueReaders.stringValue(result['api_key']);
    result['updated_at'] = _now();
    return result;
  }

  JsonMap blankModelProfile([String credentialId = '']) {
    // 中文注释: 模型骨架作为归一化输入基线，应该和运行态组装逻辑分离。
    final now = _now();
    return <String, Object?>{
      'id': '',
      'name': '',
      'purpose': '',
      'credential_id': credentialId,
      'kind': ProviderProfileConstants.kindOpenAiCompatible,
      'model': '',
      'context_length': ProviderProfileConstants.defaultContextLength,
      'compression_context_length':
          ProviderProfileConstants.defaultCompressionContextLength,
      'max_output_tokens': ProviderProfileConstants.defaultMaxOutputTokens,
      'thinking_parameter_format': ProviderProfileConstants.thinkingFormatNone,
      'temperature': ProviderProfileConstants.defaultTemperature,
      'top_p': ProviderProfileConstants.defaultTopP,
      'top_k': ProviderProfileConstants.defaultTopK,
      'custom_parameters': <Object?>[],
      'streaming_enabled': ProviderProfileConstants.defaultStreamingEnabled,
      'supports_streaming': true,
      'supports_tools': true,
      'supports_tool_choice':
          ProviderProfileConstants.defaultSupportsToolChoice,
      'supports_image_generation': false,
      'supports_file_attachments':
          ProviderProfileConstants.defaultSupportsFileAttachments,
      'supports_image_attachments':
          ProviderProfileConstants.defaultSupportsImageAttachments,
      'supports_attachment_urls_only':
          ProviderProfileConstants.defaultSupportsAttachmentUrlsOnly,
      'supports_multi_attachments':
          ProviderProfileConstants.defaultSupportsMultiAttachments,
      'created_at': now,
      'updated_at': now,
    };
  }

  JsonMap normalizeModelProfile(JsonMap profile) {
    // 中文注释: 模型配置归一化只关心结构收敛与边界校验，不参与 capability 规则合并。
    final result = blankModelProfile()
      ..addAll(ValueReaders.deepCopyMap(profile));
    var id = ValueReaders.stringValue(result['id']).trim();
    if (id.isEmpty) {
      id = newModelId();
    }
    result['id'] = id;

    var name = ValueReaders.stringValue(result['name']).trim();
    if (name.isEmpty) {
      name = '未命名模型';
    }
    result['name'] = name;

    var purpose = ValueReaders.stringValue(result['purpose']).trim();
    if (purpose.isEmpty) {
      purpose = '通用创作';
    }
    result['purpose'] = purpose;
    result['credential_id'] = ValueReaders.stringValue(
      result['credential_id'],
    ).trim();

    var kind = ValueReaders.stringValue(
      result['kind'],
      ProviderProfileConstants.kindOpenAiCompatible,
    ).trim();
    if (!_protocolService.isSupportedProtocol(kind)) {
      kind = ProviderProfileConstants.kindOpenAiCompatible;
    }
    result['kind'] = kind;
    result['model'] = ValueReaders.stringValue(result['model']).trim();
    final contextLength = _max(
      1,
      ValueReaders.intValue(
        result['context_length'],
        ProviderProfileConstants.defaultContextLength,
      ),
    );
    result['context_length'] = contextLength;
    result['compression_context_length'] = _clampInt(
      ValueReaders.intValue(
        result['compression_context_length'],
        ProviderProfileConstants.defaultCompressionContextLength,
      ),
      1,
      contextLength,
    );
    result['max_output_tokens'] = _max(
      0,
      ValueReaders.intValue(
        result['max_output_tokens'],
        ProviderProfileConstants.defaultMaxOutputTokens,
      ),
    );
    result['thinking_parameter_format'] = _thinkingService
        .normalizeThinkingParameterFormat(
          ValueReaders.stringValue(
            result['thinking_parameter_format'],
            ProviderProfileConstants.thinkingFormatNone,
          ),
        );
    result['temperature'] = _clampDouble(
      ValueReaders.doubleValue(
        result['temperature'],
        ProviderProfileConstants.defaultTemperature,
      ),
      0,
      2,
    );
    result['top_p'] = _clampDouble(
      ValueReaders.doubleValue(
        result['top_p'],
        ProviderProfileConstants.defaultTopP,
      ),
      0,
      1,
    );
    result['top_k'] = _max(
      0,
      ValueReaders.intValue(
        result['top_k'],
        ProviderProfileConstants.defaultTopK,
      ),
    );
    result['custom_parameters'] = _customParameterService
        .normalizeCustomParameters(result['custom_parameters']);
    result['streaming_enabled'] = ValueReaders.boolValue(
      result['streaming_enabled'],
      ProviderProfileConstants.defaultStreamingEnabled,
    );
    result['supports_streaming'] = ValueReaders.boolValue(
      result['supports_streaming'],
      true,
    );
    result['supports_tools'] = ValueReaders.boolValue(
      result['supports_tools'],
      true,
    );
    result['supports_tool_choice'] = ValueReaders.boolValue(
      result['supports_tool_choice'],
      ProviderProfileConstants.defaultSupportsToolChoice,
    );
    result['supports_image_generation'] = ValueReaders.boolValue(
      result['supports_image_generation'],
      false,
    );
    result['supports_file_attachments'] = ValueReaders.boolValue(
      result['supports_file_attachments'],
      ProviderProfileConstants.defaultSupportsFileAttachments,
    );
    result['supports_image_attachments'] = ValueReaders.boolValue(
      result['supports_image_attachments'],
      ProviderProfileConstants.defaultSupportsImageAttachments,
    );
    result['supports_attachment_urls_only'] = ValueReaders.boolValue(
      result['supports_attachment_urls_only'],
      ProviderProfileConstants.defaultSupportsAttachmentUrlsOnly,
    );
    result['supports_multi_attachments'] = ValueReaders.boolValue(
      result['supports_multi_attachments'],
      ProviderProfileConstants.defaultSupportsMultiAttachments,
    );
    result['updated_at'] = _now();
    return result;
  }

  String newCredentialId() {
    // 中文注释: credential ID 采用时间戳方案，先保证纯 Dart core 零宿主依赖即可工作。
    return 'credential_${DateTime.now().microsecondsSinceEpoch}';
  }

  String newModelId() {
    // 中文注释: 模型 ID 维持与 credential ID 相同策略，便于迁移旧项目数据格式。
    return 'model_${DateTime.now().microsecondsSinceEpoch}';
  }

  int _max(int left, int right) {
    // 中文注释: 数值辅助函数集中放在归一化层，避免主流程被低层细节打断。
    return left > right ? left : right;
  }

  int _clampInt(int value, int min, int max) {
    // 中文注释: 这里用纯 Dart 裁剪整数边界，替代旧宿主函数依赖。
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  double _clampDouble(double value, double min, double max) {
    // 中文注释: 浮点边界统一在归一化层校验，避免表单或适配器承担业务约束。
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  String _now() {
    // 中文注释: 时间统一输出 ISO 字符串，便于跨宿主读写和测试断言。
    return DateTime.now().toIso8601String();
  }
}
