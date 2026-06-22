import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/workbench/application/controllers/workbench_conversation_controller.dart';
import 'package:novel_agent_app/features/workbench/application/controllers/workbench_workspace_controller.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_opening_launch_bridge_service.dart';
import 'package:novel_agent_app/features/workbench/application/models/open_document_state.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_member_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_primary_agent_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/models/workbench_conversation_runtime_state.dart';
import 'package:novel_agent_app/features/workbench/application/models/workbench_project_runtime_state.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_guide_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_opening_panel_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_streaming_state_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_user_visible_text_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_agent_group_binding_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_session_projection_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_primary_action_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('WorkbenchConversationController conversation agent selection', () {
    test(
      'uses the newly selected conversation agent for execution profile and request',
      () async {
        final harness = _ConversationControllerHarness();

        harness.controller.onConversationAgentSelected('reviewer');
        expect(harness.workbench.agentSelector.currentAgentId, 'reviewer');

        await harness.controller.onSendRequested('请帮我审一下这一段。');

        expect(harness.modelExecutionProfileService.lastAgentId, 'reviewer');
        expect(harness.generateDraftUseCase.lastAgentId, 'reviewer');
      },
    );

    test(
      'passes the current opening collaboration group into ordinary conversation runtime',
      () async {
        final harness = _ConversationControllerHarness();

        await harness.controller.onSendRequested('继续推进正文。');

        expect(
          ValueReaders.stringValue(
            harness.generateDraftUseCase.lastSelectedCollaborationGroup['id'],
          ),
          'starter_novel_writer_room',
        );
        expect(
          ValueReaders.stringList(
            harness
                .generateDraftUseCase
                .lastSelectedCollaborationGroup['agents'],
          ),
          containsAll(<String>['writer', 'reviewer']),
        );
      },
    );

    test('launch long task sends an agent-led opening prompt', () async {
      final harness = _ConversationControllerHarness(
        initialWorkbench: WorkbenchViewData.initial().copyWith(
          primaryActions: const <PrimaryActionViewData>[
            PrimaryActionViewData(
              id: 'opening.launch_long_task',
              title: '启动长任务',
              description: '继续补齐或启动当前长任务。',
              commandId: 'opening.launch_long_task',
            ),
          ],
        ),
        project: const ProjectDescriptor(
          id: 'long_project',
          name: '长篇项目',
          rootPath: 'D:/Projects/long_project',
          projectType: 'long_novel',
        ),
        runtimeProfile: const ProjectRuntimeProfile(
          projectType: 'long_novel',
          runtimeBaselineId: '',
          runtimeMode: '',
          initialRunOptions: <String, Object?>{},
        ),
        openingProjection: _longTaskProjection(),
      );

      await harness.controller.onPrimaryActionRequested(
        'opening.launch_long_task',
      );

      expect(harness.runtimeState.guideScope, 'long_task_modes');
      expect(harness.generateDraftUseCase.lastUserPrompt, isEmpty);
    });

    test(
      'launch long task directly starts the formal run when opening is already ready',
      () async {
        final workflowRuntimeService = _RecordingWorkflowRuntimeService();
        final harness = _ConversationControllerHarness(
          initialWorkbench: WorkbenchViewData.initial().copyWith(
            primaryActions: const <PrimaryActionViewData>[
              PrimaryActionViewData(
                id: 'opening.launch_long_task',
                title: '启动长任务',
                description: '继续补齐或启动当前长任务。',
                commandId: 'opening.launch_long_task',
              ),
            ],
          ),
          project: const ProjectDescriptor(
            id: 'long_project',
            name: '长篇项目',
            rootPath: 'D:/Projects/long_project',
            projectType: 'long_novel',
          ),
          runtimeProfile: const ProjectRuntimeProfile(
            projectType: 'long_novel',
            runtimeBaselineId: 'continuous_autonomous',
            runtimeMode: 'seed_autopilot_novel',
            initialRunOptions: <String, Object?>{},
          ),
          openingProjection: _readyLongTaskOpeningProjection(),
          modeGuidanceState: _readyModeGuidanceState(
            ModeGuidanceTransitionService(),
            'seed_autopilot_novel',
          ),
          workflowRuntimeService: workflowRuntimeService,
        );

        await harness.controller.onPrimaryActionRequested(
          'opening.launch_long_task',
        );

        expect(workflowRuntimeService.createLongTaskWorkflowCallCount, 1);
        expect(workflowRuntimeService.runWorkflowTaskQueueCallCount, 1);
        expect(workflowRuntimeService.lastMode, isNotEmpty);
        expect(harness.generateDraftUseCase.lastUserPrompt, isEmpty);
      },
    );

    test(
      'preflights and compacts session context before the model request is built',
      () async {
        final harness = _ConversationControllerHarness(
          modelContextWindowTokens: 220,
          maxOutputTokens: 20,
          compressionContextLength: 220,
        );

        await harness.controller.onSendRequested(
          '第一轮：${'为了验证发送前压缩会话上下文与分层注入。' * 18}',
        );
        await harness.controller.onSendRequested(
          '第二轮：${'为了继续累积足够长的工作上下文。' * 18}',
        );
        final uniquePrompt =
            '第三轮：${'本轮应该先触发 preflight compact，再把内部指令单独成层。' * 18}';
        await harness.controller.onSendRequested(uniquePrompt);

        expect(
          harness.generateDraftUseCase.lastSessionContext,
          contains('【压缩指导】'),
        );
        expect(
          harness.generateDraftUseCase.lastSessionContext,
          contains('【压缩归档】'),
        );
        expect(
          harness.generateDraftUseCase.lastSessionContext,
          isNot(contains('【工作上下文】')),
        );
        expect(
          harness.generateDraftUseCase.lastSessionPromptContext.historyMessages,
          isNotEmpty,
        );
        expect(
          harness.generateDraftUseCase.lastSessionPromptContext.historyMessages
              .map((message) => ValueReaders.stringValue(message['content']))
              .any((content) => content.contains('第二轮：')),
          isTrue,
        );
        expect(
          harness.generateDraftUseCase.lastSessionContext,
          isNot(contains(uniquePrompt)),
        );
      },
    );

    test(
      'projects two child collaboration runs and keeps degraded child recoverable in GUI state',
      () async {
        final harness = _ConversationControllerHarness(
          generateDraftUseCase: _RecordingGenerateDraftUseCase(
            scriptedResult: DraftGenerationResult(
              project: _project(),
              projectInfo: <String, Object?>{
                'id': _project().id,
                'title': _project().name,
                'path': _project().rootPath,
                'project_type': _project().projectType,
              },
              userPrompt: '继续推进正文。',
              prompt: '继续推进正文。',
              modelId: 'selected-model',
              draftMarkdown: '主智能体已综合专家意见完成当前段落。',
              contextPack: const <String, Object?>{},
              selectedPaths: const <String>[],
              executedTools: const <Object?>[
                <String, Object?>{
                  'id': 'tool_sub_1',
                  'name': 'call_sub_agent',
                  'ok': true,
                  'result': <String, Object?>{
                    'ok': true,
                    'sub_agent_run_id': 'sub_run_1',
                    'sub_session_id': 'sub_session_1',
                    'agent_id': 'reviewer',
                    'agent_name': '审稿员',
                    'task': '审一下第一章冲突是否立得住。',
                    'summary': '已给出一条主修建议。',
                    'result_markdown': '建议把冲突前置到第一段。',
                    'reasoning_content': '先看冲突是否太晚出现。',
                    'tool_count': 1,
                    'sub_agent_events': <Object?>[
                      <String, Object?>{'summary': '接收任务。'},
                      <String, Object?>{'summary': '返回审稿建议。'},
                    ],
                    'collaboration_result_package': <String, Object?>{
                      'package_id': 'pkg_1',
                      'execution_package_id': 'exec_1',
                      'child_run_package_id': 'child_1',
                      'agent_id': 'reviewer',
                      'agent_name': '审稿员',
                      'status': 'success',
                      'used_tool_count': 1,
                      'result_summary': '已给出一条主修建议。',
                      'result_markdown': '建议把冲突前置到第一段。',
                      'merge_contract': <String, Object?>{
                        'merge_mode': 'main_agent_merges',
                        'parent_review_required': true,
                        'allows_direct_delivery': false,
                        'accepted_result_types': <Object?>['suggestion'],
                      },
                      'conflicts': <Object?>[
                        <String, Object?>{
                          'conflict_id': 'conflict_1',
                          'subject': '第一章冲突露出',
                          'agent_id': 'reviewer',
                          'agent_name': '审稿员',
                          'risk': 'low',
                          'suggestion': '建议把冲突前置到第一段。',
                          'adoption_hint': '先由主智能体复核后再吸收。',
                          'confidence': 0.84,
                          'evidence': <Object?>[
                            <String, Object?>{
                              'summary': '第二段之前还没有明确外部阻力。',
                              'reference': 'chapter_01#p1',
                            },
                          ],
                        },
                      ],
                      'arbitration_result': <String, Object?>{
                        'arbitration_id': 'arb_1',
                        'status': 'auto_resolved',
                        'highest_risk': 'low',
                        'selected_conflict_id': 'conflict_1',
                        'summary': '主链可以先复核这条建议，再决定是否吸收。',
                        'accepted_conflict_ids': <Object?>['conflict_1'],
                      },
                    },
                  },
                },
                <String, Object?>{
                  'id': 'tool_sub_2',
                  'name': 'call_sub_agent',
                  'ok': false,
                  'result': <String, Object?>{
                    'ok': false,
                    'sub_agent_run_id': 'sub_run_2',
                    'sub_session_id': 'sub_session_2',
                    'agent_id': 'evidence_reader',
                    'agent_name': '资料考据员',
                    'task': '补齐时代背景证据。',
                    'summary': '子智能体模型失败，建议退回单主链继续：上下文不足。',
                    'failure_disposition': 'fallback_single_main',
                    'tool_count': 0,
                    'sub_agent_events': <Object?>[
                      <String, Object?>{'summary': '接收任务。'},
                      <String, Object?>{'summary': '转回单主链继续。'},
                    ],
                    'collaboration_result_package': <String, Object?>{
                      'package_id': 'pkg_2',
                      'execution_package_id': 'exec_2',
                      'child_run_package_id': 'child_2',
                      'agent_id': 'evidence_reader',
                      'agent_name': '资料考据员',
                      'status': 'failed',
                      'retryable': false,
                      'used_tool_count': 0,
                      'merge_contract': <String, Object?>{
                        'merge_mode': 'main_agent_merges',
                        'parent_review_required': true,
                        'allows_direct_delivery': false,
                        'accepted_result_types': <Object?>['suggestion'],
                      },
                      'metadata': <String, Object?>{
                        'failure_disposition': 'fallback_single_main',
                      },
                    },
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
            ),
          ),
        );

        await harness.controller.onSendRequested('继续推进正文。');

        expect(
          ValueReaders.stringValue(
            harness.generateDraftUseCase.lastSelectedCollaborationGroup['id'],
          ),
          'starter_novel_writer_room',
        );
        expect(harness.workbench.subAgentRuns, hasLength(2));

        final reviewerRun = harness.workbench.subAgentRuns.singleWhere(
          (run) => run.agentName == '审稿员',
        );
        expect(reviewerRun.expertOpinion, contains('建议把冲突前置到第一段'));
        expect(reviewerRun.evidenceItems.single, contains('chapter_01#p1'));
        expect(reviewerRun.adoptionSummary, contains('主链可以先复核这条建议'));
        expect(
          reviewerRun.diagnosticItems.join('\n'),
          contains('agent_id: reviewer'),
        );

        final degradedRun = harness.workbench.subAgentRuns.singleWhere(
          (run) => run.agentName == '资料考据员',
        );
        expect(degradedRun.status, '已降级返回');
        expect(degradedRun.degradationSummary, contains('已退回单主链继续'));
      },
    );

    test(
      'falls back to primary agent when selected agent is no longer valid',
      () async {
        final harness = _ConversationControllerHarness(
          initialWorkbench: WorkbenchViewData.initial().copyWith(
            agentSelector: const ConversationAgentSelectorViewData(
              currentAgentLabel: '过期智能体',
              currentAgentId: 'ghost',
              currentAgentDescription: '旧会话选择',
              agentOptions: <SelectorOptionViewData>[],
              canSwitchAgent: false,
            ),
          ),
        );

        await harness.controller.onSendRequested('继续推进正文。');

        expect(harness.modelExecutionProfileService.lastAgentId, 'writer');
        expect(harness.generateDraftUseCase.lastAgentId, 'writer');
      },
    );

    test('writes reasoning toggle back to shared model settings', () async {
      final harness = _ConversationControllerHarness();

      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(
            harness.settings.extraSettings['model_settings'],
          )['thinking_enabled'],
        ),
        isFalse,
      );

      harness.controller.onReasoningToggleChanged(true);

      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(
            harness.settings.extraSettings['model_settings'],
          )['thinking_enabled'],
        ),
        isTrue,
      );

      harness.controller.onReasoningToggleChanged(false);

      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(
            harness.settings.extraSettings['model_settings'],
          )['thinking_enabled'],
        ),
        isFalse,
      );
    });

    test(
      'optimize request announces the current user-facing guidance without roadmap language',
      () async {
        final harness = _ConversationControllerHarness();

        harness.controller.onOptimizeRequested();

        expect(harness.lastAnnouncement, '直接发送自然语言需求即可；需要优化时可以在当前会话里继续调整。');
      },
    );

    test(
      'injects bridged execution constraints into ordinary conversation generation',
      () async {
        final harness = _ConversationControllerHarness(
          conversationDraftRuntimeService:
              _FakeProjectConversationDraftRuntimeService(
                preparation: const ProjectConversationDraftRuntimePreparation(
                  runId: 'conversation_constraint_run',
                  taskType: 'chapter',
                  activationReportPath:
                      'tracking/conversation_draft/conversation_constraint_run.activation_report.json',
                  activationReport: <String, Object?>{
                    'summary':
                        'selected profiles 1, claims 0, constraints 1, files 1.',
                  },
                  sessionContextMarkdown:
                      '## Execution Constraints\n- 字数约束：目标约 2400 字',
                  exposedToolIds: <String>['submit_chapter_delivery'],
                  executionConstraints: <String, Object?>{
                    'session_context_markdown':
                        '## Execution Constraints\n- 字数约束：目标约 2400 字',
                    'chapter_length_metadata': <String, Object?>{
                      'chapter_length_profile': <String, Object?>{
                        'enabled': true,
                        'target_length': 2400,
                        'preferred_min': 2000,
                        'preferred_max': 2800,
                      },
                    },
                    'expression_constraint_profiles': <Object?>[
                      <String, Object?>{
                        'id': 'de_ai',
                        'display_name': '去 AI 风',
                        'summary': '降低模板化表达。',
                        'kind': 'natural_expression',
                        'rules': <Object?>['减少总结句。'],
                      },
                    ],
                    'project_expression_constraint_bindings': <Object?>[
                      <String, Object?>{
                        'id': 'binding_1',
                        'profile_id': 'de_ai',
                        'default_for_project': true,
                      },
                    ],
                  },
                ),
              ),
        );

        await harness.controller.onSendRequested('继续写第一章。');

        expect(
          harness.generateDraftUseCase.lastSessionContext,
          contains('字数约束'),
        );
        expect(
          harness.generateDraftUseCase.lastExpressionConstraintProfiles.length,
          1,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              harness
                  .generateDraftUseCase
                  .lastExpressionConstraintProfiles
                  .first,
            )['id'],
          ),
          'de_ai',
        );
        expect(
          harness
              .generateDraftUseCase
              .lastProjectExpressionConstraintBindings
              .length,
          1,
        );
        final chapterLengthProfile = ValueReaders.mapValue(
          ValueReaders.mapValue(
            harness
                .generateDraftUseCase
                .lastWritingExecutionConstraints['chapter_length_metadata'],
          )['chapter_length_profile'],
        );
        expect(
          ValueReaders.intValue(chapterLengthProfile['preferred_min']),
          2000,
        );
        expect(
          ValueReaders.intValue(chapterLengthProfile['preferred_max']),
          2800,
        );
      },
    );

    test(
      'injects activation report context and submit_chapter_delivery tool priority for ordinary chapter turns',
      () async {
        final runtimeService = _FakeProjectConversationDraftRuntimeService(
          preparation: const ProjectConversationDraftRuntimePreparation(
            runId: 'conversation_run_1',
            taskType: 'chapter',
            activationReportPath:
                'tracking/conversation_draft/conversation_run_1.activation_report.json',
            activationReport: <String, Object?>{
              'summary':
                  'selected profiles 1, claims 0, constraints 1, files 2.',
            },
            sessionContextMarkdown:
                '## Activation Report\n- summary: selected profiles 1, claims 0, constraints 1, files 2.',
            exposedToolIds: <String>[
              'submit_chapter_delivery',
              'read_project_file',
              'write_project_file',
            ],
          ),
        );
        final harness = _ConversationControllerHarness(
          conversationDraftRuntimeService: runtimeService,
        );

        await harness.controller.onSendRequested('继续写第一章。');

        expect(
          harness.generateDraftUseCase.lastSessionContext,
          contains('## Activation Report'),
        );
        expect(
          harness.generateDraftUseCase.lastExposedToolIds.first,
          'submit_chapter_delivery',
        );
        expect(runtimeService.prepareCallCount, 1);
        expect(runtimeService.finalizeCallCount, 1);
      },
    );

    test(
      'passes full user prompt into ordinary chapter runtime preparation instead of truncated title',
      () async {
        final runtimeService = _FakeProjectConversationDraftRuntimeService(
          preparation: const ProjectConversationDraftRuntimePreparation(
            runId: 'conversation_run_chapter_hint',
            taskType: 'chapter',
            activationReportPath:
                'tracking/conversation_draft/conversation_run_chapter_hint.activation_report.json',
            activationReport: <String, Object?>{
              'summary':
                  'selected profiles 0, claims 0, constraints 0, files 0.',
            },
            sessionContextMarkdown: '## Activation Report',
            exposedToolIds: <String>['submit_chapter_delivery'],
          ),
        );
        final harness = _ConversationControllerHarness(
          conversationDraftRuntimeService: runtimeService,
        );
        const prompt = '先承接前文已经落定的门后回应，不要回退铺垫，直接把第三章写出来。';

        await harness.controller.onSendRequested(prompt);

        expect(runtimeService.lastChapterLabelHint, prompt);
      },
    );

    test(
      'routes premise-side concept planning prompts into planning runtime instead of chapter runtime',
      () async {
        final runtimeService = _FakeProjectConversationDraftRuntimeService(
          preparation: const ProjectConversationDraftRuntimePreparation(
            runId: 'conversation_run_planning',
            taskType: 'planning',
            activationReportPath:
                'tracking/conversation_draft/conversation_run_planning.activation_report.json',
            activationReport: <String, Object?>{
              'summary':
                  'selected profiles 0, claims 0, constraints 0, files 1.',
            },
            sessionContextMarkdown: '## Activation Report',
            exposedToolIds: <String>['read_project_file', 'write_project_file'],
          ),
        );
        final harness = _ConversationControllerHarness(
          conversationDraftRuntimeService: runtimeService,
        );
        harness.workspaceController.openOrActivateDocument(
          relativePath: 'premise/project_brief.md',
          title: 'project_brief.md',
          content: '# brief',
        );

        await harness.controller.onSendRequested('先定概念级能力体系，收束世界规则和角色边界。');

        expect(runtimeService.lastTaskType, 'planning');
      },
    );

    test(
      'routes confirmed personality-and-style user option into planning runtime instead of chapter runtime',
      () async {
        final runtimeService = _FakeProjectConversationDraftRuntimeService(
          preparation: const ProjectConversationDraftRuntimePreparation(
            runId: 'conversation_run_option_planning',
            taskType: 'planning',
            activationReportPath:
                'tracking/conversation_draft/conversation_run_option_planning.activation_report.json',
            activationReport: <String, Object?>{
              'summary':
                  'selected profiles 0, claims 0, constraints 0, files 0.',
            },
            sessionContextMarkdown: '## Activation Report',
            exposedToolIds: <String>['read_project_file', 'write_project_file'],
          ),
        );
        final harness = _ConversationControllerHarness(
          conversationDraftRuntimeService: runtimeService,
        );

        await harness.controller.onUserOptionSelected(
          const UserOptionViewData(
            label: '主角性格与处事风格',
            description: '确认主角的性格底色、处事方式与语言质地。',
            prompt: '',
            sourceQuestion: '你想先定哪部分设定？',
            allOptions: <Map<String, Object?>>[
              <String, Object?>{
                'label': '主角性格与处事风格',
                'description': '确认主角的性格底色、处事方式与语言质地。',
              },
              <String, Object?>{'label': '第一章正式正文', 'description': '直接进入章节写作。'},
            ],
          ),
        );

        expect(runtimeService.lastTaskType, 'planning');
      },
    );

    test(
      'passes host information permission context into ordinary conversation factory',
      () async {
        final harness = _ConversationControllerHarness(
          initialSettings: _buildSettings().copyWith(
            permissionSettings: const <String, Object?>{
              'mode': 'safe',
              'allow_network': false,
            },
          ),
        );

        await harness.controller.onSendRequested('继续写第一章。');

        expect(harness.lastHostInformationPermissionContext, isNotNull);
        expect(
          harness.lastHostInformationPermissionContext!.permissionMode,
          HostInformationPermissionModes.safe,
        );
        expect(
          harness.lastHostInformationPermissionContext!.allowNetwork,
          isFalse,
        );
        expect(harness.lastHostToolPermissionContext, isNotNull);
        expect(
          harness.lastHostToolPermissionContext!.permissionMode,
          HostToolPermissionModes.safe,
        );
        expect(
          harness.lastHostToolPermissionContext!.allowFormalDelivery,
          isTrue,
        );
      },
    );

    test(
      'restores persisted ordinary conversation permission approvals after project reload',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'workbench_conversation_permission_restore_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });
        final workspacePort = LocalProjectWorkspacePort();
        final toolHostPort = ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        );
        final project = ProjectDescriptor(
          id: 'permission_restore_project',
          name: '权限恢复测试项目',
          rootPath: tempDirectory.path,
          projectType: 'novel',
        );
        final harness = _ConversationControllerHarness(
          project: project,
          workspacePort: workspacePort,
          toolHostPort: toolHostPort,
          generateDraftUseCase: _RecordingGenerateDraftUseCase(
            scriptedResult: DraftGenerationResult(
              project: project,
              projectInfo: <String, Object?>{
                'id': project.id,
                'title': project.name,
                'path': project.rootPath,
                'project_type': project.projectType,
              },
              userPrompt: '请先申请联网权限。',
              prompt: '请先申请联网权限。',
              modelId: 'selected-model',
              draftMarkdown: '',
              contextPack: const <String, Object?>{},
              selectedPaths: const <String>[],
              executedTools: const <Object?>[
                <String, Object?>{
                  'call_id': 'tool_network_1',
                  'name': 'request_gateway_tool',
                  'result': <String, Object?>{
                    'ok': true,
                    'waiting_for_user_choice': true,
                    'question': '需要临时联网读取资料，是否允许？',
                    'options': <Object?>[
                      <String, Object?>{
                        'id': 'allow_once',
                        'label': '允许一次',
                        'prompt': '这次允许联网读取资料。',
                      },
                      <String, Object?>{
                        'id': 'deny_and_continue',
                        'label': '拒绝并继续',
                        'prompt': '不要联网，继续当前任务。',
                      },
                    ],
                    'permission_decision': <String, Object?>{
                      'state': 'waiting_user_confirmation',
                    },
                    'permission_capability': 'network',
                    'permission_context': <String, Object?>{
                      'allow_network': false,
                    },
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
            ),
          ),
        );

        await harness.controller.onSendRequested('请先申请联网权限。');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final originalSessionId = harness.runtimeState.activeSessionId;
        expect(originalSessionId, isNotEmpty);
        expect(harness.runtimeState.sessions, hasLength(1));
        expect(
          harness.runtimeState.sessions.single.pendingOptions.map(
            (option) => option.label,
          ),
          containsAll(<String>['允许一次', '拒绝并继续']),
        );

        harness.controller.resetRuntimeState();
        await harness.controller.restoreProjectSessions(project);

        expect(harness.runtimeState.activeSessionId, originalSessionId);
        expect(harness.runtimeState.sessions, hasLength(1));
        final restoredSession = harness.runtimeState.sessions.single;
        expect(restoredSession.pendingOptions, hasLength(2));
        expect(
          restoredSession.pendingOptions.map((option) => option.label).toList(),
          containsAll(<String>['允许一次', '拒绝并继续']),
        );
        expect(
          restoredSession.pendingOptions.first.permissionApprovalId,
          isNotEmpty,
        );
        expect(
          restoredSession.pendingOptions.first.permissionApprovalOptionId,
          isNotEmpty,
        );
      },
    );

    test(
      'projects ordinary runtime information summary back into workbench status',
      () async {
        final runtimeService = _FakeProjectConversationDraftRuntimeService(
          preparation: const ProjectConversationDraftRuntimePreparation(
            runId: 'conversation_run_information',
            taskType: 'chapter',
            activationReportPath:
                'tracking/conversation_draft/conversation_run_information.activation_report.json',
            activationReport: <String, Object?>{
              'summary':
                  'selected profiles 1, claims 0, constraints 0, files 1.',
            },
            sessionContextMarkdown: '## Activation Report',
            exposedToolIds: <String>[
              'submit_chapter_delivery',
              NarrativeDomainToolNames.requestExternalResearch,
            ],
          ),
          finalization: const ProjectConversationDraftRuntimeArtifacts(
            informationStatus: 'executed_research',
            informationSummary: '已自动补齐回京礼制资料。information 改动 3 项。',
            informationChangedPaths: <String>[
              '.novel_agent/information/research_requests/research_request_1.json',
              '.novel_agent/information/research_notes/gateway_1.json',
              'research/研究摘要.md',
            ],
          ),
        );
        final harness = _ConversationControllerHarness(
          conversationDraftRuntimeService: runtimeService,
        );

        await harness.controller.onSendRequested('继续写第一章。');

        expect(harness.workbench.toolCoreStatus, contains('资料研究已执行'));
        expect(harness.workbench.contextSummary, contains('已自动补齐回京礼制资料'));
        expect(harness.workbench.generationStatus, contains('信息状态'));
      },
    );

    test(
      'prefers saved chapter status when ordinary generation salvages after tool error',
      () async {
        final runtimeService = _FakeProjectConversationDraftRuntimeService(
          preparation: const ProjectConversationDraftRuntimePreparation(
            runId: 'conversation_run_2',
            taskType: 'chapter',
            activationReportPath:
                'tracking/conversation_draft/conversation_run_2.activation_report.json',
            activationReport: <String, Object?>{
              'summary':
                  'selected profiles 1, claims 0, constraints 1, files 2.',
            },
            sessionContextMarkdown: '## Activation Report',
            exposedToolIds: <String>[
              'submit_chapter_delivery',
              'write_project_file',
            ],
          ),
          finalization: const ProjectConversationDraftRuntimeArtifacts(
            outputPath: 'chapters/第01章.md',
          ),
        );
        final harness = _ConversationControllerHarness(
          conversationDraftRuntimeService: runtimeService,
          generateDraftUseCase: _RecordingGenerateDraftUseCase(
            scriptedResult: DraftGenerationResult(
              project: _project(),
              projectInfo: <String, Object?>{
                'id': _project().id,
                'title': _project().name,
                'path': _project().rootPath,
                'project_type': _project().projectType,
              },
              userPrompt: '继续写第一章。',
              prompt: '继续写第一章。',
              modelId: 'selected-model',
              draftMarkdown: '# 第01章\n\n测试输出',
              contextPack: const <String, Object?>{},
              selectedPaths: const <String>[],
              executedTools: const <Object?>[],
              writtenPaths: const <String>[],
              changedPaths: const <String>[],
              transcriptMessages: const <JsonMap>[],
              waitingForUserChoice: false,
              reasoningContent: '',
              stoppedByToolError: true,
              toolErrorSummary: 'submit_chapter_delivery：领域工具参数不合法。',
            ),
          ),
        );

        await harness.controller.onSendRequested('继续写第一章。');

        expect(
          harness.workbench.generationStatus,
          '工具执行失败：submit_chapter_delivery：领域工具参数不合法。',
        );
      },
    );

    test(
      'autosave fallback stages the active chapter document without creating a project file',
      () async {
        final workspacePort = _RecordingProjectWorkspacePort(
          initialFiles: <String, String>{'chapters/chapter_01.md': '旧内容'},
        );
        final harness = _ConversationControllerHarness(
          workspacePort: workspacePort,
          initialSettings: _buildSettings().copyWith(autoSaveDrafts: true),
          generateDraftUseCase: _RecordingGenerateDraftUseCase(
            scriptedResult: DraftGenerationResult(
              project: _project(),
              projectInfo: <String, Object?>{
                'id': _project().id,
                'title': _project().name,
                'path': _project().rootPath,
                'project_type': _project().projectType,
              },
              userPrompt: '继续写第一章。',
              prompt: '继续写第一章。',
              modelId: 'selected-model',
              draftMarkdown: '''
雨下得很密，像有人把整座城的光都揉进了水里。

林述站在桥边，没有立刻往前走。他听见远处列车的轰鸣，又听见脚下河水撞向护栏的碎响。

这一夜像是某种漫长的前奏，而他知道，自己已经没有回头的余地。
''',
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
            ),
          ),
        );
        harness.workspaceController.openOrActivateDocument(
          relativePath: 'chapters/chapter_01.md',
          title: 'chapter_01.md',
          content: '旧内容',
        );
        harness._workbench = harness.workspaceController.applyWorkbenchState(
          harness._workbench,
        );

        await harness.controller.onSendRequested('继续写第一章。');

        expect(workspacePort.lastWriteRelativePath, isEmpty);
        expect(
          workspacePort.files.keys,
          isNot(contains('chapters/chapter_02.md')),
        );
        expect(workspacePort.files['chapters/chapter_01.md'], '旧内容');
        expect(harness.workbench.activeDocumentBody, contains('雨下得很密'));
        expect(harness.workbench.activeDocumentDirty, isTrue);
        expect(harness.workbench.generationStatus, contains('已暂存到当前文档草稿'));
      },
    );
  });
}

