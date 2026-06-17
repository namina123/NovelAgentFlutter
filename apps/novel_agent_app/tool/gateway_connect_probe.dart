import 'dart:convert';
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
  final report = <String, Object?>{
    'probe_name': 'gateway_connect_probe',
    'base_url': baseUrl,
    'model_id': modelId,
    'resolved_proxy': proxyRule,
    'chat': const <String, Object?>{},
    'responses': const <String, Object?>{},
  };
  final chatResult = await gateway.requestChat(
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
  stdout.writeln('chat_final=${chatResult['content']}');
  report['chat'] = <String, Object?>{
    'ok': ValueReaders.boolValue(chatResult['ok'], true),
    'content': ValueReaders.stringValue(chatResult['content']),
    'tool_calls': ValueReaders.deepCopyList(
      ValueReaders.objectList(chatResult['tool_calls']),
    ),
    'report_category': ProbeReportCategories.success,
  };

  try {
    final responsesResult = await gateway.requestChat(
      request: ChatRequest(
        modelId: modelId,
        messages: const <JsonMap>[
          <String, Object?>{'role': 'system', 'content': '只回复 OK'},
          <String, Object?>{'role': 'user', 'content': '只回复 OK'},
        ],
        options: const <String, Object?>{
          'stream': true,
          'api_mode': 'responses',
        },
      ),
      onStreamUpdate: (update) {
        if (update.contentDelta.isNotEmpty) {
          stdout.writeln('responses_delta=${update.contentDelta}');
        }
      },
    );
    stdout.writeln('responses_final=${responsesResult['content']}');
    report['responses'] = <String, Object?>{
      'ok': ValueReaders.boolValue(responsesResult['ok'], true),
      'content': ValueReaders.stringValue(responsesResult['content']),
      'tool_calls': ValueReaders.deepCopyList(
        ValueReaders.objectList(responsesResult['tool_calls']),
      ),
      'report_category': ProbeReportCategories.success,
    };
  } catch (error) {
    final message = '$error';
    stdout.writeln('responses_failed=$message');
    report['responses'] = <String, Object?>{
      'ok': false,
      'content': '',
      'tool_calls': const <Object?>[],
      'report_category': _classifyResponsesFailure(message),
      'summary': message,
    };
  }

  final reportPath = await _writeReport(report);
  stdout.writeln('report: $reportPath');
}

String _classifyResponsesFailure(String message) {
  // 中文注释: responses 失败时先区分“接口不支持”与“真实技术故障”，避免把 404 类配置问题误报成链路崩坏。
  final lower = message.toLowerCase();
  if (lower.contains('404') ||
      lower.contains('not found') ||
      lower.contains('page not found') ||
      lower.contains('/responses')) {
    return 'configuration_unsupported';
  }
  return ProbeReportCategories.technicalFailure;
}

Future<String> _writeReport(JsonMap report) async {
  // 中文注释: 统一把探针结果落到 artifacts，便于后续和其他真实 provider probe 横向对照。
  final reportDir = Directory('artifacts/real_model_probes');
  await reportDir.create(recursive: true);
  final reportPath =
      '${reportDir.path}${Platform.pathSeparator}gateway_connect_probe_report.json';
  await File(
    reportPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  return reportPath;
}
