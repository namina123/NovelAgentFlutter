import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../profile/provider_profile_constants.dart';
import '../profile/provider_route_contract.dart';
import 'provider_interface_template_service.dart';

final class ProviderConnectionContract {
  const ProviderConnectionContract({
    required this.templateId,
    required this.providerId,
    required this.label,
    required this.protocolId,
    required this.protocolKind,
    required this.defaultBaseUrl,
    required this.baseUrlHints,
    required this.allowedRouteFamilies,
    required this.routeFamily,
    required this.notes,
  });

  final String templateId;
  final String providerId;
  final String label;
  final String protocolId;
  final ProtocolKind? protocolKind;
  final String defaultBaseUrl;
  final List<String> baseUrlHints;
  final List<RequestRouteFamily> allowedRouteFamilies;
  final RequestRouteFamily routeFamily;
  final String notes;

  String get protocolLabel {
    // 中文注释: 连接合同保留原始协议 id，同时给已知协议一个稳定的展示标签。
    if (protocolKind != null) {
      return protocolKind!.label;
    }
    return protocolId.trim().isEmpty ? 'OpenAI 协议格式' : protocolId;
  }

  List<String> get allowedApiModes {
    // 中文注释: 连接合同对外只暴露规范 api_mode，避免上层再读 route_family 原始字符串。
    return allowedRouteFamilies.map((family) => family.apiMode).toList(
      growable: false,
    );
  }

  JsonMap toJson() {
    // 中文注释: connection contract 的 JSON 投影用于测试、诊断和后续 view-data 消费。
    return <String, Object?>{
      'template_id': templateId,
      'provider_id': providerId,
      'label': label,
      'protocol_id': protocolId,
      'protocol_kind': protocolKind?.id ?? protocolId,
      'protocol_label': protocolLabel,
      'default_base_url': defaultBaseUrl,
      'base_url_hints': List<String>.unmodifiable(baseUrlHints),
      'route_family': routeFamily.id,
      'allowed_route_families': allowedRouteFamilies
          .map((family) => family.id)
          .toList(growable: false),
      'allowed_api_modes': allowedApiModes,
      'notes': notes,
    };
  }
}

final class ProviderConnectionContractResolution {
  const ProviderConnectionContractResolution({
    required this.contract,
    required this.matchedTemplate,
    required this.baseUrl,
    required this.query,
  });

  final ProviderConnectionContract contract;
  final JsonMap matchedTemplate;
  final String baseUrl;
  final String query;

  JsonMap toJson() {
    // 中文注释: resolution 的 JSON 投影保留模板来源，方便测试确认命中路径与回退路径。
    return <String, Object?>{
      'query': query,
      'base_url': baseUrl,
      'contract': contract.toJson(),
      'matched_template': ValueReaders.deepCopyMap(matchedTemplate),
    };
  }
}

class ProviderConnectionContractService {
  ProviderConnectionContractService({
    ProviderInterfaceTemplateService? templateService,
  }) : _templateService = templateService ?? ProviderInterfaceTemplateService.seeded();

  final ProviderInterfaceTemplateService _templateService;

  List<ProviderConnectionContract> contracts({
    String query = '',
    String baseUrl = '',
  }) {
    // 中文注释: 连接合同来源于模板目录，统一做一次归一化后再给上层消费。
    return _templateService
        .templates(query: query, baseUrl: baseUrl)
        .map(_contractFromTemplate)
        .toList(growable: false);
  }

  ProviderConnectionContractResolution resolve({
    String query = '',
    String baseUrl = '',
    String providerId = '',
    String preferredProtocolId = '',
  }) {
    // 中文注释: 先做模板匹配，再输出稳定 contract，避免上层自己再读模板字段。
    final template = _bestTemplateMatch(
      query: query,
      baseUrl: baseUrl,
      providerId: providerId,
      preferredProtocolId: preferredProtocolId,
    );
    if (query.trim().isEmpty && baseUrl.trim().isEmpty) {
      return ProviderConnectionContractResolution(
        contract: _manualContract(),
        matchedTemplate: <String, Object?>{},
        baseUrl: baseUrl,
        query: query,
      );
    }
    if (template.isEmpty) {
      return ProviderConnectionContractResolution(
        contract: _manualContract(),
        matchedTemplate: <String, Object?>{},
        baseUrl: baseUrl,
        query: query,
      );
    }
    return ProviderConnectionContractResolution(
      contract: _contractFromTemplate(template),
      matchedTemplate: template,
      baseUrl: baseUrl,
      query: query,
    );
  }

  ProviderConnectionContract? contractByTemplateId(String templateId) {
    // 中文注释: 这个入口用于测试和少量直接命中场景，保留模板 id 的稳定定位能力。
    final template = _templateService.templateById(templateId);
    if (template.isEmpty) {
      return null;
    }
    return _contractFromTemplate(template);
  }

