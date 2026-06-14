import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_transcript_block_projection_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_context_compaction_segment_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_context_projection_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/retry_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/sub_agent_run_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/transcript_block_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';

void main() {
  group('ConversationTranscriptBlockProjectionService', () {
    test('projects entries and appendix into semantic transcript blocks', () {
      const service = ConversationTranscriptBlockProjectionService();

      final blocks = service.build(
        entries: const [
          ConversationEntryViewData(
            id: 'user_1',
            kind: ConversationEntryKind.user,
            title: '你',
            body: '写第一章',
          ),
          ConversationEntryViewData(
            id: 'tool_1',
            kind: ConversationEntryKind.tool,
            title: 'read_project_file',
            body: '读取角色设定',
          ),
          ConversationEntryViewData(
            id: 'system_1',
            kind: ConversationEntryKind.system,
            title: '本轮失败',
            body: '网络超时',
            isError: true,
          ),
        ],
        isGenerating: false,
        pendingOptions: const [
          UserOptionViewData(
            label: '稳妥开局',
            description: '先稳住设定。',
            prompt: '我选择稳妥开局',
            sourceQuestion: '下一步怎么写？',
            allOptions: <Map<String, Object?>>[],
          ),
        ],
        subAgentRuns: const [
          SubAgentRunViewData(
            id: 'sub_1',
            agentName: '设定审校员',
            task: '检查角色卡',
            status: '完成',
            summary: '已补完缺口。',
            content: '内容',
            reasoning: '思路',
            toolCount: 1,
            events: ['接收任务。'],
          ),
        ],
        retryRequest: const RetryRequestViewData(
          label: '继续生成',
          errorMessage: '网络超时',
        ),
      );

      expect(blocks.map((block) => block.kind), [
        TranscriptBlockKind.messageUser,
        TranscriptBlockKind.toolCompact,
        TranscriptBlockKind.runtimeNotice,
        TranscriptBlockKind.retryBanner,
        TranscriptBlockKind.choiceGroup,
        TranscriptBlockKind.subAgentPreview,
      ]);
    });

    test(
      'adds streaming placeholder when generation is active without text',
      () {
        const service = ConversationTranscriptBlockProjectionService();

        final blocks = service.build(
          entries: const [],
          isGenerating: true,
          pendingOptions: const [],
          subAgentRuns: const [],
          retryRequest: null,
        );

        expect(blocks, hasLength(1));
        expect(
          blocks.single.kind,
          TranscriptBlockKind.messageAssistantStreaming,
        );
        expect(
          (blocks.single as TranscriptMessageBlockViewData).isPlaceholder,
          isTrue,
        );
      },
    );

    test(
      'prepends archive folds when the context projection has compaction segments',
      () {
        const service = ConversationTranscriptBlockProjectionService();
        final pressureSnapshot = SessionContextPressureSnapshot(
          settings: SessionTokenBudgetSettings(
            modelContextWindowTokens: 1000,
            reservedOutputTokens: 100,
          ),
          estimate: SessionTokenBudgetEstimate(
            systemPromptTokens: 20,
            messageTokens: 120,
            framingTokens: 12,
          ),
        );
        final projection = ConversationContextProjectionViewData(
          pressureSnapshot: pressureSnapshot,
          transcriptMessageCount: 3,
          workingContextMessageCount: 2,
          compactionSegments: const [
            ConversationContextCompactionSegmentViewData(
              id: 'segment_1',
              title: '发送前压缩',
              summary: '已压缩保存更早历史',
              sourceMessageCount: 3,
              createdAt: '2026-06-14T00:00:00.000Z',
              sourceMessageRoles: ['user', 'assistant'],
            ),
          ],
        );

        final blocks = service.build(
          entries: const [
            ConversationEntryViewData(
              id: 'user_1',
              kind: ConversationEntryKind.user,
              title: '你',
              body: '继续写。',
            ),
          ],
          isGenerating: false,
          pendingOptions: const [],
          subAgentRuns: const [],
          retryRequest: null,
          contextProjection: projection,
        );

        expect(blocks.first, isA<TranscriptRuntimeNoticeBlockViewData>());
        expect(
          (blocks.first as TranscriptRuntimeNoticeBlockViewData).entry.title,
          '发送前压缩',
        );
        expect(
          (blocks.first as TranscriptRuntimeNoticeBlockViewData).entry.body,
          '已压缩保存更早历史',
        );
        expect(blocks[1].kind, TranscriptBlockKind.messageUser);
      },
    );
  });
}