class _ConversationControllerHarness {
  _ConversationControllerHarness({
    WorkbenchViewData? initialWorkbench,
    AppSettings? initialSettings,
    ProjectConversationDraftRuntimeService? conversationDraftRuntimeService,
    ProjectDraftExecutionConstraintRuntimeService?
    draftExecutionConstraintRuntimeService,
    ProjectWorkflowRuntimeService? workflowRuntimeService,
    _RecordingGenerateDraftUseCase? generateDraftUseCase,
    ProjectDescriptor? project,
    ProjectRuntimeProfile? runtimeProfile,
    OpeningSessionProjection? openingProjection,
    ModeGuidanceState? modeGuidanceState,
    int modelContextWindowTokens = 100000,
    int maxOutputTokens = 4096,
    int compressionContextLength = 80000,
    ProjectWorkspacePort? workspacePort,
    ProjectToolHostPort? toolHostPort,
  }) : _settings = initialSettings ?? _buildSettings(),
       _workbench = initialWorkbench ?? WorkbenchViewData.initial(),
       _projectState = WorkbenchProjectRuntimeState(
         currentProject: project ?? _project(),
         currentRuntimeProfile:
             runtimeProfile ??
             const ProjectRuntimeProfile(
               projectType: 'novel',
               runtimeBaselineId: '',
               runtimeMode: '',
               initialRunOptions: <String, Object?>{},
             ),
         openDocuments: const <OpenDocumentState>[],
       ),
       _runtimeState = WorkbenchConversationRuntimeState(
         openingProjection: openingProjection ?? _projection(),
       ),
       generateDraftUseCase =
           generateDraftUseCase ?? _RecordingGenerateDraftUseCase(),
       modelExecutionProfileService = _RecordingModelExecutionProfileService(
         modelContextWindowTokens: modelContextWindowTokens,
         maxOutputTokens: maxOutputTokens,
         compressionContextLength: compressionContextLength,
       ) {
    final effectiveWorkspacePort = workspacePort ?? _NoopProjectWorkspacePort();
    final effectiveToolHostPort =
        toolHostPort ??
        (effectiveWorkspacePort is LocalProjectWorkspacePort
            ? ProjectWorkspaceToolHostAdapter(
                workspacePort: effectiveWorkspacePort,
                fileMutationAdapter: LocalProjectFileMutationAdapter(),
              )
            : _NoopProjectToolHostPort());
    workspaceController = WorkbenchWorkspaceController(
      loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
        projectRepository: _NoopProjectRepository(),
        projectWorkspacePort: effectiveWorkspacePort,
      ),
      readProjectFileUseCase: ReadProjectFileUseCase(effectiveWorkspacePort),
      showProjectRagAssets: () async {},
      saveDraftUseCase: SaveDraftUseCase(
        projectWorkspacePort: effectiveWorkspacePort,
      ),
      createProjectEntryUseCase: CreateProjectEntryUseCase(
        projectToolHostPort: effectiveToolHostPort,
      ),
      importProjectFilesUseCase: ImportProjectFilesUseCase(
        projectToolHostPort: effectiveToolHostPort,
        sourceImportDiscoveryPort: const SourceImportDiscoveryService(),
      ),
      updateProjectManifestUseCase: UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: effectiveWorkspacePort,
        ),
      ),
      projectToolHostPort: effectiveToolHostPort,
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: effectiveWorkspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: effectiveWorkspacePort,
          ),
      generateDraftUseCaseFactory: (_, _) => this.generateDraftUseCase,
      longTaskSupervisor: _NoopLongTaskSupervisor(),
      reviewReportService: _NoopProjectReviewReportService(),
      projectRuntimeProfileRepository: _NoopProjectRuntimeProfileRepository(),
      readProjectState: () => _projectState,
      writeProjectState: (next) {
        _projectState = next;
      },
      resetConversationRuntimeState: () {},
      restoreConversationRuntimeState: (_) async {},
      readWorkbench: () => _workbench,
      mutateWorkbench: (updater) {
        _workbench = updater(_workbench);
      },
      applyConversationState: (base) => base,
      readSettings: () => _settings,
      saveSettingsSilently: (next) async {
        _settings = next;
      },
      refreshSettingsViewData: () {},
      refreshAgentEcosystem: () async {},
      refreshActiveDestinationAfterProjectLoad: () async {},
      modelOptionsBuilder: (_) => const <SelectorOptionViewData>[],
      readProjectAgentGroupWorkspaceViewData: () => null,
      selectProjectAgentGroup: (_) async => null,
      showSettings: () async {},
      showAgentEcosystem: () async {},
      showLongTaskStation: () async {},
      showInspirationWorkbench: () async {},
      showPromptTemplates: () async {},
      showProjectAssets: () async {},
      showCurrentAgentSkillLoadout: (_) async {},
      showCurrentAgentExpressionConstraints: (_) async {},
      announce: (_) {},
    );

    final projectionService = _StaticOpeningSessionProjectionService(
      projection: openingProjection ?? _projection(),
    );
    final modeGuidanceStatePort = _MemoryModeGuidanceStatePort(
      initialState: modeGuidanceState,
    );
    final effectiveWorkflowRuntimeService =
        workflowRuntimeService ??
        ProjectWorkflowRuntimeService(
          taskRepository: ProjectTaskRepository(
            workspacePort: effectiveWorkspacePort,
          ),
          promptTemplateService: ProjectPromptTemplateService(
            workspacePort: effectiveWorkspacePort,
          ),
          generateDraftUseCaseFactory: (_, _) => this.generateDraftUseCase,
        );
    controller = WorkbenchConversationController(
      saveDraftUseCase: SaveDraftUseCase(
        projectWorkspacePort: effectiveWorkspacePort,
      ),
      generateDraftUseCaseFactory: (_, _) => this.generateDraftUseCase,
      hostAwareGenerateDraftUseCaseFactory:
          (
            _,
            _, {
            hostInformationPermissionContext,
            hostToolPermissionContext,
          }) {
            lastHostInformationPermissionContext =
                hostInformationPermissionContext;
            lastHostToolPermissionContext = hostToolPermissionContext;
            return this.generateDraftUseCase;
          },
      modelExecutionProfileService: modelExecutionProfileService,
      conversationSessionStateService: ConversationSessionStateService(),
      projectSessionWorkspaceService: ProjectSessionWorkspaceService(
        hostPort: effectiveToolHostPort,
      ),
      conversationStreamingStateService: ConversationStreamingStateService(
        sessionStateService: ConversationSessionStateService(),
      ),
      conversationGuideViewDataService: ConversationGuideViewDataService(),
      conversationOpeningPanelViewDataService:
          ConversationOpeningPanelViewDataService(),
      openingSessionProjectionService: projectionService,
      projectOpeningAgentGroupBindingService:
          ProjectOpeningAgentGroupBindingService(
            loadSelections: (_) async => const <ProjectAgentGroupSelection>[],
            saveSelections: (_, _) async {},
          ),
      conversationUserVisibleTextService: ConversationUserVisibleTextService(),
      workbenchPrimaryActionService: WorkbenchPrimaryActionService(),
      conversationDraftRuntimeService: conversationDraftRuntimeService,
      draftExecutionConstraintRuntimeService:
          draftExecutionConstraintRuntimeService,
      userOptionPromptBuilderService: UserOptionPromptBuilderService(),
      loadModeGuidanceStateUseCase: LoadModeGuidanceStateUseCase(
        statePort: modeGuidanceStatePort,
      ),
      answerModeGuidanceStageUseCase: AnswerModeGuidanceStageUseCase(
        statePort: modeGuidanceStatePort,
      ),
      modeGuidanceTransitionService: ModeGuidanceTransitionService(),
      openingLaunchBridgeService: WorkbenchOpeningLaunchBridgeService(
        buildModeGuidancePlanInputUseCase: BuildModeGuidancePlanInputUseCase(
          statePort: modeGuidanceStatePort,
        ),
        workflowRuntimeService: effectiveWorkflowRuntimeService,
      ),
      workspaceController: workspaceController,
      readRuntimeState: () => _runtimeState,
      writeRuntimeState: (next) {
        _runtimeState = next;
      },
      readWorkbench: () => _workbench,
      mutateWorkbench: (updater) {
        _workbench = updater(_workbench);
      },
      readSettings: () => _settings,
      persistSettings:
          (
            nextSettings, {
            required successMessage,
            String? selectedProviderId,
          }) async {
            _settings = nextSettings;
          },
      saveSettingsSilently: (nextSettings) async {
        _settings = nextSettings;
      },
      refreshSettingsViewData: () {},
      readThemeId: () => 'light',
      notifyShell: () {},
      showSettings: () async {},
      contextStrategySettingsOf: (_) => const <String, Object?>{},
      selectedModelProvider: (settings) => settings.providers.first,
      toolPermissionApprovalRecordService:
          ProjectToolPermissionApprovalRecordService(
            taskRepository: ProjectTaskRepository(
              workspacePort: effectiveWorkspacePort,
            ),
          ),
      announce: (message) {
        lastAnnouncement = message;
      },
    );
    _workbench = controller.applyConversationState(_workbench);
  }

  AppSettings _settings;
  WorkbenchViewData _workbench;
  WorkbenchProjectRuntimeState _projectState;
  WorkbenchConversationRuntimeState _runtimeState;
  HostInformationPermissionContext? lastHostInformationPermissionContext;
  HostToolPermissionContext? lastHostToolPermissionContext;

  final _RecordingGenerateDraftUseCase generateDraftUseCase;
  final _RecordingModelExecutionProfileService modelExecutionProfileService;

  late final WorkbenchWorkspaceController workspaceController;
  late final WorkbenchConversationController controller;

  WorkbenchViewData get workbench => _workbench;

  AppSettings get settings => _settings;

  WorkbenchConversationRuntimeState get runtimeState => _runtimeState;
  String lastAnnouncement = '';
}