  ProviderConnectionContract _contractFromTemplate(JsonMap template) {
    // 中文注释: 模板到连接合同的归一化只在这一个地方做，避免 route family 规则在别处再长一套。
    final protocolId = ValueReaders.stringValue(template['protocol']);
    final protocolKind = ProtocolKindCodec.tryParse(protocolId);
    final rawRouteFamily = _routeFamilyFromTemplate(
      ValueReaders.stringValue(template['route_family']),
      protocolKind: protocolKind,
    );
    final allowedRouteFamilies = _allowedRouteFamilies(
      protocolKind: protocolKind,
      template: template['allowed_route_families'],
      fallbackRouteFamily: rawRouteFamily,
    );
    final routeFamily = allowedRouteFamilies.contains(rawRouteFamily)
        ? rawRouteFamily
        : (allowedRouteFamilies.isNotEmpty
              ? allowedRouteFamilies.first
              : _defaultRouteFamilyForProtocol(protocolKind));
    return ProviderConnectionContract(
      templateId: ValueReaders.stringValue(template['id']),
      providerId: ValueReaders.stringValue(template['provider_id']),
      label: ValueReaders.stringValue(template['label']),
      protocolId: protocolId,
      protocolKind: protocolKind,
      defaultBaseUrl: ValueReaders.stringValue(template['default_base_url']),
      baseUrlHints: ValueReaders.stringList(template['base_url_hints']),
      allowedRouteFamilies: allowedRouteFamilies,
      routeFamily: routeFamily,
      notes: ValueReaders.stringValue(template['notes']),
    );
  }

  JsonMap _bestTemplateMatch({
    String query = '',
    String baseUrl = '',
    String providerId = '',
    String preferredProtocolId = '',
  }) {
    // 中文注释: 在通用模板命中基础上，再用 provider_id 与 protocol 约束收口，避免同厂商 native/compatible 模板互相抢占。
    var candidates = _templateService.templates(query: query, baseUrl: baseUrl);
    final cleanProviderId = providerId.trim();
    if (cleanProviderId.isNotEmpty) {
      final providerFiltered = candidates
          .where(
            (template) =>
                ValueReaders.stringValue(template['provider_id']) ==
                cleanProviderId,
          )
          .toList(growable: false);
      if (providerFiltered.isNotEmpty) {
        candidates = providerFiltered;
      }
    }
    final cleanProtocolId = preferredProtocolId.trim();
    if (cleanProtocolId.isNotEmpty) {
      final protocolFiltered = candidates
          .where(
            (template) =>
                ValueReaders.stringValue(template['protocol']) ==
                cleanProtocolId,
          )
          .toList(growable: false);
      if (protocolFiltered.isNotEmpty) {
        candidates = protocolFiltered;
      }
    }
    if (candidates.isEmpty) {
      return <String, Object?>{};
    }
    return ValueReaders.deepCopyMap(candidates.first);
  }

  List<RequestRouteFamily> _allowedRouteFamilies(
    {
    required ProtocolKind? protocolKind,
    required Object? template,
    RequestRouteFamily? fallbackRouteFamily,
  }) {
    // 中文注释: 允许路由族优先来自模板显式字段，没有时才回退到协议默认可运行族。
    final families = <RequestRouteFamily>[];
    for (final raw in ValueReaders.stringList(template)) {
      final parsed = RequestRouteFamilyCodec.tryParse(raw);
      if (parsed != null && !families.contains(parsed)) {
        families.add(parsed);
      }
    }
    if (families.isEmpty) {
      final fallback =
          fallbackRouteFamily ?? _defaultRouteFamilyForProtocol(protocolKind);
      if (!families.contains(fallback)) {
        families.add(fallback);
      }
    }
    return List<RequestRouteFamily>.unmodifiable(families);
  }

  RequestRouteFamily _routeFamilyFromTemplate(
    String rawRouteFamily, {
    required ProtocolKind? protocolKind,
  }) {
    // 中文注释: 模板原始 route_family 先尝试解析成正式路由族，组合型标签则交给默认面收口。
    final parsed = RequestRouteFamilyCodec.tryParse(rawRouteFamily);
    if (parsed != null) {
      return parsed;
    }
    return _defaultRouteFamilyForProtocol(protocolKind);
  }

  RequestRouteFamily _defaultRouteFamilyForProtocol(ProtocolKind? protocolKind) {
    // 中文注释: 协议默认路由族优先走正式枚举，未知协议则按模板家族的现实使用场景回退。
    if (protocolKind != null) {
      return protocolKind.defaultRouteFamily;
    }
    return RequestRouteFamily.chatCompletions;
  }

  ProviderConnectionContract _manualContract() {
    // 中文注释: 手动接口是连接合同的显式兜底，而不是让模板匹配隐式抢走空输入。
    return ProviderConnectionContract(
      templateId: 'manual_openai_compatible',
      providerId: '',
      label: '无厂商 / 手动接口',
      protocolId: ProviderProfileConstants.kindOpenAiCompatible,
      protocolKind: ProtocolKind.openAiCompatible,
      defaultBaseUrl: '',
      baseUrlHints: const <String>[],
      allowedRouteFamilies: const <RequestRouteFamily>[
        RequestRouteFamily.chatCompletions,
      ],
      routeFamily: RequestRouteFamily.chatCompletions,
      notes: '手动接口兜底连接合同。',
    );
  }
}
