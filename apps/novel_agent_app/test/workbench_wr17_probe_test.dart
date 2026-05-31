import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_request_handle.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_primary_agent_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_assessment.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_stage.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_group_selector_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_guide_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_input_capability_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_progress_coalescer_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_request_runtime_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_agent_group_binding_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_session_projection_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_context.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WR-17 probe closes the regression loop', () async {
    final repoRoot = _resolveRepoRoot();
    final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
    final recorder = _ProbeRecorder();
    final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
      projectRepository: bundle.projectRepository,
      projectWorkspacePort: bundle.projectWorkspacePort,
      projectContentRepository: bundle.projectContentRepository,
      projectReadableProjectionService: bundle.projectReadableProjectionService,
    );
    final tempProjectsRoot = await Directory.systemTemp.createTemp(
      'workbench_wr17_probe_',
    );
    ProjectDescriptor? createdProject;
    try {
      await recorder.capture('open_existing_project_roundtrip', () async {
        createdProject = await createProjectWorkspaceUseCase.execute(
          projectsRootPath: tempProjectsRoot.path,
          title: 'WR17 Probe Novel',
          projectType: 'novel',
        );
        final reopened = await bundle.projectRepository.openByPath(
          createdProject!.rootPath,
        );
        _ensure(reopened != null, '创建后的项目应可再次打开。');
        return <String, Object?>{
          'project_root': createdProject!.rootPath,
          'reopened_project_id': reopened!.id,
        };
      });

      await recorder.capture(
        'group_switch_updates_primary_agent_projection',
        () async {
          final selectionStore = <ProjectAgentGroupSelection>[];
          final bindingService = ProjectOpeningAgentGroupBindingService(
            loadSelections: (_) async =>
                List<ProjectAgentGroupSelection>.from(selectionStore),
            saveSelections: (_, selections) async {
              selectionStore
                ..clear()
                ..addAll(selections);
            },
          );
          final projectionService = ProjectOpeningSessionProjectionService(
            loadAgentPackages: (_) async => <JsonMap>[
              _agentPackage(
                id: 'default_generalist',
                name: '综合创作智能体',
                role: '负责统筹当前小说协作。',
              ),
              _agentPackage(
                id: 'editorial_lead',
                name: '编辑统筹智能体',
                role: '更偏结构审阅与推进节奏控制。',
              ),
            ],
            loadAgentGroups: (_) async => <JsonMap>[
              _agentGroupPackage(
                id: 'starter_novel_generalist',
                displayName: '默认小说开局',
                primaryAgentId: 'default_generalist',
                projectTypeId: 'novel',
              ),
              _agentGroupPackage(
                id: 'starter_novel_editorial',
                displayName: '编辑统筹组',
                primaryAgentId: 'editorial_lead',
                projectTypeId: 'novel',
              ),
            ],
            loadProjectAgentGroupSelections: (_) async =>
                List<ProjectAgentGroupSelection>.from(selectionStore),
          );
          final groupSelectorService =
              ConversationGroupSelectorViewDataService();
          final runtimeProfile = const ProjectRuntimeProfile(
            projectType: 'novel',
            runtimeBaselineId: '',
            runtimeMode: '',
            initialRunOptions: <String, Object?>{},
          );

          var projection = await projectionService.build(
            project: createdProject!,
            runtimeProfile: runtimeProfile,
            modeGuidanceState: null,
            sessionGoalModeId: SessionRecordConstants.modeSmartOpening,
          );
          var selector = groupSelectorService.build(
            openingProjection: projection,
            fallbackPrimaryAgentLabel: '后备智能体',
          );
          _ensure(selector.currentGroupLabel == '默认小说开局', '初始组名异常。');
          _ensure(selector.primaryAgentLabel == '综合创作智能体', '初始主智能体显示异常。');

          await bindingService.selectProjectDefaultGroup(
            project: createdProject!,
            groupId: 'starter_novel_editorial',
            displayName: '编辑统筹组',
          );
          projection = await projectionService.build(
            project: createdProject!,
            runtimeProfile: runtimeProfile,
            modeGuidanceState: null,
            sessionGoalModeId: SessionRecordConstants.modeSmartOpening,
          );
          selector = groupSelectorService.build(
            openingProjection: projection,
            fallbackPrimaryAgentLabel: '后备智能体',
          );
          _ensure(selector.currentGroupLabel == '编辑统筹组', '切组后当前组未更新。');
          _ensure(selector.primaryAgentLabel == '编辑统筹智能体', '切组后主智能体显示未派生更新。');
          return <String, Object?>{
            'selected_group': selector.currentGroupLabel,
            'primary_agent': selector.primaryAgentLabel,
            'option_count': selector.groupOptions.length,
          };
        },
      );

      await recorder.capture(
        'reasoning_toggle_dynamic_and_attachment_hidden',
        () async {
          const service = ConversationInputCapabilityService();
          final supported = service.resolve(
            context: const ConversationInputCapabilityContext(
              hasActiveProject: true,
              isGenerating: false,
              hostSupportsAttachmentPicking: true,
              modelSupportsReasoning: true,
              modelSupportsFileAttachments: true,
              modelSupportsImageAttachments: true,
              modelSupportsAttachmentUrlsOnly: false,
              modelSupportsMultiAttachments: true,
              collaborationSupportsReasoning: true,
              collaborationSupportsAttachments: true,
              collaborationSupportsToolOptions: false,
              reasoningEnabled: true,
              productExposesReasoningToggle: true,
              productExposesAttachmentEntry: false,
              productExposesStopAction: true,
              productExposesToolOptionsAction: false,
              productExposesOptimizeAction: false,
            ),
          );
          final unsupported = service.resolve(
            context: const ConversationInputCapabilityContext(
              hasActiveProject: true,
              isGenerating: false,
              hostSupportsAttachmentPicking: true,
              modelSupportsReasoning: false,
              modelSupportsFileAttachments: true,
              modelSupportsImageAttachments: false,
              modelSupportsAttachmentUrlsOnly: false,
              modelSupportsMultiAttachments: false,
              collaborationSupportsReasoning: true,
              collaborationSupportsAttachments: true,
              collaborationSupportsToolOptions: false,
              reasoningEnabled: false,
              productExposesReasoningToggle: true,
              productExposesAttachmentEntry: false,
              productExposesStopAction: true,
              productExposesToolOptionsAction: false,
              productExposesOptimizeAction: false,
            ),
          );
          _ensure(supported.showReasoningToggle, '支持 reasoning 时应显示 toggle。');
          _ensure(
            !unsupported.showReasoningToggle,
            '不支持 reasoning 的模型不应显示 toggle。',
          );
          _ensure(supported.supportsAttachmentEntry, '附件内部能力应仍然存在。');
          _ensure(!supported.showAttachmentEntry, '附件公开入口仍应保持关闭。');
          return <String, Object?>{
            'supported_reasoning_toggle': supported.showReasoningToggle,
            'unsupported_reasoning_toggle': unsupported.showReasoningToggle,
            'attachment_public_hidden': !supported.showAttachmentEntry,
          };
        },
      );

      await recorder.capture(
        'stop_cancel_and_cancelled_state_notice',
        () async {
          final runtimeService = ConversationRequestRuntimeService(
            progressCoalescerService:
                const ConversationProgressCoalescerService(
                  interval: Duration(milliseconds: 1),
                ),
          );
          final handle = runtimeService.start(
            onProgress: (_) {},
            execute: ({required onProgress, required cancellationToken}) async {
              await Future<void>.delayed(const Duration(milliseconds: 12));
              onProgress(
                DraftGenerationProgress(
                  phase: 'stream',
                  roundIndex: 1,
                  draftMarkdown: '中途内容',
                ),
              );
              return _draftResult(
                draftMarkdown: '',
                cancelledByUser: true,
                partialContentAccepted: false,
              );
            },
          );
          final didCancel = handle.requestCancellation();
          final result = await handle.completion;
          _ensure(didCancel, '停止请求应成功挂到正式句柄上。');
          _ensure(
            handle.status == ConversationRequestLifecycleStatus.cancelled,
            '停止后的请求句柄状态应为 cancelled。',
          );
          final sessionService = ConversationSessionStateService();
          final seededState = sessionService.stateWithUserPrompt(
            sessionService.createSession(sessionId: 'wr17_cancel_session'),
            '继续推进这一章',
          );
          final cancelledState = sessionService.stateWithAssistantResult(
            seededState,
            result,
          );
          _ensure(
            cancelledState.entries.any(
              (entry) =>
                  entry.kind == ConversationEntryKind.system &&
                  entry.title == '本轮已停止',
            ),
            '取消后应在时间线里保留正式运行期 notice。',
          );
          _ensure(cancelledState.retryRequest != null, '无保留内容时应提供重试入口。');
          return <String, Object?>{
            'handle_status': handle.status.name,
            'cancelled_notice': true,
            'retry_label': cancelledState.retryRequest?.label ?? '',
          };
        },
      );

      await recorder.capture('long_task_unique_launch_action', () async {
        final guideService = ConversationGuideViewDataService();
        final longTaskGuide = guideService.build(
          projectType: 'long_novel',
          needsGoalSelection: true,
          isGenerating: false,
          openingMaturity: const ProjectOpeningMaturityAssessment(
            stage: ProjectOpeningMaturityStage.openingInProgress,
            summary: '当前项目仍处于开局整理阶段。',
            authoredFoundationFileCount: 0,
            narrativeFileCount: 0,
          ),
          openingProjection: _longTaskProjection(),
        );
        final novelGuide = guideService.build(
          projectType: 'novel',
          needsGoalSelection: true,
          isGenerating: false,
          openingMaturity: const ProjectOpeningMaturityAssessment(
            stage: ProjectOpeningMaturityStage.continueReady,
            summary: '当前项目已经有正文或结构基础，可直接继续创作。',
            authoredFoundationFileCount: 3,
            narrativeFileCount: 1,
          ),
          openingProjection: _interactiveProjection(),
        );
        _ensure(longTaskGuide.primaryActions.length == 1, '长任务入口应唯一。');
        _ensure(
          longTaskGuide.primaryActions.single.commandId ==
              'opening.launch_long_task',
          '长任务唯一入口 commandId 应为 opening.launch_long_task。',
        );
        _ensure(
          novelGuide.primaryActions.every(
            (action) => action.commandId != 'opening.launch_long_task',
          ),
          '普通项目不应暴露长任务唯一入口。',
        );
        return <String, Object?>{
          'long_task_action_count': longTaskGuide.primaryActions.length,
          'long_task_action': longTaskGuide.primaryActions.single.commandId,
          'normal_project_actions': novelGuide.primaryActions
              .map((action) => action.commandId)
              .toList(growable: false),
        };
      });
    } finally {
      final reportPath = await _writeReport(repoRoot, recorder);
      if (await tempProjectsRoot.exists()) {
        await tempProjectsRoot.delete(recursive: true);
      }
      if (recorder.failedCount > 0) {
        fail('WR-17 probe failed. report: $reportPath');
      }
    }
  });
}

