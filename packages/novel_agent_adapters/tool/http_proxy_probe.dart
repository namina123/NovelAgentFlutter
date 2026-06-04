import 'dart:io';

import 'package:novel_agent_adapters/src/providers/system_proxy_resolver.dart';

import '../../../tools/probe_config_support.dart';

Future<void> main() async {
  // 中文注释: 这个探针只负责验证 Dart HttpClient 在 direct/system/custom 三种代理模式下是否能打通同一个 OpenAI 兼容端点。
  final apiConfig = await loadLocalProbeApiConfig(
    probeName: 'http_proxy_probe',
  );
  final requestUri = '${apiConfig.baseUrl}/models';
  final apiKey = apiConfig.apiKey;
  final resolver = const SystemProxyResolver();
  final systemProxy = await resolver.resolveFor(Uri.parse(requestUri));
  stdout.writeln('system_proxy=$systemProxy');

  for (final mode in const <String>['direct', 'system', 'custom']) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 45);
    if (mode == 'system') {
      client.findProxy = (_) => systemProxy;
    } else if (mode == 'custom') {
      client.findProxy = (_) => 'PROXY 127.0.0.1:7890';
    }
    try {
      final request = await client.getUrl(Uri.parse(requestUri));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      final response = await request.close();
      final body = await response.transform(SystemEncoding().decoder).join();
      stdout.writeln(
        'mode=$mode status=${response.statusCode} preview=${_preview(body)}',
      );
    } catch (error, stackTrace) {
      stdout.writeln('mode=$mode error=$error');
      stdout.writeln(stackTrace.toString().split('\n').take(3).join('\n'));
    } finally {
      client.close(force: true);
    }
  }
}

String _preview(String value) {
  // 中文注释: 响应预览只截短前缀，避免探针输出被长 JSON 淹没。
  final normalized = value.replaceAll('\r', ' ').replaceAll('\n', ' ');
  if (normalized.length <= 160) {
    return normalized;
  }
  return normalized.substring(0, 160);
}
