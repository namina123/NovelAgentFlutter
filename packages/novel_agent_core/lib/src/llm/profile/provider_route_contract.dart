import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_profile_constants.dart';

enum ProtocolKind {
  openAiCompatible,
  anthropicCompatible,
  geminiNative,
}

extension ProtocolKindContract on ProtocolKind {
  String get id {
    // 中文注释: 协议标识由正式合同统一提供，避免 core 各处再拼散字符串。
    switch (this) {
      case ProtocolKind.openAiCompatible:
        return ProviderProfileConstants.kindOpenAiCompatible;
      case ProtocolKind.anthropicCompatible:
        return ProviderProfileConstants.kindAnthropicCompatible;
      case ProtocolKind.geminiNative:
        return 'gemini_native';
    }
  }

  String get label {
    // 中文注释: 协议标签与协议标识分离，方便 UI 和诊断输出共享同一份稳定投影。
    switch (this) {
      case ProtocolKind.openAiCompatible:
        return 'OpenAI 协议格式';
      case ProtocolKind.anthropicCompatible:
        return 'Anthropic 协议格式';
      case ProtocolKind.geminiNative:
        return 'Gemini 原生协议';
    }
  }

  RequestRouteFamily get defaultRouteFamily {
    // 中文注释: 默认路由族用于 api_mode 缺省和非法值回退，必须与协议默认面一致。
    switch (this) {
      case ProtocolKind.openAiCompatible:
        return RequestRouteFamily.chatCompletions;
      case ProtocolKind.anthropicCompatible:
        return RequestRouteFamily.messages;
      case ProtocolKind.geminiNative:
        return RequestRouteFamily.generateContent;
    }
  }

  List<RequestRouteFamily> get supportedRouteFamilies {
    // 中文注释: 协议可运行路由族先在合同层集中声明，后续 UI 与 gateway 再按这份结果分流。
    switch (this) {
      case ProtocolKind.openAiCompatible:
        return const <RequestRouteFamily>[
          RequestRouteFamily.chatCompletions,
          RequestRouteFamily.responses,
          RequestRouteFamily.embeddings,
        ];
      case ProtocolKind.anthropicCompatible:
        return const <RequestRouteFamily>[RequestRouteFamily.messages];
      case ProtocolKind.geminiNative:
        return const <RequestRouteFamily>[
          RequestRouteFamily.generateContent,
          RequestRouteFamily.streamGenerateContent,
        ];
    }
  }

  List<String> get supportedApiModes {
    // 中文注释: api_mode 作为 UI 投影时，只暴露与当前协议已确认一致的路由族。
    return supportedRouteFamilies
        .map((family) => family.apiMode)
        .toList(growable: false);
  }

  JsonMap toJson() {
    // 中文注释: 这里把协议合同转成字典，供旧接口与测试断言直接消费。
    return <String, Object?>{
      'id': id,
      'label': label,
      'default_route_family': defaultRouteFamily.id,
      'route_families': supportedRouteFamilies
          .map((family) => family.id)
          .toList(growable: false),
      'api_modes': supportedApiModes,
    };
  }
}

abstract final class ProtocolKindCodec {
  static ProtocolKind? tryParse(String? value) {
    // 中文注释: 协议解析只做稳定归一化，不在这里偷偷回退，避免隐藏上游输入错误。
    final normalized = ValueReaders.stringValue(value).trim().toLowerCase();
    switch (normalized) {
      case ProviderProfileConstants.kindOpenAiCompatible:
        return ProtocolKind.openAiCompatible;
      case ProviderProfileConstants.kindAnthropicCompatible:
        return ProtocolKind.anthropicCompatible;
      case 'gemini_native':
        return ProtocolKind.geminiNative;
      default:
        return null;
    }
  }

  static ProtocolKind parse(
    String? value, {
    ProtocolKind fallback = ProtocolKind.openAiCompatible,
  }) {
    // 中文注释: 需要兜底时统一在这里处理，保证调用者得到稳定协议枚举。
    return tryParse(value) ?? fallback;
  }
}

