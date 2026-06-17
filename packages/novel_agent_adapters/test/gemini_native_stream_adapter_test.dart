import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('GeminiNativeStreamAdapter', () {
    test('recognizes stream bodies and aggregates native event payloads', () {
      final adapter = GeminiNativeStreamAdapter();

      expect(adapter.looksLikeEventStream('data: {"candidates": []}'), isTrue);
      expect(adapter.looksLikeEventStream('{"candidates": []}'), isFalse);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final result = adapter.parseEventStreamBody(
        'data: {"candidates":[{"content":{"parts":[{"text":"Hel"}]},"thoughts":[{"text":"Thinking"}]}]}\n\n'
        'data: {"candidates":[{"content":{"parts":[{"text":"lo"}]}}]}\n\n'
        'data: {"done": true}\n\n'
        'data: [DONE]\n',
        cancellationScope: OpenAiGatewayCancellationScope(
          client: client,
          cancellationToken: null,
        ),
      );

      expect(result['ok'], isTrue);
      expect(result['content'], 'Hello');
      expect(result['reasoning_content'], 'Thinking');
    });
  });
}
