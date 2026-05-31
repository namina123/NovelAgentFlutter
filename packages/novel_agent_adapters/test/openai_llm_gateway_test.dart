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
          request: ChatRequest(
            modelId: 'demo-model',
            messages: const <JsonMap>[
              <String, Object?>{'role': 'user', 'content': 'hi'},
            ],
            options: const <String, Object?>{'stream': true},
          ),
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

    test(
      'merges streamed tool call arguments across id and index chunks',
      () async {
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
            request.response.add(
              utf8.encode('data: ${jsonEncode(firstChunk)}\n\n'),
            );
            request.response.add(
              utf8.encode('data: ${jsonEncode(secondChunk)}\n\n'),
            );
            request.response.add(
              utf8.encode('data: ${jsonEncode(thirdChunk)}\n\n'),
            );
            request.response.add(utf8.encode('data: [DONE]\n\n'));
            await request.response.close();
          });
          final gateway = OpenAiLlmGateway(
            baseUrl: 'http://127.0.0.1:${server.port}',
            apiKey: '',
          );
          final result = await gateway.requestChat(
            request: ChatRequest(
              modelId: 'demo-model',
              messages: const <JsonMap>[
                <String, Object?>{'role': 'user', 'content': 'hi'},
              ],
              options: const <String, Object?>{'stream': true},
            ),
          );
          final toolCalls = ValueReaders.objectList(
            result['tool_calls'],
          ).map(ValueReaders.mapValue).toList(growable: false);
          expect(toolCalls, hasLength(1));
          expect(toolCalls.first['name'], 'present_user_options');
          final arguments = ValueReaders.mapValue(toolCalls.first['arguments']);
          expect(arguments['question'], '先选方向');
          final options = ValueReaders.objectList(
            arguments['options'],
          ).map(ValueReaders.mapValue).toList(growable: false);
          expect(options, hasLength(1));
          expect(options.first['title'], '稳妥开局');
          expect(options.first['value'], '我选择稳妥开局');
        } finally {
          await server.close(force: true);
        }
      },
    );

    test(
      'retries transient truncated transport failure before succeeding',
      () async {
        // 中文注释: 这里模拟首轮响应在 header 后立刻断开，验证网关会按传输重试策略自动补一次请求。
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        var requestCount = 0;
        try {
          server.listen((socket) {
            requestCount += 1;
            var responded = false;
            socket.listen((_) async {
              if (responded) {
                return;
              }
              responded = true;
              socket.write('HTTP/1.1 200 OK\r\n');
              socket.write('Content-Type: text/event-stream\r\n');
              socket.write('\r\n');
              if (requestCount == 1) {
                socket.write(
                  'data: {"choices":[{"delta":{"content":"首包未完成"}}]}\n\n',
                );
                await socket.flush();
                socket.destroy();
                return;
              }
              socket.write(
                'data: {"choices":[{"delta":{"role":"assistant","content":"第二次成功"}}]}\n\n',
              );
              socket.write('data: [DONE]\n\n');
              await socket.flush();
              await socket.close();
            });
          });
          final gateway = OpenAiLlmGateway(
            baseUrl: 'http://127.0.0.1:${server.port}',
            apiKey: '',
            transportRetryEnabled: true,
            transportRetryAttempts: 1,
            timeout: const Duration(seconds: 10),
          );
          final updates = <LlmStreamUpdate>[];
          final result = await gateway.requestChat(
            request: ChatRequest(
              modelId: 'demo-model',
              messages: const <JsonMap>[
                <String, Object?>{'role': 'user', 'content': 'hi'},
              ],
              options: const <String, Object?>{'stream': true},
            ),
            onStreamUpdate: updates.add,
          );
          expect(result['content'], '第二次成功');
          expect(requestCount, 2);
          expect(updates.last.isCompleted, isTrue);
        } finally {
          await server.close();
        }
      },
    );

    test('stops streaming early when cancellation token is requested', () async {
      // 中文注释: 这里验证 gateway 会把取消意图下沉到传输层，并尽量保留已收到的流式片段。
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final cancellationToken = DraftGenerationCancellationToken();
      try {
        server.listen((request) async {
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          request.response.add(
            utf8.encode(
              'data: {"choices":[{"delta":{"role":"assistant","content":"第一段"}}]}\n\n',
            ),
          );
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 80));
          request.response.add(
            utf8.encode('data: {"choices":[{"delta":{"content":"第二段"}}]}\n\n'),
          );
          await request.response.flush();
          await request.response.close();
        });
        final gateway = OpenAiLlmGateway(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: '',
          timeout: const Duration(seconds: 10),
          transportRetryEnabled: false,
        );
        final updates = <LlmStreamUpdate>[];
        final result = await gateway.requestChat(
          request: ChatRequest(
            modelId: 'demo-model',
            messages: const <JsonMap>[
              <String, Object?>{'role': 'user', 'content': 'hi'},
            ],
            options: const <String, Object?>{'stream': true},
          ),
          cancellationToken: cancellationToken,
          onStreamUpdate: (update) {
            updates.add(update);
            if (update.content == '第一段') {
              cancellationToken.cancel();
            }
          },
        );
        expect(result['content'], '第一段');
        expect(updates, isNotEmpty);
        expect(updates.last.isCompleted, isFalse);
      } finally {
        await server.close(force: true);
      }
    });
  });
}