enum RequestRouteFamily {
  chatCompletions,
  responses,
  messages,
  generateContent,
  streamGenerateContent,
  embeddings,
}

extension RequestRouteFamilyContract on RequestRouteFamily {
  String get id {
    // 中文注释: 路由族 id 是稳定合同，后续 gateway、UI、测试都要共用同一套值。
    switch (this) {
      case RequestRouteFamily.chatCompletions:
        return ProviderProfileConstants.routeFamilyChatCompletions;
      case RequestRouteFamily.responses:
        return ProviderProfileConstants.routeFamilyResponses;
      case RequestRouteFamily.messages:
        return ProviderProfileConstants.routeFamilyMessages;
      case RequestRouteFamily.generateContent:
        return ProviderProfileConstants.routeFamilyGenerateContent;
      case RequestRouteFamily.streamGenerateContent:
        return ProviderProfileConstants.routeFamilyStreamGenerateContent;
      case RequestRouteFamily.embeddings:
        return ProviderProfileConstants.routeFamilyEmbeddings;
    }
  }

  String get label {
    // 中文注释: 路由族的展示名保持直白，便于设置页和诊断页直接投影。
    switch (this) {
      case RequestRouteFamily.chatCompletions:
        return 'Chat Completions';
      case RequestRouteFamily.responses:
        return 'Responses';
      case RequestRouteFamily.messages:
        return 'Messages';
      case RequestRouteFamily.generateContent:
        return 'Generate Content';
      case RequestRouteFamily.streamGenerateContent:
        return 'Stream Generate Content';
      case RequestRouteFamily.embeddings:
        return 'Embeddings';
    }
  }

  String get apiMode {
    // 中文注释: api_mode 是 route family 的 UI 投影，返回值必须是短而稳定的规范模式名。
    switch (this) {
      case RequestRouteFamily.chatCompletions:
        return ProviderProfileConstants.apiModeChat;
      case RequestRouteFamily.responses:
        return ProviderProfileConstants.apiModeResponses;
      case RequestRouteFamily.messages:
        return ProviderProfileConstants.apiModeMessages;
      case RequestRouteFamily.generateContent:
        return ProviderProfileConstants.apiModeGenerateContent;
      case RequestRouteFamily.streamGenerateContent:
        return ProviderProfileConstants.apiModeStreamGenerateContent;
      case RequestRouteFamily.embeddings:
        return ProviderProfileConstants.apiModeEmbeddings;
    }
  }

  JsonMap toJson() {
    // 中文注释: route family 的 JSON 投影用于测试、调试与后续 UI 选项消费。
    return <String, Object?>{
      'id': id,
      'label': label,
      'api_mode': apiMode,
    };
  }
}

abstract final class RequestRouteFamilyCodec {
  static RequestRouteFamily? tryParse(String? value) {
    // 中文注释: 兼容字符串输入时，先做标准化再决定是否命中正式 route family。
    final normalized = ValueReaders.stringValue(value).trim().toLowerCase();
    switch (normalized) {
      case ProviderProfileConstants.routeFamilyChatCompletions:
      case ProviderProfileConstants.apiModeChat:
        return RequestRouteFamily.chatCompletions;
      case ProviderProfileConstants.routeFamilyResponses:
      case ProviderProfileConstants.apiModeResponses:
        return RequestRouteFamily.responses;
      case ProviderProfileConstants.routeFamilyMessages:
      case ProviderProfileConstants.apiModeMessages:
        return RequestRouteFamily.messages;
      case ProviderProfileConstants.routeFamilyGenerateContent:
      case ProviderProfileConstants.apiModeGenerateContent:
        return RequestRouteFamily.generateContent;
      case ProviderProfileConstants.routeFamilyStreamGenerateContent:
      case ProviderProfileConstants.apiModeStreamGenerateContent:
        return RequestRouteFamily.streamGenerateContent;
      case ProviderProfileConstants.routeFamilyEmbeddings:
      case ProviderProfileConstants.apiModeEmbeddings:
        return RequestRouteFamily.embeddings;
      case 'generate_content':
        return RequestRouteFamily.generateContent;
      case 'stream_generate_content':
        return RequestRouteFamily.streamGenerateContent;
      default:
        return null;
    }
  }

