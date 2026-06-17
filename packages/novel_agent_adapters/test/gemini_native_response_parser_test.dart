import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('GeminiNativeResponseParser', () {
    test('normalizes native candidates, thoughts and function calls', () {
      const parser = GeminiNativeResponseParser();

      final result = parser.parseBody(
        '''
        {
          "candidates": [
            {
              "content": {
                "parts": [
                  {"text": "Hello"},
                  {
                    "functionCall": {
                      "id": "call_1",
                      "name": "demo_tool",
                      "args": {"value": "x"}
                    }
                  }
                ]
              },
              "thoughts": [
                {"text": "Thinking..."}
              ]
            }
          ]
        }
        ''',
      );

      expect(result['ok'], isTrue);
      expect(result['content'], 'Hello');
      expect(result['reasoning_content'], 'Thinking...');
      expect(ValueReaders.objectList(result['tool_calls']), hasLength(1));
      final toolCall = ValueReaders.mapValue(
        ValueReaders.objectList(result['tool_calls']).first,
      );
      expect(toolCall['name'], 'demo_tool');
      expect(toolCall['arguments'], isA<Map<String, Object?>>());
    });
  });
}