Future<String> _writeReport(String repoRoot, _ProbeRecorder recorder) async {
  final reportPath =
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}workbench_wr17_probe_report.json';
  final file = File(reportPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'created_at': DateTime.now().toIso8601String(),
      'passed': recorder.passedCount,
      'failed': recorder.failedCount,
      'steps': recorder.steps,
    }),
  );
  return reportPath;
}

String _resolveRepoRoot() {
  var current = Directory.current.absolute;
  for (var depth = 0; depth < 6; depth += 1) {
    final docsFile = File(
      '${current.path}${Platform.pathSeparator}docs${Platform.pathSeparator}workbench-remaining-session-order-2026-05-28.md',
    );
    if (docsFile.existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return Directory.current.absolute.path;
}

JsonMap _agentPackage({
  required String id,
  required String name,
  required String role,
}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'role': role,
    'description': role,
  };
}

JsonMap _agentGroupPackage({
  required String id,
  required String displayName,
  required String primaryAgentId,
  required String projectTypeId,
}) {
  return <String, Object?>{
    'id': id,
    'name': displayName,
    'description': displayName,
    'enabled': true,
    'orchestration': 'supervised',
    'agents': <String>[primaryAgentId],
    'primary_agent_id': primaryAgentId,
    'required_agent_ids': <String>[primaryAgentId],
    'display_label': displayName,
    'applicability_scope': <String, Object?>{
      'allowed_project_type_ids': <String>[projectTypeId],
    },
    'metadata': <String, Object?>{'starter_group': true},
  };
}

DraftGenerationResult _draftResult({
  required String draftMarkdown,
  required bool cancelledByUser,
  required bool partialContentAccepted,
}) {
  return DraftGenerationResult(
    project: const ProjectDescriptor(
      id: 'wr17_project',
      name: 'WR17 Project',
      rootPath: 'D:/workspace/wr17',
    ),
    projectInfo: const <String, Object?>{'id': 'wr17_project'},
    userPrompt: '继续推进这一章',
    prompt: '继续推进这一章',
    modelId: 'probe-model',
    draftMarkdown: draftMarkdown,
    contextPack: const <String, Object?>{'summary': '摘要'},
    selectedPaths: const <String>[],
    executedTools: const <Object?>[],
    writtenPaths: const <String>[],
    changedPaths: const <String>[],
    transcriptMessages: const <JsonMap>[],
    waitingForUserChoice: false,
    reasoningContent: '',
    stoppedByToolError: false,
    toolErrorSummary: '',
    cancelledByUser: cancelledByUser,
    stopPhase: cancelledByUser
        ? DraftGenerationStopPhase.llmRound
        : DraftGenerationStopPhase.none,
    partialContentAccepted: partialContentAccepted,
  );
}

OpeningSessionProjection _longTaskProjection() {
  return OpeningSessionProjection(
    projectTypeId: 'long_novel',
    currentGroupId: 'starter_long_novel_generalist',
    currentGroupDisplayName: '默认长任务开局',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_long_novel_generalist',
        displayName: '默认长任务开局',
        description: '默认长任务开局',
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
          resolvedAgentGroupId: 'starter_long_novel_generalist',
          availableAgentGroupIds: <String>['starter_long_novel_generalist'],
          runtimeBaselineId: 'continuous_autonomous',
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-05-29T00:00:00.000',
        updatedAt: '2026-05-29T00:00:00.000',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: false,
        canStartInteractiveSession: false,
        missingRequirements: <OpeningMissingRequirement>[
          OpeningMissingRequirement(
            id: 'mode_selection',
            title: '缺少长任务模式',
            description: '请先选择模式。',
          ),
        ],
        effectiveRuntimeBaselineId: 'continuous_autonomous',
      ),
      suggestedActions: const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.choose_long_task_mode',
          commandId: 'opening.choose_long_task_mode',
          title: '选择长任务模式',
          description: '先确认模式。',
        ),
      ],
    ),
    currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
      agentId: 'default_generalist',
      displayName: '综合创作智能体',
      role: '负责统筹当前长篇协作。',
      thinkingSupported: true,
    ),
  );
}

