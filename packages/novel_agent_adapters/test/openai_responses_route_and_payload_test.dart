import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAiResponsesRouteResolver', () {
    test('resolves responses route and /responses uri', () {
      const resolver = OpenAiResponsesRouteResolver();

      final resolution = resolver.resolve(apiMode: 'responses');
      expect(resolution.routeFamily, RequestRouteFamily.responses);
      expect(resolution.apiMode, ProviderProfileConstants.apiModeResponses);
      expect(resolution.isAllowed, isTrue);

      final uri = resolver.resolveRequestUri('https://example.com/v1/');
      expect(uri.toString(), 'https://example.com/v1/responses');
    });
  });

  group('OpenAiResponsesRequestPayloadBuilder', () {
    test('builds instructions and input contract from messages', () {
      const builder = OpenAiResponsesRequestPayloadBuilder();

      final payload = builder.build(
        ChatRequest(
          modelId: 'demo-model',
          messages: const <JsonMap>[
            <String, Object?>{'role': 'system', 'content': 'Keep it short.'},
            <String, Object?>{'role': 'user', 'content': 'Say hi.'},
            <String, Object?>{
              'role': 'assistant',
              'content': 'Hi!',
            },
            <String, Object?>{
              'role': 'tool',
              'tool_call_id': 'call_1',
              'content': 'tool result',
            },
          ],
          tools: const <JsonMap>[
            <String, Object?>{
              'type': 'function',
              'function': <String, Object?>{
                'name': 'demo_tool',
                'description': 'demo',
                'parameters': <String, Object?>{
                  'type': 'object',
                },
              },
            },
          ],
          options: const <String, Object?>{
            'stream': true,
            'api_mode': 'responses',
          },
        ),
      );

      expect(payload['model'], 'demo-model');
      expect(payload['instructions'], 'Keep it short.');
      final input = ValueReaders.objectList(payload['input']).map(ValueReaders.mapValue).toList(
        growable: false,
      );
      expect(input, hasLength(3));
      expect(input.first['type'], 'message');
      expect(input.first['role'], 'user');
      expect(input.first['content'], 'Say hi.');
      expect(input[1]['role'], 'assistant');
      expect(input[2]['type'], 'function_call_output');
      expect(input[2]['call_id'], 'call_1');
      expect(payload['api_mode'], isNull);
      expect(payload['stream'], isTrue);
      final tools = ValueReaders.objectList(payload['tools']).map(ValueReaders.mapValue).toList(
        growable: false,
      );
      expect(tools, hasLength(1));
      expect(tools.first['name'], 'demo_tool');
      expect(tools.first['parameters'], isA<Map<String, Object?>>());
    });
  });
}