  static RequestRouteFamily parse(
    String? value, {
    RequestRouteFamily fallback = RequestRouteFamily.chatCompletions,
  }) {
    // 中文注释: 需要兜底时统一在这一层处理，避免各调用点自己发明默认值。
    return tryParse(value) ?? fallback;
  }
}

final class ApiModeRouteMapping {
  const ApiModeRouteMapping._();

  static RequestRouteFamily routeFamilyForApiMode(
    String apiMode, {
    ProtocolKind protocolKind = ProtocolKind.openAiCompatible,
    Iterable<RequestRouteFamily>? allowedRouteFamilies,
    RequestRouteFamily? fallbackRouteFamily,
  }) {
    // 中文注释: api_mode 先映射成 route family，再按当前协议允许范围做收口，避免 UI 假开关直通网关。
    final allowedFamilies = allowedRouteFamiliesFor(
      protocolKind,
      allowedRouteFamilies: allowedRouteFamilies,
    );
    final requestedFamily = RequestRouteFamilyCodec.tryParse(apiMode);
    if (requestedFamily != null && allowedFamilies.contains(requestedFamily)) {
      return requestedFamily;
    }
    final fallbackFamily = fallbackRouteFamily ?? protocolKind.defaultRouteFamily;
    if (allowedFamilies.contains(fallbackFamily)) {
      return fallbackFamily;
    }
    if (allowedFamilies.isNotEmpty) {
      return allowedFamilies.first;
    }
    return fallbackFamily;
  }

  static String normalizeApiMode(
    String apiMode, {
    ProtocolKind protocolKind = ProtocolKind.openAiCompatible,
    Iterable<RequestRouteFamily>? allowedRouteFamilies,
    RequestRouteFamily? fallbackRouteFamily,
  }) {
    // 中文注释: 这里输出的是规范 api_mode，而不是原始输入，方便 request options 直接消费。
    return routeFamilyForApiMode(
      apiMode,
      protocolKind: protocolKind,
      allowedRouteFamilies: allowedRouteFamilies,
      fallbackRouteFamily: fallbackRouteFamily,
    ).apiMode;
  }

  static List<RequestRouteFamily> allowedRouteFamiliesFor(
    ProtocolKind protocolKind, {
    Iterable<RequestRouteFamily>? allowedRouteFamilies,
  }) {
    // 中文注释: 若调用方没有额外约束，就使用协议自身声明的可运行路由族。
    return List<RequestRouteFamily>.unmodifiable(
      allowedRouteFamilies == null
          ? protocolKind.supportedRouteFamilies
          : allowedRouteFamilies.toList(growable: false),
    );
  }

  static List<String> apiModeOptions(
    ProtocolKind protocolKind, {
    Iterable<RequestRouteFamily>? allowedRouteFamilies,
  }) {
    // 中文注释: api_mode 选项直接来源于 allowed route families，避免 UI 再自己拼选项列表。
    return allowedRouteFamiliesFor(
      protocolKind,
      allowedRouteFamilies: allowedRouteFamilies,
    ).map((family) => family.apiMode).toList(growable: false);
  }

  static List<JsonMap> apiModeOptionDocuments(
    ProtocolKind protocolKind, {
    Iterable<RequestRouteFamily>? allowedRouteFamilies,
  }) {
    // 中文注释: 这里提供给后续 UI/诊断的稳定选项文档，便于直接渲染 route family 候选。
    return allowedRouteFamiliesFor(
      protocolKind,
      allowedRouteFamilies: allowedRouteFamilies,
    ).map((family) {
      return <String, Object?>{
        'id': family.apiMode,
        'label': family.label,
        'route_family': family.id,
        'protocol_kind': protocolKind.id,
      };
    }).toList(growable: false);
  }

