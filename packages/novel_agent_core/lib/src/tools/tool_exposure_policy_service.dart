import '../common/host_platform.dart';
import 'builtin_tool_catalog.dart';
import 'builtin_tool_definition.dart';
import 'tool_platform_policy.dart';

class ToolExposurePolicyService {
  const ToolExposurePolicyService();

  List<String> filterExposedToolIds(
    List<String> toolIds, {
    required HostPlatform hostPlatform,
  }) {
    // 中文注释: 工具暴露过滤只决定“哪些 schema 可以给模型看”，不影响宿主侧手工执行或探针执行。
    final result = <String>[];
    for (final toolId in toolIds) {
      if (isToolExposed(toolId, hostPlatform: hostPlatform)) {
        result.add(toolId);
      }
    }
    return result;
  }

  bool isToolExposed(String toolId, {required HostPlatform hostPlatform}) {
    // 中文注释: 传输层工具和当前平台不支持的工具要在 schema 层就被拦掉，避免模型拿到错误能力心智。
    final definition = _definitionById(toolId);
    if (definition == null) {
      return false;
    }
    switch (definition.platformPolicy) {
      case ToolPlatformPolicy.transportOnly:
        return false;
      case ToolPlatformPolicy.desktopOnly:
      case ToolPlatformPolicy.desktopOrGatewayOnly:
        return !_isMobile(hostPlatform);
      case ToolPlatformPolicy.mobileSafeIfProjectScoped:
      default:
        return true;
    }
  }

  BuiltinToolDefinition? _definitionById(String toolId) {
    for (final definition in BuiltinToolCatalog.definitions) {
      if (definition.id == toolId) {
        return definition;
      }
    }
    return null;
  }

  bool _isMobile(HostPlatform platform) {
    return platform == HostPlatform.android || platform == HostPlatform.ios;
  }
}
