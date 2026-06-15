import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_tool_lifecycle_status.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_viewmodel_harness_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'CTC-15 probe keeps controller send, retry and layered session context aligned',
    () async {
      var executionCount = 0;
      final useCase = ScriptedGenerateDraftUseCase(
        progressFrames: const <DraftGenerationProgress>[
          DraftGenerationProgress(
            phase: 'tool_round',
            roundIndex: 0,
            pendingToolCalls: <JsonMap>[
              <String, Object?>{
                'id': 'tool_1',
                'name': 'read_project_file',
                'arguments': <String, Object?>{
                  'relative_path': 'premise/project_brief.md',
                },
              },
            ],
          ),
        ],
        resultBuilder:
            ({
              required ProjectDescriptor project,
              required String userPrompt,
              required String modelId,
            }) {
              executionCount += 1;
              final sharedTools = <Object?>[
                <String, Object?>{
                  'id': 'tool_1',
                  'name': 'read_project_file',
                  'ok': true,
                  'arguments': <String, Object?>{
                    'relative_path': 'premise/project_brief.md',
                  },
                  'result': <String, Object?>{
                    'ok': true,
                    'relative_path': 'premise/project_brief.md',
                    'content': '前情摘要',
                  },
                },
              ];
              if (executionCount == 1) {
                return DraftGenerationResult(
                  project: project,
                  projectInfo: <String, Object?>{
                    'id': project.id,
                    'title': project.name,
                    'path': project.rootPath,
                    'project_type': project.projectType,
                  },
                  userPrompt: userPrompt,
                  prompt: userPrompt,
                  modelId: modelId,
                  draftMarkdown: '',
                  contextPack: const <String, Object?>{'summary': '首轮先整理前情'},
                  selectedPaths: const <String>[],
                  executedTools: sharedTools,
                  writtenPaths: const <String>[],
                  changedPaths: const <String>[],
                  transcriptMessages: const <JsonMap>[],
                  waitingForUserChoice: false,
                  reasoningContent: '先整理前情，再等用户重试。',
                  stoppedByToolError: false,
                  toolErrorSummary: '',
                  cancelledByUser: true,
                  stopPhase: DraftGenerationStopPhase.llmRound,
                  partialContentAccepted: false,
                );
              }
              return DraftGenerationResult(
                project: project,
                projectInfo: <String, Object?>{
                  'id': project.id,
                  'title': project.name,
                  'path': project.rootPath,
                  'project_type': project.projectType,
                },
                userPrompt: userPrompt,
                prompt: userPrompt,
                modelId: modelId,
                draftMarkdown: '重试后正文已经整理好。',
                contextPack: const <String, Object?>{'summary': '重试后继续推进'},
                selectedPaths: const <String>[],
                executedTools: sharedTools,
                writtenPaths: const <String>[],
                changedPaths: const <String>[],
                transcriptMessages: const <JsonMap>[],
                waitingForUserChoice: false,
                reasoningContent: '',
                stoppedByToolError: false,
                toolErrorSummary: '',
              );
            },
      );
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: useCase,
      );
      await harness.createProject(title: 'CTC-15 Probe Project');

      const prompt = '请先整理这一轮的前情，然后继续写下去。';
      await harness.sendPrompt(prompt);
      await harness.waitUntil(
        () => harness.conversation.isGenerating,
        description: 'controller send entering generation',
      );
      await harness.waitUntil(
        () => harness.conversation.conversationEntries.any(
          (entry) =>
              entry.toolLifecycleStatus ==
              ConversationToolLifecycleStatus.running,
        ),
        description: 'tool round entered from controller path',
      );
      await harness.releasePromptCompletion();
      await harness.waitUntil(
        () => harness.conversation.retryRequest != null,
        description: 'retry request from cancelled first round',
      );

      expect(useCase.lastUserPrompt, prompt);
      expect(useCase.lastUserPrompt, isNot(contains('压缩指导')));
      expect(useCase.lastSessionContext, contains('【压缩指导】'));
      expect(useCase.lastUserPrompt, isNot(contains('恢复续跑指令')));
      expect(harness.conversation.conversationContextProjection, isNotNull);
      expect(
        harness.conversation.conversationContextProjection!.headlineSummary,
        contains('完整历史'),
      );

      harness.controller.onRetryLastFailedRequested();
      await harness.waitUntil(
        () => executionCount >= 2,
        description: 'retry execution to start',
      );
      await harness.releasePromptCompletion();
      await harness.waitUntil(
        () => !harness.conversation.isGenerating,
        description: 'retry completion',
      );

      expect(useCase.lastUserPrompt, prompt);
      expect(useCase.lastSessionContext, contains('【压缩指导】'));
      expect(useCase.lastSessionContext, contains('恢复续跑指令'));
      expect(useCase.lastUserPrompt, isNot(contains('恢复续跑指令')));
      expect(harness.conversation.conversationContextProjection, isNotNull);
      expect(
        harness.conversation.conversationContextProjection!.pressureSummary,
        contains('安全'),
      );
      expect(
        harness
            .conversation
            .conversationContextProjection!
            .workingWindowSummary,
        isNotEmpty,
      );
    },
  );
}
