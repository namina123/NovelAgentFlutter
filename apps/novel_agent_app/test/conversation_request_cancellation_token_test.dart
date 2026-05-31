import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_request_cancellation_token.dart';

void main() {
  group('ConversationRequestCancellationToken', () {
    test('cancel flips state only once and notifies listeners once', () {
      final token = ConversationRequestCancellationToken();
      var callbackCount = 0;

      token.addListener(() {
        callbackCount += 1;
      });

      expect(token.isCancellationRequested, isFalse);
      expect(token.cancel(), isTrue);
      expect(token.cancel(), isFalse);
      expect(token.isCancellationRequested, isTrue);
      expect(callbackCount, 1);
    });

    test('late listeners are replayed immediately after cancellation', () {
      final token = ConversationRequestCancellationToken()..cancel();
      var callbackCount = 0;

      token.addListener(() {
        callbackCount += 1;
      });

      expect(callbackCount, 1);
    });
  });
}
