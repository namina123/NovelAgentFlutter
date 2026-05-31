import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LlmGateway legacy bridge', () {
    test(
      'requestChatLegacy folds prompt into typed request messages',
      () async {
        final gateway = _RecordingGateway();

        await gateway.requestChatLegacy(
          messages: const <JsonMap>[],
          modelId: 'demo-model',
          options: const <String, Object?>{'prompt': '只回复 OK', 'stream': true},
        );

        expect(gateway.lastRequest.modelId, 'demo-model');
        expect(gateway.lastRequest.messages, hasLength(1));
        expect(gateway.lastRequest.messages.single['role'], 'user');
        expect(gateway.lastRequest.messages.single['content'], '只回复 OK');
        expect(gateway.lastRequest.options.containsKey('prompt'), isFalse);
        expect(gateway.lastRequest.options['stream'], isTrue);
      },
    );

    test('requestText reuses typed request bridge', () async {
      final gateway = _RecordingGateway();

      final content = await gateway.requestText(
        prompt: '继续写作',
        modelId: 'demo-model',
      );

      expect(content, 'OK');
      expect(gateway.lastRequest.messages.single['content'], '继续写作');
      expect(gateway.lastRequest.options, isEmpty);
    });
  });
}

class _RecordingGateway extends LlmGateway {
  ChatRequest lastRequest = ChatRequest(
    modelId: '',
    messages: const <JsonMap>[],
  );

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    lastRequest = request;
    return <String, Object?>{'content': 'OK'};
  }
}
