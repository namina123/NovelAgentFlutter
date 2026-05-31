import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_attachment_draft.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_session_state.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_streaming_state_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('streaming state projects sub-agent runs from executed tools', () {
    final sessionStateService = ConversationSessionStateService();
    final streamingStateService = ConversationStreamingStateService(
      sessionStateService: sessionStateService,
    );
    const baseState = ConversationSessionState(
      sessionRecord: <String, Object?>{},
      entries: [],
      pendingOptions: [],
      subAgentRuns: [],
      attachmentDrafts: <ConversationAttachmentDraft>[],
      retryRequest: null,
    );

    final nextState = streamingStateService.stateWithProgress(
      baseState,
      const DraftGenerationProgress(
        phase: 'tool_result',
        roundIndex: 1,
        executedTools: [
          <String, Object?>{
            'name': 'call_sub_agent',
            'result': <String, Object?>{
              'ok': true,
              'sub_agent_run_id': 'sub_run_1',
              'agent_name': '风格审校员',
              'task': '压一下第二章的 AI 味',
              'summary': '已给出两条具体修改建议。',
              'result_markdown': '把过度解释的句子收短。',
              'reasoning_content': '先找共性句式。',
              'tool_count': 1,
              'sub_agent_events': [
                <String, Object?>{'summary': '接收任务并开始分析。'},
                <String, Object?>{'summary': '完成建议整理。'},
              ],
            },
          },
        ],
      ),
    );

    expect(nextState.subAgentRuns, hasLength(1));
    expect(nextState.subAgentRuns.single.id, 'sub_run_1');
    expect(nextState.subAgentRuns.single.agentName, '风格审校员');
    expect(nextState.subAgentRuns.single.events, ['接收任务并开始分析。', '完成建议整理。']);
  });

  test('streaming tool entries skip heavy detail bodies', () {
    final sessionStateService = ConversationSessionStateService();
    final streamingStateService = ConversationStreamingStateService(
      sessionStateService: sessionStateService,
    );
    const baseState = ConversationSessionState(
      sessionRecord: <String, Object?>{},
      entries: [],
      pendingOptions: [],
      subAgentRuns: [],
      attachmentDrafts: <ConversationAttachmentDraft>[],
      retryRequest: null,
    );

    final nextState = streamingStateService.stateWithProgress(
      baseState,
      const DraftGenerationProgress(
        phase: 'tool_result',
        roundIndex: 1,
        executedTools: [
          <String, Object?>{
            'id': 'tool_1',
            'name': 'write_project_file',
            'ok': true,
            'arguments': <String, Object?>{
              'relative_path': 'chapters/chapter_01.md',
            },
            'result': <String, Object?>{
              'relative_path': 'chapters/chapter_01.md',
              'content': '很长很长的正文',
            },
          },
        ],
      ),
    );

    expect(nextState.entries, hasLength(1));
    expect(nextState.entries.single.kind, ConversationEntryKind.tool);
    expect(nextState.entries.single.detailBody, isEmpty);
  });
}