class _RecordingModelExecutionProfileService
    extends ModelExecutionProfileService {
  _RecordingModelExecutionProfileService({
    required this.modelContextWindowTokens,
    required this.maxOutputTokens,
    required this.compressionContextLength,
  });

  final int modelContextWindowTokens;
  final int maxOutputTokens;
  final int compressionContextLength;

  String lastAgentId = '';

  @override
  JsonMap resolve({
    required AppSettings settings,
    ProviderEndpointSettings? provider,
    String overrideModelId = '',
    JsonMap agent = const <String, Object?>{},
    ProjectAgentBinding? projectAgentBinding,
    ProjectAgentModelOverride? projectAgentModelOverride,
  }) {
    lastAgentId = ValueReaders.stringValue(agent['id']);
    return <String, Object?>{
      'provider_id': provider?.id ?? '',
      'resolved_model_id': 'selected-model',
      'runtime_profile': <String, Object?>{
        'model': 'selected-model',
        'context_length': modelContextWindowTokens,
        'compression_context_length': compressionContextLength,
        'max_output_tokens': maxOutputTokens,
      },
      'request_options': <String, Object?>{'agent_id': lastAgentId},
      'model_settings': const <String, Object?>{},
    };
  }
}

class _RecordingGenerateDraftUseCase extends GenerateDraftUseCase {
  _RecordingGenerateDraftUseCase({DraftGenerationResult? scriptedResult})
    : _scriptedResult = scriptedResult,
      super(
        projectWorkspacePort: _NoopProjectWorkspacePort(),
        llmGateway: _NoopLlmGateway(),
        toolExecutionPort: _NoopToolExecutionPort(),
        contextAssemblerService: ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        ),
        projectPromptContract: ProjectPromptContract(),
      );

  final DraftGenerationResult? _scriptedResult;

  String lastAgentId = '';
  String lastUserPrompt = '';
  String lastSessionContext = '';
  SessionPromptContext lastSessionPromptContext = const SessionPromptContext();
  List<String> lastExposedToolIds = const <String>[];
  List<Object?> lastExpressionConstraintProfiles = const <Object?>[];
  List<Object?> lastProjectExpressionConstraintBindings = const <Object?>[];
  JsonMap lastWritingExecutionConstraints = const <String, Object?>{};
  JsonMap lastSelectedCollaborationGroup = const <String, Object?>{};

  @override
  Future<DraftGenerationResult> execute({
    required ProjectDescriptor project,
    required String userPrompt,
    required String modelId,
    String title = '',
    String intent = 'draft',
    JsonMap agent = const <String, Object?>{},
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
    String sessionContext = '',
    SessionPromptContext sessionPromptContext = const SessionPromptContext(),
    JsonMap requestOptions = const <String, Object?>{},
    JsonMap contextSettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
    JsonMap skillRoutingContext = const <String, Object?>{},
    AppSettings? subAgentRuntimeSettings,
    List<ProjectAgentBinding> subAgentBindings = const <ProjectAgentBinding>[],
    String subAgentBindingModeId = '',
    String subAgentBindingStageId = '',
    List<String> exposedToolIds = const <String>[],
    List<Object?> memorySections = const <Object?>[],
    List<Object?> expressionConstraintProfiles = const <Object?>[],
    List<Object?> projectExpressionConstraintBindings = const <Object?>[],
    JsonMap writingExecutionConstraints = const <String, Object?>{},
    List<Object?> projectFileSectionPlan = const <Object?>[],
    JsonMap projectFileContents = const <String, Object?>{},
    String activeDocumentPath = '',
    String activeDocumentBody = '',
    DraftGenerationCancellationToken? cancellationToken,
    void Function(DraftGenerationProgress progress)? onProgress,
  }) async {
    lastAgentId = ValueReaders.stringValue(agent['id']);
    lastUserPrompt = userPrompt;
    lastSelectedCollaborationGroup = ValueReaders.deepCopyMap(
      selectedCollaborationGroup,
    );
    lastSessionContext = sessionContext;
    lastSessionPromptContext = sessionPromptContext;
    lastExposedToolIds = List<String>.from(exposedToolIds, growable: false);
    lastExpressionConstraintProfiles = List<Object?>.from(
      expressionConstraintProfiles,
      growable: false,
    );
    lastProjectExpressionConstraintBindings = List<Object?>.from(
      projectExpressionConstraintBindings,
      growable: false,
    );
    lastWritingExecutionConstraints = ValueReaders.deepCopyMap(
      writingExecutionConstraints,
    );
    return _scriptedResult ??
        DraftGenerationResult(
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
          draftMarkdown: '测试输出',
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
}

class _RecordingWorkflowRuntimeService extends ProjectWorkflowRuntimeService {
  _RecordingWorkflowRuntimeService()
    : super(
        taskRepository: ProjectTaskRepository(
          workspacePort: _NoopProjectWorkspacePort(),
        ),
        promptTemplateService: ProjectPromptTemplateService(
          workspacePort: _NoopProjectWorkspacePort(),
        ),
        generateDraftUseCaseFactory: (_, _) => _RecordingGenerateDraftUseCase(),
      );

  int createLongTaskWorkflowCallCount = 0;
  int runWorkflowTaskQueueCallCount = 0;
  String lastMode = '';
  JsonMap lastOptions = const <String, Object?>{};
  JsonMap lastRunWorkflowTaskQueueOptions = const <String, Object?>{};

  @override
  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) async {
    createLongTaskWorkflowCallCount += 1;
    lastMode = mode;
    lastOptions = ValueReaders.deepCopyMap(options);
    return const <String, Object?>{'ok': true, 'message': '已根据当前开局状态启动长任务。'};
  }

  @override
  Future<JsonMap> runWorkflowTaskQueue(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    runWorkflowTaskQueueCallCount += 1;
    lastRunWorkflowTaskQueueOptions = ValueReaders.deepCopyMap(options);
    return const <String, Object?>{'ok': true, 'message': '长任务已开始推进。'};
  }
}

