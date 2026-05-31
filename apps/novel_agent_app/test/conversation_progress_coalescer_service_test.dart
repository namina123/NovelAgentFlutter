import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_progress_coalescer_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('coalescer emits only latest progress within the interval', () async {
    final emitted = <DraftGenerationProgress>[];
    final handle = const ConversationProgressCoalescerService(
      interval: Duration(milliseconds: 50),
    ).bind(emitted.add);

    handle.schedule(
      const DraftGenerationProgress(
        phase: 'stream',
        roundIndex: 1,
        draftMarkdown: 'a',
      ),
    );
    handle.schedule(
      const DraftGenerationProgress(
        phase: 'stream',
        roundIndex: 1,
        draftMarkdown: 'ab',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(emitted, hasLength(1));
    expect(emitted.single.draftMarkdown, 'ab');
  });

  test('coalescer flushes pending progress immediately', () {
    final emitted = <DraftGenerationProgress>[];
    final handle = const ConversationProgressCoalescerService().bind(
      emitted.add,
    );

    handle.schedule(
      const DraftGenerationProgress(
        phase: 'stream',
        roundIndex: 1,
        draftMarkdown: 'latest',
      ),
    );
    handle.flushNow();

    expect(emitted, hasLength(1));
    expect(emitted.single.draftMarkdown, 'latest');
  });
}
