import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/transcript_block_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/services/conversation_transcript_lane_projection_service.dart';

void main() {
  group('ConversationTranscriptLaneProjectionService', () {
    const service = ConversationTranscriptLaneProjectionService();

    test('splits stable history, current round tool strip and streaming appendix', () {
      final lanes = service.build(
        const [
          TranscriptMessageBlockViewData(
            id: 'user_1',
            kind: TranscriptBlockKind.messageUser,
            entry: ConversationEntryViewData(
              id: 'user_1',
              kind: ConversationEntryKind.user,
              title: '你',
              body: '开始写作',
            ),
          ),
          TranscriptToolBlockViewData(
            id: 'tool_1',
            entry: ConversationEntryViewData(
              id: 'tool_1',
              kind: ConversationEntryKind.tool,
              title: 'read_project_file',
              body: '读取角色卡',
            ),
          ),
          TranscriptMessageBlockViewData(
            id: 'assistant_streaming',
            kind: TranscriptBlockKind.messageAssistantStreaming,
            entry: ConversationEntryViewData(
              id: 'assistant_streaming',
              kind: ConversationEntryKind.assistant,
              title: '综合创作智能体',
              body: '正在出字',
            ),
          ),
        ],
        isGenerating: true,
      );

      expect(lanes.stableHistoryBlocks, hasLength(1));
      expect(lanes.currentRoundToolBlocks, hasLength(1));
      expect(lanes.streamingAppendixBlocks, hasLength(1));
      expect(lanes.footerBlocks, isEmpty);
    });

    test('keeps tool block in stable history after generation settles', () {
      final lanes = service.build(
        const [
          TranscriptToolBlockViewData(
            id: 'tool_1',
            entry: ConversationEntryViewData(
              id: 'tool_1',
              kind: ConversationEntryKind.tool,
              title: 'write_project_file',
              body: '写入正文',
            ),
          ),
        ],
        isGenerating: false,
      );

      expect(lanes.stableHistoryBlocks, hasLength(1));
      expect(lanes.currentRoundToolBlocks, isEmpty);
      expect(lanes.streamingAppendixBlocks, isEmpty);
    });
  });
}