class _FakeProjectConversationDraftRuntimeService
    extends ProjectConversationDraftRuntimeService {
  _FakeProjectConversationDraftRuntimeService({
    required this.preparation,
    this.finalization = const ProjectConversationDraftRuntimeArtifacts(),
  }) : super(
         workspacePort: _NoopProjectWorkspacePort(),
         hostPort: _NoopProjectToolHostPort(),
       );

  final ProjectConversationDraftRuntimePreparation preparation;
  final ProjectConversationDraftRuntimeArtifacts finalization;
  int prepareCallCount = 0;
  int finalizeCallCount = 0;
  String lastTaskType = '';
  String lastChapterLabelHint = '';
  String lastActiveDocumentPath = '';

  @override
  Future<ProjectConversationDraftRuntimePreparation> prepareDraftRun(
    ProjectDescriptor project, {
    required String taskType,
    List<String> pinnedRelativePaths = const <String>[],
    String chapterLabelHint = '',
    String activeDocumentPath = '',
    String agentId = '',
    String modeId = '',
    String stageId = '',
    String intent = '',
    String phase = '',
    String expressionConstraintPolicyMode = '',
    String expressionConstraintInjectionMode = '',
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
  }) async {
    prepareCallCount += 1;
    lastTaskType = taskType;
    lastChapterLabelHint = chapterLabelHint;
    lastActiveDocumentPath = activeDocumentPath;
    return preparation;
  }

  @override
  Future<ProjectConversationDraftRuntimeArtifacts> finalizeDraftRun({
    required ProjectDescriptor project,
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required String title,
    String fallbackSavedPath = '',
  }) async {
    finalizeCallCount += 1;
    return finalization;
  }
}