OpeningSessionProjection _interactiveProjection() {
  return OpeningSessionProjection(
    projectTypeId: 'novel',
    currentGroupId: 'starter_novel_generalist',
    currentGroupDisplayName: '默认小说开局',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_novel_generalist',
        displayName: '默认小说开局',
        description: '默认小说开局',
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
          resolvedAgentGroupId: 'starter_novel_generalist',
          availableAgentGroupIds: <String>['starter_novel_generalist'],
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
    currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
      agentId: 'default_generalist',
      displayName: '综合创作智能体',
      role: '负责统筹当前小说协作。',
      thinkingSupported: true,
    ),
  );
}

void _ensure(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

class _ProbeRecorder {
  final List<JsonMap> steps = <JsonMap>[];

  int get passedCount =>
      steps.where((step) => ValueReaders.boolValue(step['ok'])).length;

  int get failedCount =>
      steps.where((step) => !ValueReaders.boolValue(step['ok'])).length;

  Future<void> capture(
    String name,
    Future<Map<String, Object?>> Function() action,
  ) async {
    final startedAt = DateTime.now();
    try {
      final detail = await action();
      steps.add(<String, Object?>{
        'name': name,
        'ok': true,
        'detail': detail,
        'started_at': startedAt.toIso8601String(),
        'finished_at': DateTime.now().toIso8601String(),
      });
    } catch (error, stackTrace) {
      steps.add(<String, Object?>{
        'name': name,
        'ok': false,
        'detail': '$error',
        'stack_trace': '$stackTrace',
        'started_at': startedAt.toIso8601String(),
        'finished_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
