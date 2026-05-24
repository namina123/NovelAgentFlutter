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
  });
}
