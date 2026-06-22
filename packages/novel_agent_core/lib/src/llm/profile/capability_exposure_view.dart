import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_profile_constants.dart';

final class CapabilityExposureView {
  const CapabilityExposureView({
    required this.protocolMode,
    required this.protocolLabel,
    required this.apiMode,
    required this.routeFamily,
    required this.allowedApiModes,
    required this.allowedRouteFamilies,
    required this.apiModeVisible,
    required this.visibleAdvancedFields,
  });

  final String protocolMode;
  final String protocolLabel;
  final String apiMode;
  final String routeFamily;
  final List<String> allowedApiModes;
  final List<String> allowedRouteFamilies;
  final bool apiModeVisible;
  final List<String> visibleAdvancedFields;

  JsonMap toJson() {
    // 中文注释: 暴露视图是 GUI / CLI 的共同消费对象，因此这里提供稳定 JSON 投影。
    return <String, Object?>{
      'protocol_mode': protocolMode,
      'protocol_label': protocolLabel,
      'api_mode': apiMode,
      'route_family': routeFamily,
      'allowed_api_modes': List<String>.unmodifiable(allowedApiModes),
      'allowed_route_families': List<String>.unmodifiable(allowedRouteFamilies),
      'api_mode_visible': apiModeVisible,
      'visible_advanced_fields': List<String>.unmodifiable(
        visibleAdvancedFields,
      ),
    };
  }

  static CapabilityExposureView fromRuntimeProfile(JsonMap runtimeProfile) {
    // 中文注释: 视图只消费 runtime profile 里的正式合同，不回头自己推断协议和路由。
    final connection = ValueReaders.mapValue(
      runtimeProfile['provider_connection_contract'],
    );
    final runtimeRoute = ValueReaders.mapValue(
      runtimeProfile['provider_runtime_route_contract'],
    );
    final hasConnectionContract = connection.isNotEmpty;
    final protocolMode = ValueReaders.stringValue(
      runtimeRoute['protocol_kind'],
      ValueReaders.stringValue(
        connection['protocol_kind'],
        ValueReaders.stringValue(
          runtimeProfile['resolved_protocol_kind'],
          ValueReaders.stringValue(
            runtimeProfile['kind'],
            ProviderProfileConstants.kindOpenAiCompatible,
          ),
        ),
      ),
    );
    final protocolLabel = ValueReaders.stringValue(
      connection['protocol_label'],
      protocolMode,
    );
    final apiMode = ValueReaders.stringValue(
      runtimeRoute['resolved_api_mode'],
      ValueReaders.stringValue(runtimeProfile['api_mode']),
    );
    final routeFamily = ValueReaders.stringValue(
      runtimeRoute['selected_route_family'],
      ValueReaders.stringValue(
        runtimeProfile['resolved_selected_route_family'],
        ValueReaders.stringValue(
          runtimeProfile['route_family'],
          ValueReaders.stringValue(
            connection['route_family'],
            'chat_completions',
          ),
        ),
      ),
    );
    final allowedApiModes = ValueReaders.stringList(
      connection['allowed_api_modes'],
    );
    final allowedRouteFamilies = ValueReaders.stringList(
      runtimeRoute['allowed_route_families'],
    );
    final normalizedAllowedRouteFamilies = allowedRouteFamilies.isNotEmpty
        ? allowedRouteFamilies
        : ValueReaders.stringList(connection['allowed_route_families']);
    final selectableApiModes = allowedApiModes
        .where(_isSelectableApiMode)
        .toList(growable: false);
    final supportsReasoning = ValueReaders.boolValue(
      runtimeProfile['supports_reasoning'],
    );
    final supportsReasoningEffort = ValueReaders.boolValue(
      runtimeProfile['reasoning_supports_effort'],
    );
    final supportsTopK = ValueReaders.boolValue(
      runtimeProfile['supports_top_k'],
    );
    final supportsToolChoice = ValueReaders.boolValue(
      runtimeProfile['supports_tool_choice'],
    );
    final apiModeVisible =
        hasConnectionContract &&
        selectableApiModes.length > 1 &&
        selectableApiModes.any((mode) => mode != apiMode);
    final fallbackApiMode = allowedApiModes.isNotEmpty
        ? allowedApiModes.first
        : 'chat';
    final visibleAdvancedFields = <String>[];
    if (apiModeVisible) {
      visibleAdvancedFields.add('api_mode');
    }
    if (supportsReasoning) {
      visibleAdvancedFields.add('thinking_enabled');
    }
    if (supportsReasoningEffort) {
      visibleAdvancedFields.add('thinking_effort');
    }
    if (supportsToolChoice) {
      visibleAdvancedFields.add('tool_choice');
    }
    if (supportsTopK) {
      visibleAdvancedFields.add('top_k');
    }
    if (ValueReaders.boolValue(runtimeProfile['supports_streaming'])) {
      visibleAdvancedFields.add('stream');
    }
    return CapabilityExposureView(
      protocolMode: protocolMode,
      protocolLabel: protocolLabel,
      apiMode: apiMode,
      routeFamily: routeFamily,
      allowedApiModes: allowedApiModes.isEmpty
          ? <String>[fallbackApiMode]
          : allowedApiModes,
      allowedRouteFamilies: normalizedAllowedRouteFamilies,
      apiModeVisible: apiModeVisible,
      visibleAdvancedFields: List<String>.unmodifiable(visibleAdvancedFields),
    );
  }

  static bool _isSelectableApiMode(String apiMode) {
    // 中文注释: 不是所有 route family 的 api_mode 都应该对用户暴露，流式实现路由和 embeddings 这类内部路由要先过滤掉。
    switch (apiMode) {
      case 'stream_generate_content':
      case 'embeddings':
        return false;
      default:
        return true;
    }
  }
}
