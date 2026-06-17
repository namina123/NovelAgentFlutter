import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAiLlmGateway responses route', () {
    test('parses typed SSE responses into unified result', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      try {
        server.listen((request) async {
          expect(request.uri.path, '/responses');
          final body = await utf8.decoder.bind(request).join();
          final payload = ValueReaders.mapValue(jsonDecode(body));
          expect(payload['instructions'], 'Keep it short.');
          expect(payload['model'], 'demo-model');
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          request.response.add(
            utf8.encode(
              'data: {"type":"response.created","response":{"id":"resp_1"}}\n\n',
            ),
          );
          request.response.add(
            utf8.encode(
              'data: {"type":"response.output_text.delta","delta":"Hello"}\n\n',
            ),
          );
          request.response.add(
            utf8.encode(
              'data: {"type":"response.function_call_arguments.delta","call_id":"call_1","item_id":"item_1","delta":"{\\"foo\\":1}"}\n\n',
            ),
          );
          request.response.add(
            utf8.encode(
              'data: {"type":"response.completed","response":{"id":"resp_1"}}\n\n',
            ),
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
              <String, Object?>{'role': 'system', 'content': 'Keep it short.'},
              <String, Object?>{'role': 'user', 'content': 'Say hi.'},
            ],
            options: const <String, Object?>{
              'api_mode': 'responses',
              'stream': true,
            },
          ),
          onStreamUpdate: updates.add,
        );

        expect(result['content'], 'Hello');
        expect(result['tool_calls'], isNotEmpty);
        expect(updates, isNotEmpty);
        expect(updates.last.isCompleted, isTrue);
        expect(updates.last.content, 'Hello');
      } finally {
        await server.close(force: true);
      }
    });
  });
}
