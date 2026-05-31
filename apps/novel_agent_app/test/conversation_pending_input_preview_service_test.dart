import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/presentation/services/conversation_pending_input_preview_service.dart';

void main() {
  group('ConversationPendingInputPreviewService', () {
    const service = ConversationPendingInputPreviewService();

    test('builds preview only while generation is active', () {
      final preview = service.build(
        rawText: '继续补完这一段，先压句式，再收尾。',
        isGenerating: true,
      );

      expect(preview, isNotNull);
      expect(preview!.characterCount, greaterThan(0));
      expect(preview.lineCount, 1);

      final hidden = service.build(
        rawText: '继续补完这一段，先压句式，再收尾。',
        isGenerating: false,
      );
      expect(hidden, isNull);
    });
  });
}
