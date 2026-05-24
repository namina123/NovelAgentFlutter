import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';
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
  });
}