OpeningSessionProjection _longTaskProjection() {
  return OpeningSessionProjection(
    projectTypeId: 'long_novel',
    currentGroupId: 'starter_long_form_room',
    currentGroupDisplayName: '长篇主写组',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_long_form_room',
        displayName: '长篇主写组',
        description: '用于长篇开局与推进',
        isSupported: true,
        isDegraded: false,
        isCurrent: true,
        isStarterGroup: true,
      ),
    ],
    orchestration: OpeningOrchestrationResult(
      state: OpeningSessionState(
        projectTypeId: 'long_novel',
        status: OpeningSessionState.statusCollecting,
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_long_form_room',
          availableAgentGroupIds: <String>['starter_long_form_room'],
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-06-15T00:00:00.000',
        updatedAt: '2026-06-15T00:00:00.000',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: false,
        canStartInteractiveSession: false,
        effectiveModeId: '',
        missingRequirements: <OpeningMissingRequirement>[
          OpeningMissingRequirement(
            id: 'mode',
            title: '长任务模式',
            description: '还没有收束当前长篇要用哪种推进模式。',
          ),
        ],
      ),
      suggestedActions: const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.choose_long_task_mode',
          commandId: 'opening.choose_long_task_mode',
          title: '选择长任务模式',
          description: '先确认当前长任务模式，再继续启动正式任务链。',
        ),
      ],
    ),
    availableAgentSummaries: const <OpeningAgentMemberSummary>[
      OpeningAgentMemberSummary(
        agentId: 'writer',
        displayName: '长篇主写智能体',
        role: '负责长篇主线推进',
        isPrimary: true,
        thinkingSupported: true,
        description: '负责长篇开局与正文推进。',
      ),
    ],
    currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
      agentId: 'writer',
      displayName: '长篇主写智能体',
      role: '负责长篇主线推进',
      thinkingSupported: true,
    ),
  );
}

