import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAiLlmGateway', () {
    test('parses SSE chat completion stream into unified result', () async {
      // 中文注释: 这里用本地 HTTP 服务模拟 data: 事件流，验证默认流式链路不再把 SSE 当成普通 JSON 解析。
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      try {
        server.listen((request) async {
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          request.response.add(
            utf8.encode(
              'data: {"choices":[{"delta":{"role":"assistant","content":"你好"}}]}\n\n',
            ),
          );
          request.response.add(
            utf8.encode('data: {"choices":[{"delta":{"content":"，世界"}}]}\n\n'),
          );
          request.response.add(utf8.encode('data: [DONE]\n\n'));
          await request.response.close();
        });
        final gateway = OpenAiLlmGateway(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: '',
        );
        final updates = <LlmStreamUpdate>[];
        final result = await gateway.requestChat(
          messages: const <Map<String, Object?>>[
            <String, Object?>{'role': 'user', 'content': 'hi'},
          ],
          modelId: 'demo-model',
          options: const <String, Object?>{'stream': true},
          onStreamUpdate: updates.add,
        );
        expect(result['content'], '你好，世界');
        expect(updates, isNotEmpty);
        expect(updates.first.content, '你好');
        expect(updates.last.isCompleted, isTrue);
      } finally {
        await server.close(force: true);
      }
    });

    test('merges streamed tool call arguments across id and index chunks', () async {
      // 中文注释: 这里覆盖真实兼容网关常见行为：首包给出 id/name，后续参数增量只继续携带 index。
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      try {
        server.listen((request) async {
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          final firstChunk = <String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'delta': <String, Object?>{
                  'tool_calls': <Object?>[
                    <String, Object?>{
                      'index': 0,
                      'id': 'call_1',
                      'type': 'function',
                      'function': <String, Object?>{
                        'name': 'present_user_options',
                        'arguments': '',
                      },
                    },
                  ],
                },
              },
            ],
          };
          final secondChunk = <String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'delta': <String, Object?>{
                  'tool_calls': <Object?>[
                    <String, Object?>{
                      'index': 0,
                      'function': <String, Object?>{
                        'arguments':
                            '{"question":"先选方向","options":[{"title":"稳妥开局",',
                      },
                    },
                  ],
                },
              },
            ],
          };
          final thirdChunk = <String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'delta': <String, Object?>{
                  'tool_calls': <Object?>[
                    <String, Object?>{
                      'index': 0,
                      'function': <String, Object?>{
                        'arguments': '"value":"我选择稳妥开局"}]}',
                      },
                    },
                  ],
                },
              },
            ],
          };
          request.response.add(utf8.encode('data: ${jsonEncode(firstChunk)}\n\n'));
          request.response.add(utf8.encode('data: ${jsonEncode(secondChunk)}\n\n'));
          request.response.add(utf8.encode('data: ${jsonEncode(thirdChunk)}\n\n'));
          request.response.add(utf8.encode('data: [DONE]\n\n'));
          await request.response.close();
        });
        final gateway = OpenAiLlmGateway(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: '',
        );
        final result = await gateway.requestChat(
          messages: const <Map<String, Object?>>[
            <String, Object?>{'role': 'user', 'content': 'hi'},
          ],
          modelId: 'demo-model',
          options: const <String, Object?>{'stream': true},
        );
        final toolCalls = ValueReaders.objectList(result['tool_calls'])
            .map(ValueReaders.mapValue)
            .toList(growable: false);
        expect(toolCalls, hasLength(1));
        expect(toolCalls.first['name'], 'present_user_options');
        final arguments = ValueReaders.mapValue(toolCalls.first['arguments']);
        expect(arguments['question'], '先选方向');
        final options = ValueReaders.objectList(arguments['options'])
            .map(ValueReaders.mapValue)
            .toList(growable: false);
        expect(options, hasLength(1));
        expect(options.first['title'], '稳妥开局');
        expect(options.first['value'], '我选择稳妥开局');
      } finally {
        await server.close(force: true);
      }
    });
  });
}
