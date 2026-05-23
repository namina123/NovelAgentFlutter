import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Long task guidance services', () {
    final appendService = LongTaskGuidanceAppendService();
    final messageService = LongTaskGuidanceMessageService();
    final consumeService = LongTaskGuidanceConsumeService(
      messageService: messageService,
    );

    test('appends guidance and consumes it before next tool call', () {
      // 中文注释: 这里验证运行中引导会进入队列，并在主智能体下次工具调用前转成注入消息。
      final appended = appendService.appendGuidance(
        const <Object?>[],
        '先改口吻，再继续写这一章。',
        createdAt: '2026-05-23T12:00:00Z',
      );
      final consumed = consumeService.consumeGuidance(
        appended['queue'] as List<Object?>,
        createdAt: '2026-05-23T12:01:00Z',
        taskContext: const <String, Object?>{'task_title': '第一章'},
      );

      expect(appended['ok'], isTrue);
      expect(appended['pending_count'], 1);
      expect(consumed['has_guidance'], isTrue);
      final delivered = consumed['delivered_guidance'] as List<Object?>;
      final message = consumed['message'] as Map<String, Object?>;
      expect(delivered, hasLength(1));
      expect((delivered.first as Map<String, Object?>)['status'], 'delivered');
      expect(message['content'], contains('运行中引导'));
      expect(message['content'], contains('第一章'));
    });
  });
}
