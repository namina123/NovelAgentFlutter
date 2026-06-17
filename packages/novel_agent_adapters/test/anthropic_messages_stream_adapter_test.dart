import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicMessagesStreamAdapter', () {
    test('parses typed SSE messages into unified result', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      try {
        server.listen((request) async {
          expect(request.uri.path, '/messages');
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          request.response.add(
            utf8.encode(
              'event: message_start\n'
              'data: {"type":"message_start","message":{"id":"msg_1","type":"message","role":"assistant"}}\n\n',
            ),
          );
          request.response.add(
            utf8.encode(
              'event: content_block_start\n'
              'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":"Hello"}}\n\n',
            ),
          );
          request.response.add(
            utf8.encode(
              'event: content_block_start\n'
              'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"read_project_file","input":{}}}\n\n',
            ),
          );
          request.response.add(
            utf8.encode(
              'event: content_block_delta\n'
              'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"relative_path\\":\\"chapters/a.md\\"}"}}\n\n',
            ),
          );
          request.response.add(
            utf8.encode(
              'event: message_stop\n'
              'data: {"type":"message_stop"}\n\n',
            ),
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
            modelId: 'claude-demo',
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

        expect(result['content'], 'Hello');
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