OpeningSessionProjection _readyLongTaskOpeningProjection() {
  return OpeningSessionProjection(
    projectTypeId: 'long_novel',
    currentGroupId: 'starter_long_form_room',
    currentGroupDisplayName: '长篇主写组',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_long_form_room',
        displayName: '长篇主写组',
        description: '用于长篇开局与推进',
        isSupported: true,
        isDegraded: false,
        isCurrent: true,
        isStarterGroup: true,
      ),
    ],
    orchestration: OpeningOrchestrationResult(
      state: OpeningSessionState(
        projectTypeId: 'long_novel',
        status: OpeningSessionState.statusReadyForLongTask,
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_long_form_room',
          availableAgentGroupIds: <String>['starter_long_form_room'],
          runtimeBaselineId: 'continuous_autonomous',
          modeId: 'seed_autopilot_novel',
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-06-15T00:00:00.000',
        updatedAt: '2026-06-15T00:00:00.000',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: true,
        canStartInteractiveSession: false,
        effectiveRuntimeBaselineId: 'continuous_autonomous',
        effectiveModeId: 'seed_autopilot_novel',
        missingRequirements: <OpeningMissingRequirement>[],
      ),
      suggestedActions: const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.start_long_task_run',
          commandId: 'opening.start_long_task_run',
          title: '启动长任务',
          description: '当前开局信息已经收束完成，可以进入正式长任务运行链。',
          payload: <String, Object?>{
            'runtime_baseline_id': 'continuous_autonomous',
            'mode_id': 'seed_autopilot_novel',
            'agent_group_id': 'starter_long_form_room',
          },
        ),
      ],
    ),
    availableAgentSummaries: const <OpeningAgentMemberSummary>[
      OpeningAgentMemberSummary(
        agentId: 'writer',
        displayName: '长篇主写智能体',
        role: '负责长篇主线推进',
        isPrimary: true,
        thinkingSupported: true,
        description: '负责长篇开局与正文推进。',
      ),
    ],
    currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
      agentId: 'writer',
      displayName: '长篇主写智能体',
      role: '负责长篇主线推进',
      thinkingSupported: true,
    ),
  );
}

