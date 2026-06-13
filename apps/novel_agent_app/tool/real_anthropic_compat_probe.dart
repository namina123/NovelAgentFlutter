import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';

Future<void> main() async {
  final apiConfig = await loadProbeApiConfig(
    probeName: 'real_anthropic_compat_probe',
  );
  final baseUrl = apiConfig.baseUrl;
  final apiKey = apiConfig.apiKey;
  final modelId = apiConfig.modelId;
  final provider = ProviderEndpointSettings(
    id: 'opencode_go_anthropic_probe',
    title: 'OpenCode Go Anthropic Probe',
    protocol: ProviderProfileConstants.kindAnthropicCompatible,
    baseUrl: baseUrl,
    apiKey: apiKey,
    modelId: modelId,
    description: 'real anthropic compatibility probe',
  );
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: Directory.current.path,
  );
  final gateway = bundle.createGateway(
    provider,
    networkSettings: const <String, Object?>{
      'proxy_mode': 'custom',
      'proxy_protocol': 'http',
      'proxy_host': '127.0.0.1',
      'proxy_port': '7890',
      'timeout_seconds': 90,
      'transport_retry_enabled': true,
      'transport_retry_attempts': 1,
    },
  );

  final plainRequest = ChatRequest(
    modelId: modelId,
    messages: const <JsonMap>[
      <String, Object?>{
        'role': 'system',
        'content': 'You are a compatibility probe. Reply with only OK.',
      },
      <String, Object?>{'role': 'user', 'content': 'reply only OK'},
    ],
    options: const <String, Object?>{
      'stream': false,
      'temperature': 0.2,
      'max_tokens': 128,
    },
  );

  stdout.writeln('=== anthropic plain probe ===');
  try {
    final result = await gateway.requestChat(request: plainRequest);
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'ok': result['ok'],
        'content': result['content'],
        'reasoning_content': result['reasoning_content'],
        'tool_calls': result['tool_calls'],
        'raw_response': result['raw_response'],
      }),
    );
  } catch (error, stackTrace) {
    stdout.writeln('plain probe failed: $error');
    stdout.writeln(stackTrace);
  }

  final toolRequest = ChatRequest(
    modelId: modelId,
    messages: const <JsonMap>[
      <String, Object?>{
        'role': 'user',
        'content':
            'Use the tool to read chapters/demo.md. Do not answer directly.',
      },
    ],
    tools: const <JsonMap>[
      <String, Object?>{
        'type': 'function',
        'function': <String, Object?>{
          'name': 'read_project_file',
          'description': 'Read a project file by relative path.',
          'parameters': <String, Object?>{
            'type': 'object',
            'properties': <String, Object?>{
              'relative_path': <String, Object?>{'type': 'string'},
            },
            'required': <Object?>['relative_path'],
          },
        },
      },
    ],
    options: const <String, Object?>{
      'stream': true,
      'temperature': 0.2,
      'max_tokens': 256,
    },
  );

  stdout.writeln('=== anthropic tool probe ===');
  try {
    final updates = <JsonMap>[];
    final result = await gateway.requestChat(
      request: toolRequest,
      onStreamUpdate: (update) {
        updates.add(<String, Object?>{
          'content_delta': update.contentDelta,
          'content': update.content,
          'reasoning_delta': update.reasoningDelta,
          'reasoning_content': update.reasoningContent,
          'tool_calls': update.toolCalls,
          'is_completed': update.isCompleted,
        });
      },
    );
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'ok': result['ok'],
        'content': result['content'],
        'reasoning_content': result['reasoning_content'],
        'tool_calls': result['tool_calls'],
        'stream_updates': updates,
        'raw_response': result['raw_response'],
      }),
    );
  } catch (error, stackTrace) {
    stdout.writeln('tool probe failed: $error');
    stdout.writeln(stackTrace);
  }
}
