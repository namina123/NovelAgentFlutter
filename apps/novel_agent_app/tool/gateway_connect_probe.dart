import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_adapters/src/providers/system_proxy_resolver.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';

Future<void> main() async {
  // 中文注释: 这支探针只验证系统代理解析与 OpenAI 兼容网关连通性，不掺入项目上下文和工具链。
  final apiConfig = await loadProbeApiConfig(
    probeName: 'gateway_connect_probe',
  );
  final baseUrl = apiConfig.baseUrl;
  final apiKey = apiConfig.apiKey;
  final modelId = apiConfig.modelId;
  final resolver = const SystemProxyResolver();
  final proxyRule = await resolver.resolveFor(
    Uri.parse('$baseUrl/chat/completions'),
  );
  stdout.writeln('resolved_proxy=$proxyRule');

  final gateway = OpenAiLlmGateway(
    baseUrl: baseUrl,
    apiKey: apiKey,
    proxyRule: '',
    transportRetryEnabled: false,
  );
  final result = await gateway.requestChat(
    request: ChatRequest(
      modelId: modelId,
      messages: const <JsonMap>[
        <String, Object?>{'role': 'user', 'content': '只回复 OK'},
      ],
      options: const <String, Object?>{'stream': true},
    ),
    onStreamUpdate: (update) {
      if (update.contentDelta.isNotEmpty) {
        stdout.writeln('delta=${update.contentDelta}');
      }
    },
  );
  stdout.writeln('final=${result['content']}');
}