ModeGuidanceState _readyModeGuidanceState(
  ModeGuidanceTransitionService transitionService,
  String modeId,
) {
  var state = transitionService.initialize(modeId);
  while (!state.isReady) {
    final question = transitionService.buildQuestion(state);
    state = transitionService.answer(
      state,
      stageId: question.stageId,
      fieldKey: question.fieldKey,
      value: '测试 ${question.stageId}',
      label: '测试 ${question.stageId}',
      source: 'test',
    );
  }
  return state;
}

class _StaticOpeningSessionProjectionService
    extends ProjectOpeningSessionProjectionService {
  _StaticOpeningSessionProjectionService({required this.projection})
    : super(
        loadAgentPackages: (_) async => const <JsonMap>[],
        loadAgentGroups: (_) async => const <JsonMap>[],
        loadProjectAgentGroupSelections: (_) async =>
            const <ProjectAgentGroupSelection>[],
      );

  final OpeningSessionProjection projection;

  @override
  Future<OpeningSessionProjection> build({
    required ProjectDescriptor project,
    required ProjectRuntimeProfile? runtimeProfile,
    required ModeGuidanceState? modeGuidanceState,
    String sessionGoalModeId = '',
    String freeTextIntent = '',
    List<ProjectAgentBinding> agentBindings = const <ProjectAgentBinding>[],
  }) async {
    return projection;
  }
}

