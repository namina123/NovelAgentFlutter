// 中文注释: 一次性排障探针——验证推理模型端点经项目 OpenAiLlmGateway 是否支持 tool calling。
// 仅在本地 dart run，读取 local/probe_api.txt，不硬编码 key，结果不落正式目录。
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';

Future<void> main() async {
  final apiConfig = await loadProbeApiConfig(probeName: 'reasoning_toolcall_smoke');
  final gateway = OpenAiLlmGateway(
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    proxyRule: '',
    transportRetryEnabled: false,
  );

  // 同一个工具调用请求，分别测非流式与流式，看 reasoning 模型能否吐 tool_calls。
  final tools = <JsonMap>[
    <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': 'write_project_file',
        'description': '把给定内容写入项目相对路径的文件。',
        'parameters': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'relative_path': <String, Object?>{'type': 'string'},
            'content': <String, Object?>{'type': 'string'},
          },
          'required': <String>['relative_path', 'content'],
        },
      },
    },
  ];
  final messages = <JsonMap>[
    <String, Object?>{
      'role': 'user',
      'content': '请用 write_project_file 工具，把「你好世界」写入 premise/opening.md。',
    },
  ];

  for (final stream in <bool>[false, true]) {
    stdout.writeln('===== stream=$stream =====');
    try {
      final result = await gateway.requestChat(
        request: ChatRequest(
          modelId: apiConfig.modelId,
          messages: messages,
          tools: tools,
          options: <String, Object?>{'stream': stream, 'max_tokens': 4096},
        ),
      );
      final toolCalls = ValueReaders.objectList(result['tool_calls']);
      stdout.writeln('finish_reason=${result['finish_reason']}');
      stdout.writeln(
        'content=${(ValueReaders.stringValue(result['content'])).replaceAll('\n', '\\n')}',
      );
      stdout.writeln('tool_calls_count=${toolCalls.length}');
      for (final tc in toolCalls) {
        final m = ValueReaders.mapValue(tc);
        final fn = ValueReaders.mapValue(m['function']);
        stdout.writeln(
          '  -> name=${ValueReaders.stringValue(fn['name'])} args=${ValueReaders.stringValue(fn['arguments'])}',
        );
      }
      stdout.writeln('reasoning_len=${(result['reasoning_content'] ?? '').toString().length}');
      stdout.writeln('raw=${const JsonEncoder.withIndent('  ').convert(result)}');
    } catch (e, st) {
      stdout.writeln('ERROR=$e');
      stdout.writeln('$st');
    }
  }
}
