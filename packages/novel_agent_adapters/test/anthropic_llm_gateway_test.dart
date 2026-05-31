import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicLlmGateway', () {
    test(
      'posts anthropic messages payload and normalizes text response',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        try {
          server.listen((request) async {
            expect(request.uri.path, '/messages');
            expect(request.headers.value('x-api-key'), 'demo-key');
            expect(request.headers.value('anthropic-version'), '2023-06-01');
            final body = await utf8.decoder.bind(request).join();
            final payload = ValueReaders.mapValue(jsonDecode(body));
            expect(payload['model'], 'deepseek-v4-flash');
            expect(ValueReaders.stringValue(payload['system']), 'system rule');
            final messages = ValueReaders.mapList(payload['messages']);
            expect(messages, hasLength(1));
            expect(messages.first['role'], 'user');
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode(<String, Object?>{
                'id': 'msg_1',
                'type': 'message',
                'role': 'assistant',
                'content': <Object?>[
                  <String, Object?>{'type': 'text', 'text': '你好，Anthropic'},
                ],
              }),
            );
            await request.response.close();
          });
          final gateway = AnthropicLlmGateway(
            baseUrl: 'http://127.0.0.1:${server.port}',
            apiKey: 'demo-key',
            proxyRule: 'DIRECT',
          );
          final result = await gateway.requestChat(
            request: ChatRequest(
              modelId: 'deepseek-v4-flash',
              messages: const <JsonMap>[
                <String, Object?>{'role': 'system', 'content': 'system rule'},
                <String, Object?>{'role': 'user', 'content': 'hello'},
              ],
              options: const <String, Object?>{'stream': false},
            ),
          );
          expect(result['content'], '你好，Anthropic');
          expect(ValueReaders.objectList(result['tool_calls']), isEmpty);
        } finally {
          await server.close(force: true);
        }
      },
    );

    test('normalizes anthropic streamed tool_use events', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      try {
        server.listen((request) async {
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          request.response.write(
            'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_1","type":"message","role":"assistant"}}\n\n',
          );
          request.response.write(
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_1","name":"read_project_file","input":{}}}\n\n',
          );
          request.response.write(
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"relative_path\\":\\"chapters/a.md\\"}"}}\n\n',
          );
          request.response.write(
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n\n',
          );
          await request.response.close();
        });
        final gateway = AnthropicLlmGateway(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: 'demo-key',
          proxyRule: 'DIRECT',
        );
        final updates = <LlmStreamUpdate>[];
        final result = await gateway.requestChat(
          request: ChatRequest(
            modelId: 'deepseek-v4-flash',
            messages: const <JsonMap>[
              <String, Object?>{'role': 'user', 'content': 'read file'},
            ],
            tools: const <JsonMap>[
              <String, Object?>{
                'type': 'function',
                'function': <String, Object?>{
                  'name': 'read_project_file',
                  'description': 'read file',
                  'parameters': <String, Object?>{
                    'type': 'object',
                    'properties': <String, Object?>{
                      'relative_path': <String, Object?>{'type': 'string'},
                    },
                  },
                },
              },
            ],
            options: const <String, Object?>{'stream': true},
          ),
          onStreamUpdate: updates.add,
        );
        final toolCalls = ValueReaders.mapList(result['tool_calls']);
        expect(toolCalls, hasLength(1));
        expect(toolCalls.first['name'], 'read_project_file');
        expect(
          ValueReaders.mapValue(toolCalls.first['arguments'])['relative_path'],
          'chapters/a.md',
        );
        expect(updates, isNotEmpty);
        expect(updates.last.isCompleted, isTrue);
      } finally {
        await server.close(force: true);
      }
    });
  });
}