  static List<JsonMap> routeFamilyDocuments(
    ProtocolKind protocolKind, {
    Iterable<RequestRouteFamily>? allowedRouteFamilies,
  }) {
    // 中文注释: route family 文档和 api_mode 文档同源，但保留 route_family 维度的原始语义。
    return allowedRouteFamiliesFor(
      protocolKind,
      allowedRouteFamilies: allowedRouteFamilies,
    ).map((family) {
      return <String, Object?>{
        'id': family.id,
        'label': family.label,
        'api_mode': family.apiMode,
        'protocol_kind': protocolKind.id,
      };
    }).toList(growable: false);
  }
}

final class GatewayRouteResolution {
  const GatewayRouteResolution({
    required this.protocolKind,
    required this.routeFamily,
    required this.allowedRouteFamilies,
    required this.requestedApiMode,
    required this.resolvedApiMode,
    required this.fallbackRouteFamily,
  });

  final ProtocolKind protocolKind;
  final RequestRouteFamily routeFamily;
  final List<RequestRouteFamily> allowedRouteFamilies;
  final String requestedApiMode;
  final String resolvedApiMode;
  final RequestRouteFamily fallbackRouteFamily;

  String get apiMode {
    // 中文注释: 解析结果对外保留规范 api_mode，方便 request options 和诊断输出直接读取。
    return resolvedApiMode;
  }

  bool get isFallbackUsed {
    // 中文注释: 如果最终路由与输入投影不一致，就说明发生了回退或收口。
    return requestedApiMode.trim().isNotEmpty &&
        requestedApiMode.trim().toLowerCase() != resolvedApiMode.toLowerCase();
  }

  bool get isAllowed {
    // 中文注释: 路由是否可用取决于最终路由族是否落在允许列表中。
    return allowedRouteFamilies.contains(routeFamily);
  }

  JsonMap toJson() {
    // 中文注释: 这份 JSON 投影供测试、日志和后续 UI 诊断统一消费。
    return <String, Object?>{
      'protocol_kind': protocolKind.id,
      'route_family': routeFamily.id,
      'api_mode': resolvedApiMode,
      'requested_api_mode': requestedApiMode,
      'allowed_route_families': allowedRouteFamilies
          .map((family) => family.id)
          .toList(growable: false),
      'fallback_route_family': fallbackRouteFamily.id,
      'is_fallback_used': isFallbackUsed,
      'is_allowed': isAllowed,
    };
  }

  static GatewayRouteResolution resolve({
    required ProtocolKind protocolKind,
    String apiMode = '',
    Iterable<RequestRouteFamily>? allowedRouteFamilies,
    RequestRouteFamily? fallbackRouteFamily,
  }) {
    // 中文注释: 网关路由解析把协议默认面、api_mode 输入和允许路由族收成单一稳定结果。
    final allowedFamilies = ApiModeRouteMapping.allowedRouteFamiliesFor(
      protocolKind,
      allowedRouteFamilies: allowedRouteFamilies,
    );
    final fallbackFamily = fallbackRouteFamily ?? protocolKind.defaultRouteFamily;
    final routeFamily = ApiModeRouteMapping.routeFamilyForApiMode(
      apiMode,
      protocolKind: protocolKind,
      allowedRouteFamilies: allowedFamilies,
      fallbackRouteFamily: fallbackFamily,
    );
    return GatewayRouteResolution(
      protocolKind: protocolKind,
      routeFamily: routeFamily,
      allowedRouteFamilies: allowedFamilies,
      requestedApiMode: ValueReaders.stringValue(apiMode).trim(),
      resolvedApiMode: routeFamily.apiMode,
      fallbackRouteFamily: fallbackFamily,
    );
  }
}
