import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('GeminiNativeRouteResolver', () {
    test('resolves generateContent routes and native request uri', () {
      const resolver = GeminiNativeRouteResolver();

      final resolution = resolver.resolve(apiMode: 'stream_generate_content');
      expect(resolution.protocolKind, ProtocolKind.geminiNative);
      expect(resolution.routeFamily, RequestRouteFamily.streamGenerateContent);
      expect(
        resolution.apiMode,
        ProviderProfileConstants.apiModeStreamGenerateContent,
      );

      final uri = resolver.resolveRequestUri(
        'https://generativelanguage.googleapis.com/v1beta/',
        modelId: 'gemini-3.5',
        apiMode: 'generate_content',
      );
      expect(
        uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5:generateContent',
      );
    });
  });

  group('GeminiNativeRequestPayloadBuilder', () {
    test('builds native contents and function declarations payload', () {
      const builder = GeminiNativeRequestPayloadBuilder();

      final payload = builder.build(
        ChatRequest(
          modelId: 'gemini-3.5',
          messages: const <JsonMap>[
            <String, Object?>{'role': 'system', 'content': 'Stay brief.'},
            <String, Object?>{'role': 'user', 'content': 'Say hello.'},
            <String, Object?>{
              'role': 'assistant',
              'content': 'Hello!',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_1',
                  'name': 'demo_tool',
                  'arguments': <String, Object?>{'value': 'x'},
                },
              ],
            },
            <String, Object?>{
              'role': 'tool',
              'tool_name': 'demo_tool',
              'content': 'tool output',
            },
          ],
          tools: const <JsonMap>[
            <String, Object?>{
              'type': 'function',
              'function': <String, Object?>{
                'name': 'demo_tool',
                'description': 'demo',
                'parameters': <String, Object?>{'type': 'object'},
              },
            },
          ],
          options: const <String, Object?>{
            'stream': true,
            'thinking_enabled': true,
            'thinking_effort': 'high',
          },
        ),
      );

      expect(payload['systemInstruction'], isA<Map<String, Object?>>());
      final contents = ValueReaders.mapList(payload['contents']);
      expect(contents, hasLength(3));
      expect(contents.first['role'], 'user');
      expect(contents[1]['role'], 'model');
      expect(contents[2]['role'], 'user');
      final tools = ValueReaders.mapList(payload['tools']);
      expect(tools, hasLength(1));
      expect(tools.first['functionDeclarations'], isA<List<Object?>>());
      final generationConfig = ValueReaders.mapValue(
        payload['generationConfig'],
      );
      expect(generationConfig['temperature'], isNull);
      expect(generationConfig['thinkingConfig'], isA<Map<String, Object?>>());
    });
  });
}
