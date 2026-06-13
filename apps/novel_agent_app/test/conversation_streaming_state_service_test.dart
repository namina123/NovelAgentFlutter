import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_tool_lifecycle_status.dart';
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
              'sub_session_id': 'sub_session_1',
              'agent_id': 'style_reviewer',
              'agent_name': '风格审校员',
              'task': '压一下第二章的 AI 味',
              'summary': '已给出两条具体修改建议。',
              'result_markdown': '把过度解释的句子收短。',
              'reasoning_content': '先找共性句式。',
              'tool_count': 1,
              'collaboration_result_package': <String, Object?>{
                'package_id': 'pkg_1',
                'execution_package_id': 'exec_1',
                'child_run_package_id': 'child_1',
                'agent_id': 'style_reviewer',
                'agent_name': '风格审校员',
                'status': 'success',
                'used_tool_count': 1,
                'merge_contract': <String, Object?>{
                  'merge_mode': 'main_agent_merges',
                  'parent_review_required': true,
                  'allows_direct_delivery': false,
                  'accepted_result_types': <Object?>['suggestion'],
                },
                'conflicts': <Object?>[
                  <String, Object?>{
                    'conflict_id': 'conflict_1',
                    'subject': '第二章表达风格',
                    'agent_id': 'style_reviewer',
                    'agent_name': '风格审校员',
                    'risk': 'low',
                    'suggestion': '把过度解释的句子收短。',
                    'adoption_hint': '主智能体先复核后吸收。',
                    'confidence': 0.76,
                    'evidence': <Object?>[
                      <String, Object?>{'summary': '段尾解释句过密。'},
                    ],
                  },
                ],
                'arbitration_result': <String, Object?>{
                  'arbitration_id': 'arb_1',
                  'status': 'auto_resolved',
                  'highest_risk': 'low',
                  'selected_conflict_id': 'conflict_1',
                  'summary': '主链可以先复核这条建议，再决定是否吸收。',
                },
              },
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
    expect(nextState.subAgentRuns.single.expertOpinion, contains('把过度解释的句子收短'));
    expect(
      nextState.subAgentRuns.single.evidenceItems.single,
      contains('段尾解释句过密'),
    );
    expect(
      nextState.subAgentRuns.single.adoptionSummary,
      contains('主链可以先复核这条建议'),
    );
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

  test('streaming state includes pending tool calls as running entries', () {
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
        phase: 'tool_calls_ready',
        roundIndex: 1,
        pendingToolCalls: <JsonMap>[
          <String, Object?>{
            'id': 'pending_1',
            'name': 'request_external_research',
            'result': <String, Object?>{'question': '明代后期汤药照护习惯'},
          },
        ],
      ),
    );

    expect(nextState.entries, hasLength(1));
    expect(nextState.entries.single.kind, ConversationEntryKind.tool);
    expect(nextState.entries.single.body, '已发起，正在发起资料研究');
    expect(
      nextState.entries.single.toolLifecycleStatus,
      ConversationToolLifecycleStatus.running,
    );
  });
}
