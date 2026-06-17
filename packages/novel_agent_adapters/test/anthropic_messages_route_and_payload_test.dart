import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicMessagesRouteResolver', () {
    test('resolves messages route and /messages uri', () {
      const resolver = AnthropicMessagesRouteResolver();

      final resolution = resolver.resolve(apiMode: 'messages');
      expect(resolution.routeFamily, RequestRouteFamily.messages);
      expect(resolution.apiMode, ProviderProfileConstants.apiModeMessages);
      expect(resolution.isAllowed, isTrue);

      final uri = resolver.resolveRequestUri('https://example.com/v1/');
      expect(uri.toString(), 'https://example.com/v1/messages');
    });
  });

  group('AnthropicMessagesRequestPayloadBuilder', () {
    test('builds messages payload with system and tool blocks', () {
      const builder = AnthropicMessagesRequestPayloadBuilder();

      final payload = builder.build(
        ChatRequest(
          modelId: 'claude-demo',
          messages: const <JsonMap>[
            <String, Object?>{'role': 'system', 'content': 'system rule'},
            <String, Object?>{'role': 'user', 'content': 'hello'},
            <String, Object?>{
              'role': 'assistant',
              'content': 'hi',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'toolu_1',
                  'name': 'read_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'chapters/a.md',
                  },
                },
              ],
            },
            <String, Object?>{
              'role': 'tool',
              'tool_call_id': 'toolu_1',
              'content': 'file content',
            },
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
          options: const <String, Object?>{
            'stream': true,
            'anthropic-version': 'ignored',
          },
        ),
      );

      expect(payload['model'], 'claude-demo');
      expect(ValueReaders.stringValue(payload['system']), 'system rule');
      final messages = ValueReaders.mapList(payload['messages']);
      expect(messages, hasLength(3));
      expect(messages.first['role'], 'user');
      expect(messages.first['content'], isA<List<Object?>>());
      expect(messages[1]['role'], 'assistant');
      final assistantContent = ValueReaders.objectList(messages[1]['content']).map(ValueReaders.mapValue).toList(
        growable: false,
      );
      expect(assistantContent, hasLength(2));
      expect(assistantContent.last['type'], 'tool_use');
      expect(assistantContent.last['name'], 'read_project_file');
      final toolResult = ValueReaders.objectList(messages[2]['content']).map(ValueReaders.mapValue).toList(
        growable: false,
      );
      expect(toolResult.first['type'], 'tool_result');
      expect(toolResult.first['tool_use_id'], 'toolu_1');
      expect(payload['stream'], isTrue);
      final tools = ValueReaders.mapList(payload['tools']);
      expect(tools, hasLength(1));
      expect(tools.first['function'], isA<Map<String, Object?>>());
    });
  });
}
