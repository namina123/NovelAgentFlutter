import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_streaming_state_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';

void main() {
  group('ConversationSessionStateService', () {
    test('failed assistant message stays out of session context by default', () {
      // 中文注释: 这里验证失败提示只进入时间线展示，不会污染后续发给模型的会话上下文。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's1',
        needsGoalSelection: false,
      );
      final userState = service.stateWithUserPrompt(created, '先写开场');
      final failedState = service.stateWithAssistantFailure(
        userState,
        '生成失败：网络异常',
      );

      final markdown = service.sessionContextMarkdown(failedState);
      expect(markdown, contains('user: 先写开场'));
      expect(markdown, isNot(contains('网络异常')));
      expect(failedState.entries.last.isError, isTrue);
    });

    test('user prompt can use dedicated visible text without changing context payload', () {
      // 中文注释: 用户可见文本与真实上下文消息应拆开，避免工作流入口把内部 prompt 暴露给用户。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's_visible',
        needsGoalSelection: false,
      );
      final next = service.stateWithUserPrompt(
        created,
        '这是送给模型的长提示词',
        displayContent: '我选择了“智能开局”',
      );

      expect(next.entries.single.body, '我选择了“智能开局”');
      expect(service.sessionContextMarkdown(next), contains('这是送给模型的长提示词'));
    });

    test('assistant result exposes reasoning as collapsed detail payload', () {
      // 中文注释: 助手正文与思考信息需要分栏投影，便于 UI 做折叠展示。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's2',
        needsGoalSelection: false,
      );
      final result = DraftGenerationResult(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        projectInfo: const <String, Object?>{},
        userPrompt: '写正文',
        prompt: 'prompt',
        modelId: 'test-model',
        draftMarkdown: '这是正文。',
        contextPack: const <String, Object?>{},
        selectedPaths: const <String>[],
        executedTools: const <Object?>[],
        writtenPaths: const <String>[],
        changedPaths: const <String>[],
        transcriptMessages: const <JsonMap>[],
        waitingForUserChoice: false,
        reasoningContent: '先检查设定，再写出开场冲突。',
        stoppedByToolError: false,
        toolErrorSummary: '',
      );

      final next = service.stateWithAssistantResult(created, result);
      final entry = next.entries.single;
      expect(entry.body, '这是正文。');
      expect(entry.detailTitle, '思考');
      expect(entry.detailBody, contains('开场冲突'));
      expect(entry.detailSummary, isNotEmpty);
    });

    test('assistant result keeps reasoning entry even when body is empty', () {
      // 中文注释: 纯工具回合也要保留助手思考条目，否则用户会看到一串工具而完全不知道智能体在想什么。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's_reasoning_only',
        needsGoalSelection: false,
      );
      final result = DraftGenerationResult(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        projectInfo: const <String, Object?>{},
        userPrompt: '智能开局',
        prompt: 'prompt',
        modelId: 'test-model',
        draftMarkdown: '',
        contextPack: const <String, Object?>{},
        selectedPaths: const <String>[],
        executedTools: const <Object?>[],
        writtenPaths: const <String>[],
        changedPaths: const <String>[],
        transcriptMessages: const <JsonMap>[],
        waitingForUserChoice: false,
        reasoningContent: '先检查项目目录，再决定下一步。',
        stoppedByToolError: false,
        toolErrorSummary: '',
      );

      final next = service.stateWithAssistantResult(created, result);
      expect(next.entries.single.kind, ConversationEntryKind.assistant);
      expect(next.entries.single.detailTitle, '思考');
      expect(next.entries.single.body, isEmpty);
    });

    test('recoverable tool result does not become error entry', () {
      // 中文注释: 工具缺少路径这类可自纠正问题不应在界面里显示成红色错误。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's_recoverable_tool',
        needsGoalSelection: false,
      );
      final result = DraftGenerationResult(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        projectInfo: const <String, Object?>{},
        userPrompt: '智能开局',
        prompt: 'prompt',
        modelId: 'test-model',
        draftMarkdown: '',
        contextPack: const <String, Object?>{},
        selectedPaths: const <String>[],
        executedTools: const <Object?>[
          <String, Object?>{
            'id': 'tool_1',
            'name': 'read_project_file',
            'ok': false,
            'not_executed': true,
            'arguments': <String, Object?>{},
            'result': <String, Object?>{
              'ok': false,
              'not_executed': true,
              'error': 'read_project_file 缺少 relative_path。',
              'suggested_tool': 'list_project_files',
            },
          },
        ],
        writtenPaths: const <String>[],
        changedPaths: const <String>[],
        transcriptMessages: const <JsonMap>[],
        waitingForUserChoice: false,
        reasoningContent: '',
        stoppedByToolError: false,
        toolErrorSummary: '',
      );

      final next = service.stateWithAssistantResult(created, result);
      expect(next.entries.single.kind, ConversationEntryKind.tool);
      expect(next.entries.single.isError, isFalse);
      expect(next.entries.single.body, contains('list_project_files'));
    });

    test('pending options fallback to title and prompt aliases', () {
      // 中文注释: 这里验证 present_user_options 即使只给 title/value，也能正常长出按钮。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's_pending_alias',
        needsGoalSelection: false,
      );
      final result = DraftGenerationResult(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        projectInfo: const <String, Object?>{},
        userPrompt: '智能开局',
        prompt: 'prompt',
        modelId: 'test-model',
        draftMarkdown: '请先选一个方向。',
        contextPack: const <String, Object?>{},
        selectedPaths: const <String>[],
        executedTools: const <Object?>[
          <String, Object?>{
            'id': 'tool_1',
            'name': 'present_user_options',
            'ok': true,
            'arguments': <String, Object?>{},
            'result': <String, Object?>{
              'ok': true,
              'question': '先选一个方向',
              'options': <Object?>[
                <String, Object?>{
                  'id': 'a',
                  'title': '稳妥开局',
                  'value': '我选择稳妥开局',
                  'description': '先把基础盘稳住。',
                },
              ],
              'waiting_for_user_choice': true,
            },
          },
        ],
        writtenPaths: const <String>[],
        changedPaths: const <String>[],
        transcriptMessages: const <JsonMap>[],
        waitingForUserChoice: true,
        reasoningContent: '',
        stoppedByToolError: false,
        toolErrorSummary: '',
      );

      final next = service.stateWithAssistantResult(created, result);
      expect(next.pendingOptions, hasLength(1));
      expect(next.pendingOptions.first.label, '稳妥开局');
      expect(next.pendingOptions.first.prompt, '我选择稳妥开局');
    });

    test('streaming progress updates live assistant and pending tool entries', () {
      // 中文注释: 这里验证流式过程会把正文、思考和待执行工具即时投影到会话栏。
      final sessionService = ConversationSessionStateService();
      final streamingService = ConversationStreamingStateService(
        sessionStateService: sessionService,
      );
      final created = sessionService.createSession(
        sessionId: 's_streaming',
        needsGoalSelection: false,
      );
      final userState = sessionService.stateWithUserPrompt(created, '继续写');

      final next = streamingService.stateWithProgress(
        userState,
        const DraftGenerationProgress(
          phase: 'llm_streaming',
          roundIndex: 0,
          draftMarkdown: '正在出现的正文',
          reasoningContent: '先看规格',
          pendingToolCalls: <JsonMap>[
            <String, Object?>{
              'id': 'tool_1',
              'name': 'read_project_file',
              'arguments': <String, Object?>{
                'relative_path': 'specs/project_brief.md',
              },
            },
          ],
        ),
      );

      expect(next.entries, hasLength(3));
      expect(next.entries.last.kind, ConversationEntryKind.assistant);
      expect(next.entries.last.body, contains('正在出现'));
      expect(
        next.entries[1].body,
        contains('读取文件'),
      );
    });
  });
}
