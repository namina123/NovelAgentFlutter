import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_timeline_snapshot.dart';
import 'package:novel_agent_app/features/workbench/presentation/services/conversation_timeline_auto_reveal_policy.dart';

void main() {
  group('ConversationTimelineAutoRevealPolicy', () {
    const policy = ConversationTimelineAutoRevealPolicy();

    test('follows new content while anchored to latest', () {
      const previous = ConversationTimelineSnapshot(
        blockCount: 1,
        lastBlockId: 'assistant_streaming',
        lastBlockContentLength: 12,
        lastBlockDetailLength: 0,
      );
      const current = ConversationTimelineSnapshot(
        blockCount: 1,
        lastBlockId: 'assistant_streaming',
        lastBlockContentLength: 20,
        lastBlockDetailLength: 0,
      );

      expect(
        policy.shouldAutoReveal(
          previous: previous,
          current: current,
          anchoredToLatest: true,
        ),
        isTrue,
      );
    });

    test('does not force scroll when user is reading older content', () {
      const previous = ConversationTimelineSnapshot(
        blockCount: 2,
        lastBlockId: 'assistant_streaming',
        lastBlockContentLength: 30,
        lastBlockDetailLength: 14,
      );
      const current = ConversationTimelineSnapshot(
        blockCount: 3,
        lastBlockId: 'assistant_streaming',
        lastBlockContentLength: 42,
        lastBlockDetailLength: 14,
      );

      expect(
        policy.shouldAutoReveal(
          previous: previous,
          current: current,
          anchoredToLatest: false,
        ),
        isFalse,
      );
    });

    test('reveals appended blocks when anchored', () {
      const previous = ConversationTimelineSnapshot(
        blockCount: 3,
        lastBlockId: 'assistant_3',
        lastBlockContentLength: 200,
        lastBlockDetailLength: 0,
      );
      const current = ConversationTimelineSnapshot(
        blockCount: 4,
        lastBlockId: 'retry_1',
        lastBlockContentLength: 6,
        lastBlockDetailLength: 0,
      );

      expect(
        policy.shouldAutoReveal(
          previous: previous,
          current: current,
          anchoredToLatest: true,
        ),
        isTrue,
      );
    });
  });
}
