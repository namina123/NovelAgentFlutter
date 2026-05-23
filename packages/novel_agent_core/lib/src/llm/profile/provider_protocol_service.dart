import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_profile_constants.dart';

class ProviderProtocolService {
  List<JsonMap> protocolOptions() {
    // 中文注释: 协议枚举集中在这一层，避免 GUI、CLI、适配器分别维护副本。
    return const <JsonMap>[
      <String, Object?>{
        'id': ProviderProfileConstants.kindOpenAiCompatible,
        'label': 'OpenAI 协议格式',
      },
      <String, Object?>{
        'id': ProviderProfileConstants.kindAnthropicCompatible,
        'label': 'Anthropic 协议格式',
      },
    ];
  }

  bool isSupportedProtocol(String kind) {
    // 中文注释: 协议支持性判断属于纯规则，不需要让运行配置层重复关心细节。
    for (final option in protocolOptions()) {
      if (ValueReaders.stringValue(option['id']) == kind) {
        return true;
      }
    }
    return false;
  }

  String protocolLabel(String kind) {
    // 中文注释: 协议标签由核心统一返回，避免外层靠 if/else 拼字串。
    for (final option in protocolOptions()) {
      if (ValueReaders.stringValue(option['id']) == kind) {
        return ValueReaders.stringValue(option['label'], kind);
      }
    }
    return 'OpenAI 协议格式';
  }
}
