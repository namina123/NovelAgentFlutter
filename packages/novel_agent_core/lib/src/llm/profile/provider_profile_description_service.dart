import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_profile_constants.dart';
import 'provider_protocol_service.dart';
import 'provider_runtime_profile_service.dart';

class ProviderProfileDescriptionService {
  ProviderProfileDescriptionService({
    required ProviderRuntimeProfileService runtimeProfileService,
    required ProviderProtocolService protocolService,
  }) : _runtimeProfileService = runtimeProfileService,
       _protocolService = protocolService;

  final ProviderRuntimeProfileService _runtimeProfileService;
  final ProviderProtocolService _protocolService;

  String describe(JsonMap profile) {
    // 中文注释: 运行配置摘要统一在描述服务生成，避免运行配置服务承担展示职责。
    final normalized = _runtimeProfileService.normalize(profile);
    final maxOutput = ValueReaders.intValue(
      normalized['max_output_tokens'],
      ProviderProfileConstants.defaultMaxOutputTokens,
    );
    final outputText = maxOutput <= 0 ? '不限' : '$maxOutput';
    var modelName = ValueReaders.stringValue(normalized['model']).trim();
    if (modelName.isEmpty) {
      modelName = '未选择模型';
    }
    return '${normalized['name']} - ${normalized['purpose']} / $modelName / ctx ${normalized['context_length']} / out $outputText';
  }

  String describeCredential(JsonMap credential) {
    // 中文注释: 接口摘要只输出列表展示所需信息，不额外触发能力解析副作用。
    final normalized = _runtimeProfileService.normalizeCredential(credential);
    return '${normalized['name']}｜接口｜${normalized['base_url']}';
  }

  String describeModel(JsonMap modelProfile, {String credentialName = ''}) {
    // 中文注释: 模型摘要在这一层统一格式化，保证 GUI 与 CLI 的文案一致。
    final normalized = _runtimeProfileService.normalizeModelProfile(
      modelProfile,
    );
    final provider = credentialName.trim().isNotEmpty
        ? credentialName
        : '未绑定接口';
    final maxOutput = ValueReaders.intValue(
      normalized['max_output_tokens'],
      ProviderProfileConstants.defaultMaxOutputTokens,
    );
    final outputText = maxOutput <= 0 ? '不限' : '$maxOutput';
    return '${normalized['name']}｜${normalized['purpose']}｜${_protocolService.protocolLabel(ValueReaders.stringValue(normalized['kind']))}｜${normalized['model']}｜out $outputText｜$provider';
  }
}
