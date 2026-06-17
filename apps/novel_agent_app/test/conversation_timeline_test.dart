import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/sub_agent_run_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_transcript_lane_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/transcript_block_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_timeline.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/transcript_block_renderer_registry.dart';

void main() {
  group('ConversationTimeline', () {
    testWidgets('reveals latest entry on initial restore render', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 320,
              child: ConversationTimeline(
                lanes: ConversationTranscriptLaneViewData(
                  stableHistoryBlocks: List<TranscriptBlockViewData>.generate(
                    24,
                    (index) => TranscriptMessageBlockViewData(
                      id: 'assistant_$index',
                      kind: TranscriptBlockKind.messageAssistantFinal,
                      entry: ConversationEntryViewData(
                        id: 'entry_$index',
                        kind: ConversationEntryKind.assistant,
                        title: '综合创作智能体',
                        body: '第$index条消息 ${'正文铺陈。' * 10}',
                      ),
                    ),
                    growable: false,
                  ),
                  currentRoundToolBlocks: const <TranscriptBlockViewData>[],
                  streamingAppendixBlocks: const <TranscriptBlockViewData>[],
                  footerBlocks: const <TranscriptBlockViewData>[],
                ),
                renderContext: const TranscriptBlockRenderContext(
                  showToolDetails: false,
                  onRetryRequested: _noop,
                  onUserOptionSelected: _ignoreOption,
                  onSubAgentSelected: _ignoreSubAgent,
                ),
                rendererRegistry: const TranscriptBlockRendererRegistry(),
              ),
            ),
          ),
      ),
    );
      await tester.pump();

      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ConversationTimeline),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        scrollable.position.pixels,
        greaterThanOrEqualTo(scrollable.position.maxScrollExtent - 1),
      );
    });

    testWidgets('preserve current position restore keeps user scroll anchor', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 320,
              child: ConversationTimeline(
                restoreResult: const SessionRestoreResult(
                  restoredSessionIds: <String>['s1', 's2'],
                  activeSessionId: 's2',
                  showSessionHistory: true,
                  defaultScrollTarget:
                      SessionRestoreScrollTarget.preserveCurrentPosition,
                ),
                lanes: ConversationTranscriptLaneViewData(
                  stableHistoryBlocks: List<TranscriptBlockViewData>.generate(
                    24,
                    (index) => TranscriptMessageBlockViewData(
                      id: 'assistant_$index',
                      kind: TranscriptBlockKind.messageAssistantFinal,
                      entry: ConversationEntryViewData(
                        id: 'entry_$index',
                        kind: ConversationEntryKind.assistant,
                        title: '综合创作智能体',
                        body: '第$index条消息 ${'正文铺陈。' * 10}',
                      ),
                    ),
                    growable: false,
                  ),
                  currentRoundToolBlocks: const <TranscriptBlockViewData>[],
                  streamingAppendixBlocks: const <TranscriptBlockViewData>[],
                  footerBlocks: const <TranscriptBlockViewData>[],
                ),
                renderContext: const TranscriptBlockRenderContext(
                  showToolDetails: false,
                  onRetryRequested: _noop,
                  onUserOptionSelected: _ignoreOption,
                  onSubAgentSelected: _ignoreSubAgent,
                ),
                rendererRegistry: const TranscriptBlockRendererRegistry(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ConversationTimeline),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, lessThan(10));
    });
  });
}

void _noop() {}

void _ignoreOption(UserOptionViewData _) {}

void _ignoreSubAgent(SubAgentRunViewData _) {}