class _MemoryModeGuidanceStatePort implements ModeGuidanceStatePort {
  _MemoryModeGuidanceStatePort({ModeGuidanceState? initialState})
    : _states = initialState == null
          ? <String, ModeGuidanceState>{}
          : <String, ModeGuidanceState>{initialState.modeId: initialState};

  final Map<String, ModeGuidanceState> _states;

  @override
  Future<ModeGuidanceState?> load(
    ProjectDescriptor project, {
    required String modeId,
  }) async => _states[modeId];

  @override
  Future<void> save(ProjectDescriptor project, ModeGuidanceState state) async {
    _states[state.modeId] = state;
  }
}

class _NoopProjectRepository implements ProjectRepository {
  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async => null;
}

class _NoopProjectWorkspacePort implements ProjectWorkspacePort {
  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _RecordingProjectWorkspacePort implements ProjectWorkspacePort {
  _RecordingProjectWorkspacePort({
    Map<String, String> initialFiles = const <String, String>{},
  }) : files = Map<String, String>.from(initialFiles);

  final Map<String, String> files;
  String lastWriteRelativePath = '';

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return files.keys
        .map(
          (path) => <String, Object?>{
            'relative_path': path,
            'display_name': path.split('/').last,
            'is_dir': false,
          },
        )
        .toList(growable: false);
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      files[relativePath];

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    lastWriteRelativePath = relativePath;
    files[relativePath] = content;
  }
}

class _NoopProjectToolHostPort implements ProjectToolHostPort {
  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {}

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async => false;

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {}

  @override
  Future<String?> readExternalTextFile(String absolutePath) async => null;

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {}

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _NoopLlmGateway implements LlmGateway {
  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async => const <String, Object?>{'ok': true};

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    return requestChat(
      request: ChatRequest.fromLegacy(
        messages: messages,
        modelId: modelId,
        tools: tools,
        options: options,
        attachments: attachments,
      ),
      cancellationToken: cancellationToken,
      onStreamUpdate: onStreamUpdate,
    );
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async => 'noop';
}

class _NoopToolExecutionPort implements ToolExecutionPort {
  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async => const <String, Object?>{'ok': true};
}

class _NoopLongTaskSupervisor implements LongTaskSupervisor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopProjectReviewReportService implements ProjectReviewReportService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopProjectRuntimeProfileRepository
    implements ProjectRuntimeProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProjectDescriptor _project() {
  return const ProjectDescriptor(
    id: 'project',
    name: '测试项目',
    rootPath: 'D:/Projects/test_project',
    projectType: 'novel',
  );
}

AppSettings _buildSettings() {
  return const AppSettings(
    defaultProviderId: 'provider',
    defaultAgentId: 'writer',
    defaultModelId: 'selected-model',
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[
      ProviderEndpointSettings(
        id: 'provider',
        title: 'Test Provider',
        protocol: 'openai_compatible',
        baseUrl: 'https://example.test',
        apiKey: 'key',
        modelId: 'selected-model',
        description: 'test provider',
        isDefault: true,
      ),
    ],
    extraSettings: <String, Object?>{
      'model_settings': <String, Object?>{
        'provider_id': 'provider',
        'model_id': 'selected-model',
        'thinking_enabled': false,
      },
    },
  );
}

OpeningSessionProjection _projection() {
  return OpeningSessionProjection(
    projectTypeId: 'novel',
    currentGroupId: 'starter_novel_writer_room',
    currentGroupDisplayName: '正文协作组',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_novel_writer_room',
        displayName: '正文协作组',
        description: '用于正文推进',
        isSupported: true,
        isDegraded: false,
        isCurrent: true,
        isStarterGroup: true,
      ),
    ],
    orchestration: OpeningOrchestrationResult(
      state: OpeningSessionState(
        projectTypeId: 'novel',
        status: OpeningSessionState.statusReadyForInteractiveSession,
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_novel_writer_room',
          availableAgentGroupIds: <String>['starter_novel_writer_room'],
          sessionGoalModeId: SessionRecordConstants.modeContinueWriting,
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-05-29T00:00:00.000',
        updatedAt: '2026-05-29T00:00:00.000',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: false,
        canStartInteractiveSession: true,
        missingRequirements: <OpeningMissingRequirement>[],
      ),
      suggestedActions: const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.start_interactive_session',
          commandId: 'opening.start_interactive_session',
          title: '开始会话',
          description: '直接开始。',
        ),
      ],
    ),
    availableAgentSummaries: const <OpeningAgentMemberSummary>[
      OpeningAgentMemberSummary(
        agentId: 'writer',
        displayName: '正文智能体',
        role: '负责正文创作',
        isPrimary: true,
        thinkingSupported: true,
        description: '负责完成正文初稿。',
      ),
      OpeningAgentMemberSummary(
        agentId: 'reviewer',
        displayName: '审阅智能体',
        role: '负责审阅与修订建议',
        isPrimary: false,
        thinkingSupported: true,
        description: '负责找出问题并提出修订意见。',
      ),
    ],
    currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
      agentId: 'writer',
      displayName: '正文智能体',
      role: '负责正文创作',
      thinkingSupported: true,
    ),
  );
}
