import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_tool_lifecycle_status.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_viewmodel_harness_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'HFVV-02 app shell harness captures pending tool and waiting-user states from a new project flow',
    () async {
      final useCase = ScriptedGenerateDraftUseCase(
        progressFrames: const <DraftGenerationProgress>[
          DraftGenerationProgress(
            phase: 'tool_round',
            roundIndex: 0,
            pendingToolCalls: <JsonMap>[
              <String, Object?>{
                'id': 'pending_research_1',
                'name': 'request_external_research',
                'arguments': <String, Object?>{'question': '补齐城市背景的可靠资料来源。'},
                'result': <String, Object?>{'question': '补齐城市背景的可靠资料来源。'},
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
                draftMarkdown: '我先把普通项目开局背景整理成一页摘要，接下来等你确认下一步。',
                contextPack: const <String, Object?>{'summary': '已整理普通项目开局背景'},
                selectedPaths: const <String>[],
                executedTools: const <Object?>[
                  <String, Object?>{
                    'id': 'tool_write_1',
                    'name': 'write_project_file',
                    'ok': true,
                    'arguments': <String, Object?>{
                      'relative_path': 'premise/opening_brief.md',
                    },
                    'result': <String, Object?>{
                      'relative_path': 'premise/opening_brief.md',
                      'changed_paths': <String>['premise/opening_brief.md'],
                    },
                  },
                  <String, Object?>{
                    'id': 'tool_research_1',
                    'name': 'request_external_research',
                    'ok': false,
                    'result': <String, Object?>{
                      'question': '补齐城市背景的可靠资料来源。',
                      'summary': '当前来源可信度不足，暂时不能直接落盘。',
                    },
                  },
                  <String, Object?>{
                    'id': 'tool_confirm_1',
                    'name': 'present_user_options',
                    'not_executed': true,
                    'result': <String, Object?>{
                      'question': '下一步你想先做什么？',
                      'options': <Object?>[
                        <String, Object?>{
                          'label': '先补背景',
                          'description': '继续整理世界观与时代背景。',
                          'prompt': '先补背景设定。',
                        },
                        <String, Object?>{
                          'label': '转入大纲',
                          'description': '开始拆第一卷的开局大纲。',
                          'prompt': '开始整理开局大纲。',
                        },
                      ],
                    },
                  },
                ],
                writtenPaths: const <String>[],
                changedPaths: const <String>[],
                transcriptMessages: const <JsonMap>[],
                waitingForUserChoice: true,
                reasoningContent: '普通项目先确认背景方向，再决定是否进入大纲。',
                stoppedByToolError: false,
                toolErrorSummary: '',
              );
            },
      );
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: useCase,
      );

      await harness.recordStep(
        stepId: 'step_001',
        label: 'launcher_ready',
        modelEvent: const <String, Object?>{
          'phase': 'initialized',
          'note': 'AppShellController 已初始化并进入无项目 guard 启动器。',
        },
      );

      await harness.createProject(title: 'HFVV-02 普通项目');
      await harness.recordStep(
        stepId: 'step_002',
        label: 'project_created',
        modelEvent: <String, Object?>{
          'phase': 'project_created',
          'project_name': harness.workbench.projectName,
          'project_type': 'novel',
        },
      );

      expect(harness.workbench.projectName, 'HFVV-02 普通项目');
      expect(harness.workbench.projectPath, isNotEmpty);
      expect(harness.resources.resourceEntries, isNotEmpty);
      expect(
        harness.controller.longTaskStationController.viewData.totalCount,
        0,
      );

      await harness.sendPrompt('先帮我整理这个普通项目的背景，再告诉我下一步选项。');
      await harness.waitUntil(
        () => harness.conversation.isGenerating,
        description: 'conversation generating state',
      );
      await harness.waitUntil(
        () => harness.conversation.conversationEntries.any(
          (entry) =>
              entry.toolLifecycleStatus ==
              ConversationToolLifecycleStatus.running,
        ),
        description: 'running tool entry during streaming',
      );
      await harness.waitUntil(
        () => harness.conversation.toolCoreStatus.contains('正在发起资料研究'),
        description: 'streaming tool status projection',
      );
      await harness.recordStep(
        stepId: 'step_003',
        label: 'pending_tool',
        modelEvent: <String, Object?>{
          'phase': 'progress',
          'user_prompt': useCase.lastUserPrompt,
          'model_id': useCase.lastModelId,
          'agent_id': ValueReaders.stringValue(useCase.lastAgent['id']),
          'selected_group_id': ValueReaders.stringValue(
            useCase.lastSelectedCollaborationGroup['id'],
          ),
        },
        toolEvents: useCase.emittedProgress.single.pendingToolCalls,
      );

      expect(harness.conversation.toolCoreStatus, contains('正在发起资料研究'));
      expect(
        harness.conversation.conversationEntries.any(
          (entry) =>
              entry.toolLifecycleStatus ==
                  ConversationToolLifecycleStatus.running &&
              entry.body.contains('正在发起资料研究'),
        ),
        isTrue,
      );

      await harness.releasePromptCompletion();
      await harness.recordStep(
        stepId: 'step_004',
        label: 'waiting_user',
        modelEvent: <String, Object?>{
          'phase': 'result',
          'user_prompt': useCase.lastUserPrompt,
          'model_id': useCase.lastModelId,
          'result_waiting_for_user_choice':
              useCase.lastResult!.waitingForUserChoice,
        },
        toolEvents: useCase.lastResult!.executedTools,
      );

      expect(harness.conversation.pendingOptions, hasLength(2));
      expect(harness.conversation.toolCoreStatus, '等待选择');
      expect(harness.workbench.generationStatus, contains('需要你先确认下一步选项'));
      expect(
        harness.conversation.conversationEntries.any(
          (entry) =>
              entry.toolLifecycleStatus ==
                  ConversationToolLifecycleStatus.completed &&
              entry.body == '已更新开局资料',
        ),
        isTrue,
      );
      expect(
        harness.conversation.conversationEntries.any(
          (entry) =>
              entry.toolLifecycleStatus ==
              ConversationToolLifecycleStatus.failed,
        ),
        isTrue,
      );
      expect(
        harness.conversation.conversationEntries.any(
          (entry) =>
              entry.toolLifecycleStatus ==
                  ConversationToolLifecycleStatus.pendingConfirmation &&
              entry.body == '需要确认',
        ),
        isTrue,
      );

      final waitingUserSnapshot = await harness.snapshot(
        stepId: 'step_004_snapshot_check',
        label: 'waiting_user_snapshot_check',
      );
      final snapshotEntries = ValueReaders.objectList(
        ValueReaders.mapValue(waitingUserSnapshot['conversation'])['entries'],
      ).map(ValueReaders.mapValue).toList(growable: false);
      final failedToolEntry = snapshotEntries.firstWhere(
        (entry) => ValueReaders.stringValue(entry['tool_lifecycle_status']) == 'failed',
      );
      expect(
        ValueReaders.stringValue(failedToolEntry['detail_title']),
        isNotEmpty,
      );
      expect(
        ValueReaders.stringValue(failedToolEntry['detail_body']),
        contains('待确认事项'),
      );

      final projectEntries = await harness.bundle.projectWorkspacePort
          .listEntries(harness.workbench.projectPath);
      expect(
        projectEntries.any(
          (entry) => ValueReaders.stringValue(
            ValueReaders.mapValue(entry)['relative_path'],
          ).contains('tracking/conversation_draft/'),
        ),
        isTrue,
      );

      await harness.writeSummary(<String, Object?>{
        'session': 'HFVV-02',
        'run_id': hfvvRunId,
        'lane_id': hfvv02LaneId,
        'test_file':
            'apps/novel_agent_app/test/hfvv_viewmodel_harness_smoke_test.dart',
        'status': 'passed',
        'assertions': <String>[
          '新项目通过 AppShellController 公共入口完成创建。',
          '流式阶段可从 ViewModel 观察到 pending tool 和 generating 状态。',
          '最终阶段可从 ViewModel 观察到 completed / failed / pendingConfirmation 三类工具状态。',
          'pendingOptions 与 toolCoreStatus=等待选择 一起证明正确停在用户确认点。',
          '项目目录存在 tracking/conversation_draft 运行记录文件，资源树与项目文件证据已落地。',
        ],
      });
    },
  );
}
