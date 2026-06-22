import 'dart:async';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

/// 一次 provider 联网探测的结果。
class ProviderConnectionProbeResult {
  const ProviderConnectionProbeResult({
    required this.success,
    required this.summary,
    required this.detail,
  });

  final bool success;
  final String summary;
  final String detail;
}

/// 用真实 gateway 发起一次最小请求，验证 provider 的可达性与鉴权。
///
/// 中文注释: 这层只负责"真联网探一下"，不做本地表单校验。本地校验仍由
/// `ProviderConnectionValidationService` 负责；两者结果由壳层合并呈现，
/// 避免再用本地校验冒充联网成功。
class ProviderConnectionProbeService {
  ProviderConnectionProbeService({
    required LlmGateway Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    ) gatewayFactory,
    Duration timeout = const Duration(seconds: 20),
  }) : _gatewayFactory = gatewayFactory,
       _timeout = timeout;

  final LlmGateway Function(
    ProviderEndpointSettings provider,
    JsonMap networkSettings,
  ) _gatewayFactory;
  final Duration _timeout;

  Future<ProviderConnectionProbeResult> probe({
    required ProviderEndpointSettings provider,
    required String modelId,
    String prompt = 'ping',
  }) async {
    try {
      final gateway = _gatewayFactory(provider, const <String, Object?>{});
      await gateway
          .requestText(prompt: prompt, modelId: modelId)
          .timeout(_timeout);
      return ProviderConnectionProbeResult(
        success: true,
        summary: '本地自检与联网验证均通过。',
        detail: '联网验证成功：已连接 ${provider.baseUrl} 并完成一次模型调用。',
      );
    } catch (error) {
      return ProviderConnectionProbeResult(
        success: false,
        summary: describeConnectionError(error),
        detail: '联网验证失败：$error',
      );
    }
  }

  /// 把底层异常映射成用户能理解的人话原因。
  static String describeConnectionError(Object error) {
    if (error is TimeoutException) {
      return '连接超时（未在时限内响应），请检查网络或 baseUrl 是否可达。';
    }
    if (error is SocketException) {
      return '无法连接到服务器，请检查 baseUrl 与网络。';
    }
    final text = error.toString();
    final lower = text.toLowerCase();
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return '鉴权失败，请检查 API Key 是否正确。';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return '鉴权失败：当前 Key 没有访问权限（403）。';
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return '接口路径不存在（404），请检查 baseUrl 与协议路由。';
    }
    return '联网验证失败：$text';
  }
}
