import '../../common/json_types.dart';
import 'provider_profile_constants.dart';
import 'provider_route_contract.dart';

class ProviderProtocolService {
  List<JsonMap> protocolOptions() {
    // 中文注释: 协议枚举集中在这一层，避免 GUI、CLI、适配器分别维护副本。
    return ProtocolKind.values
        .map((kind) => kind.toJson())
        .toList(growable: false);
  }

  ProtocolKind? protocolKindOf(String kind) {
    // 中文注释: 协议字符串先归一化成正式枚举，方便后续合同和路由解析共用。
    return ProtocolKindCodec.tryParse(kind);
  }

  bool isSupportedProtocol(String kind) {
    // 中文注释: 协议支持性判断属于纯规则，不需要让运行配置层重复关心细节。
    return protocolKindOf(kind) != null;
  }

  String protocolLabel(String kind) {
    // 中文注释: 协议标签由核心统一返回，避免外层靠 if/else 拼字串。
    final protocolKind = protocolKindOf(kind);
    if (protocolKind != null) {
      return protocolKind.label;
    }
    return 'OpenAI 协议格式';
  }

  List<RequestRouteFamily> supportedRouteFamilies(String kind) {
    // 中文注释: 路由族从协议合同导出，供 request options 和未来 UI 复用同一份真相。
    final protocolKind = protocolKindOf(kind);
    if (protocolKind == null) {
      return const <RequestRouteFamily>[];
    }
    return protocolKind.supportedRouteFamilies;
  }

  List<String> supportedApiModes(String kind) {
    // 中文注释: api_mode 选项是 route family 的 UI 投影，因此要跟协议支持族同步输出。
    final protocolKind = protocolKindOf(kind);
    if (protocolKind == null) {
      return const <String>[];
    }
    return ApiModeRouteMapping.apiModeOptions(protocolKind);
  }

  List<JsonMap> routeFamilyOptions(String kind) {
    // 中文注释: route family 的字典投影保留给设置页或诊断页直接消费，不再要求上层自己拼。
    final protocolKind = protocolKindOf(kind);
    if (protocolKind == null) {
      return const <JsonMap>[];
    }
    return ApiModeRouteMapping.routeFamilyDocuments(protocolKind);
  }

  List<JsonMap> apiModeOptions(String kind) {
    // 中文注释: api_mode 文档与 route family 文档同源，只是投影成更适合旧 UI 的短名。
    final protocolKind = protocolKindOf(kind);
    if (protocolKind == null) {
      return const <JsonMap>[];
    }
    return ApiModeRouteMapping.apiModeOptionDocuments(protocolKind);
  }

  GatewayRouteResolution resolveGatewayRoute({
    required String kind,
    String apiMode = '',
    Iterable<RequestRouteFamily>? allowedRouteFamilies,
  }) {
    // 中文注释: 协议 + api_mode 解析成网关路由合同，后续 request options 与 gateway 可直接消费。
    final protocolKind =
        protocolKindOf(kind) ?? ProtocolKind.openAiCompatible;
    return GatewayRouteResolution.resolve(
      protocolKind: protocolKind,
      apiMode: apiMode,
      allowedRouteFamilies: allowedRouteFamilies,
    );
  }
}
