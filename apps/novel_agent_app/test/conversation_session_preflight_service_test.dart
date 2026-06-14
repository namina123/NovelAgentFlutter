import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'package:novel_agent_app/features/workbench/application/models/conversation_session_state.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_preflight_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';

void main() {
  group('ConversationSessionPreflightService', () {
    test(
      'compacts working context before render without touching transcript',
      () {
        // 中文注释: 这里验证发送前预检会先压缩工作上下文，再把层级化压缩信息渲染给模型。
        final stateService = ConversationSessionStateService();
        final preflightService = ConversationSessionPreflightService(
          sessionStateService: stateService,
        );
        var state = stateService.createSession(
          sessionId: 'preflight_compaction',
          needsGoalSelection: false,
        );
        state = _appendRound(
          stateService,
          state,
          prompt: _longPrompt('第一轮输入'),
          reply: '第一轮回复。',
        );
        state = _appendRound(
          stateService,
          state,
          prompt: _longPrompt('第二轮输入'),
          reply: '第二轮回复。',
        );
        state = stateService.stateWithUserPrompt(state, _longPrompt('第三轮输入'));

        final preflight = preflightService.prepareForSend(
          state: state,
          runtimeProfile: <String, Object?>{
            'context_length': 220,
            'compression_context_length': 220,
            'max_output_tokens': 20,
          },
          excludeLatestUserContent: _longPrompt('第三轮输入'),
        );

        expect(preflight.didCompact, isTrue);
        expect(
          preflight.sessionState.sessionRecord['transcript_messages'],
          hasLength(5),
        );
        expect(
          preflight.sessionState.sessionRecord['working_context_messages'],
          hasLength(4),
        );
        expect(
          preflight.sessionState.sessionRecord['compaction_segments'],
          hasLength(1),
        );
        expect(preflight.sessionContextMarkdown, contains('【压缩指导】'));
        expect(preflight.sessionContextMarkdown, contains('【压缩归档】'));
        expect(preflight.sessionContextMarkdown, isNot(contains('第三轮输入')));
        expect(preflight.runtimeContinuationInstruction, isNull);
      },
    );

    test('injects runtime continuation instruction separately on retry', () {
      // 中文注释: 这里验证恢复续跑时，内部指令会单独成层，而不是混进真实用户提示词。
      final stateService = ConversationSessionStateService();
      final preflightService = ConversationSessionPreflightService(
        sessionStateService: stateService,
      );
      var state = stateService.createSession(
        sessionId: 'preflight_retry',
        needsGoalSelection: false,
      );
      state = _appendRound(
        stateService,
        state,
        prompt: '前一轮的真实用户请求',
        reply: '前一轮的助手回复。',
      );
      state = stateService.stateWithUserPrompt(state, '继续写这一段');

      final preflight = preflightService.prepareForSend(
        state: state,
        runtimeProfile: <String, Object?>{
          'context_length': 4096,
          'compression_context_length': 4096,
          'max_output_tokens': 256,
        },
        excludeLatestUserContent: '继续写这一段',
        retryLastFailure: true,
      );

      expect(preflight.didCompact, isFalse);
      expect(preflight.runtimeContinuationInstruction, isNotNull);
      expect(preflight.runtimeContinuationInstruction!.title, contains('续跑'));
      expect(preflight.sessionContextMarkdown, contains('【压缩指导】'));
      expect(preflight.sessionContextMarkdown, contains('【工作上下文】'));
      expect(preflight.sessionContextMarkdown, contains('前一轮的助手回复'));
      expect(preflight.sessionContextMarkdown, isNot(contains('继续写这一段')));
      expect(
        preflight.compactionSourceScope.allowRuntimeContinuationInstruction,
        isTrue,
      );
    });
  });
}

ConversationSessionState _appendRound(
  ConversationSessionStateService stateService,
  ConversationSessionState state, {
  required String prompt,
  required String reply,
}) {
  // 中文注释: 测试里用最小 round 组装长会话，让 preflight 能稳定触发压缩规划。
  final userState = stateService.stateWithUserPrompt(state, prompt);
  return stateService.stateWithAssistantResult(
    userState,
    _assistantResult(reply, prompt),
  );
}

DraftGenerationResult _assistantResult(String reply, String prompt) {
  // 中文注释: 这里构造一个最小可用的助手结果，保证会话状态服务能把它投影回 working context。
  return DraftGenerationResult(
    project: const ProjectDescriptor(
      id: 'demo',
      name: '示例项目',
      rootPath: 'D:/demo',
    ),
    projectInfo: const <String, Object?>{},
    userPrompt: prompt,
    prompt: prompt,
    modelId: 'test-model',
    draftMarkdown: reply,
    contextPack: const <String, Object?>{},
    selectedPaths: const <String>[],
    executedTools: const <Object?>[],
    writtenPaths: const <String>[],
    changedPaths: const <String>[],
    transcriptMessages: const <JsonMap>[],
    waitingForUserChoice: false,
    reasoningContent: '',
    stoppedByToolError: false,
    toolErrorSummary: '',
  );
}

String _longPrompt(String label) {
  // 中文注释: 通过重复长文本把上下文压力拉到可稳定触发 preflight 的区间。
  return '$label：${'为了验证发送前压缩会话上下文并分层注入内部指令。' * 12}';
}
