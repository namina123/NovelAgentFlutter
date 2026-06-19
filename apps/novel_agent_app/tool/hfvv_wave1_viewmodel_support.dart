import 'dart:collection';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/app/state/app_shell_controller.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/long_task_station/application/controllers/long_task_station_controller.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_reference_extraction_execution_service.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_contract_action_view_data.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_view_data.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_tool_lifecycle_status.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_creation_phase.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_conversation_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_resource_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/shared/services/desktop_text_file_picker_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:meta/meta.dart';

import 'probe_support.dart';
import '../../../tools/probe_config_support.dart';

class QueuedDesktopTextFilePickerService extends DesktopTextFilePickerService {
  QueuedDesktopTextFilePickerService([
    Iterable<String> initialPaths = const <String>[],
  ]) : _paths = Queue<String>.from(initialPaths);

  final Queue<String> _paths;

  void enqueue(String path) {
    final cleanPath = path.trim();
    if (cleanPath.isNotEmpty) {
      _paths.addLast(cleanPath);
    }
  }

  @override
  Future<String?> pickSingleFile({required String dialogTitle}) async {
    if (_paths.isEmpty) {
      return null;
    }
    return _paths.removeFirst();
  }

  @override
  Future<List<String>> pickFiles({
    required String dialogTitle,
    bool allowMultiple = false,
  }) async {
    if (_paths.isEmpty) {
      return const <String>[];
    }
    if (!allowMultiple) {
      return <String>[_paths.removeFirst()];
    }
    final results = _paths.toList(growable: false);
    _paths.clear();
    return results;
  }
}

class HfvvWave1AppShellHarness {
  HfvvWave1AppShellHarness._({
    required this.runId,
    required this.laneId,
    required this.controller,
    required this.bundle,
    required this.artifactRoot,
    required this.workspaceRoot,
    required this.repoRoot,
    required this.referenceSourcePickerService,
    required this.projectExpressionConstraintWorkspaceService,
  });

  final String runId;
  final String laneId;
  final AppShellController controller;
  final AdapterBundle bundle;
  final Directory artifactRoot;
  final Directory workspaceRoot;
  final Directory repoRoot;
  final QueuedDesktopTextFilePickerService referenceSourcePickerService;
  final ProjectExpressionConstraintWorkspaceService
  projectExpressionConstraintWorkspaceService;
  String _projectTypeId = '';

  static Future<HfvvWave1AppShellHarness> create({
    required String runId,
    required String laneId,
    required ProbeApiConfig apiConfig,
    Iterable<String> queuedReferenceSourcePaths = const <String>[],
    String streamMode = 'stream',
  }) async {
    final repoRoot = Directory(resolveLocalProbeRepoRoot());
    final artifactRoot = Directory(
      '${repoRoot.path}${Platform.pathSeparator}artifacts'
      '${Platform.pathSeparator}high_fidelity_viewmodel_validation'
      '${Platform.pathSeparator}$runId'
      '${Platform.pathSeparator}$laneId',
    );
    final workspaceRoot = Directory(
      '${artifactRoot.path}${Platform.pathSeparator}workspace',
    );
    if (workspaceRoot.existsSync()) {
      workspaceRoot.deleteSync(recursive: true);
    }
    workspaceRoot.createSync(recursive: true);
    artifactRoot.createSync(recursive: true);

    final settingsRoot = Directory(
      '${workspaceRoot.path}${Platform.pathSeparator}settings',
    )..createSync(recursive: true);
    final projectsRoot = Directory(
      '${workspaceRoot.path}${Platform.pathSeparator}projects',
    )..createSync(recursive: true);

    final hostBundle = AdapterBundle.standard(
      workingDirectoryPath: repoRoot.path,
    );
    final hostSettings = await hostBundle.settingsRepository.load();
    final probeEnvironment = _probeEnvironment(apiConfig);
    final bundle = AdapterBundle.standard(
      workingDirectoryPath: repoRoot.path,
      settingsRootPath: settingsRoot.path,
      defaultProjectRootPath: projectsRoot.path,
      environment: probeEnvironment,
    );
    await bundle.settingsRepository.save(
      buildHfvvWave1SeedSettings(
        apiConfig: apiConfig,
        hostSettings: hostSettings,
        streamMode: streamMode,
      ),
    );
    final savedSettings = await bundle.settingsRepository.load();

    final referenceSourcePickerService = QueuedDesktopTextFilePickerService(
      queuedReferenceSourcePaths,
    );
    final projectExpressionConstraintWorkspaceService =
        _createProjectExpressionConstraintWorkspaceService(bundle);
    final controller = _buildController(
      bundle: bundle,
      savedSettings: savedSettings,
      projectExpressionConstraintWorkspaceService:
          projectExpressionConstraintWorkspaceService,
      referenceSourcePickerService: referenceSourcePickerService,
    );
    final harness = HfvvWave1AppShellHarness._(
      runId: runId,
      laneId: laneId,
      controller: controller,
      bundle: bundle,
      artifactRoot: artifactRoot,
      workspaceRoot: workspaceRoot,
      repoRoot: repoRoot,
      referenceSourcePickerService: referenceSourcePickerService,
      projectExpressionConstraintWorkspaceService:
          projectExpressionConstraintWorkspaceService,
    );
    await harness.initialize();
    return harness;
  }

  WorkbenchViewData get workbench => controller.workbenchPageListenable.value;
  WorkbenchConversationViewData get conversation =>
      controller.workbenchConversationListenable.value;
  WorkbenchResourceViewData get resources =>
      controller.workbenchResourceListenable.value;
  TaskCenterViewData get taskCenter =>
      controller.taskCenterPageListenable.value;

  Future<void> initialize() async {
    await controller.initialize();
    await controller.longTaskStationController.initialize();
  }

  Future<void> createProject({
    required String title,
    required String projectTypeId,
    String storageStrategyId = 'markdown_project_store',
    String runtimeBaselineId = '',
  }) async {
    _projectTypeId = projectTypeId.trim();
    controller.onCreateProjectRequested();
    await waitUntil(
      () =>
          workbench.projectLauncher?.creationPhase ==
          ProjectCreationPhase.projectType,
      description: 'project type phase',
      timeout: const Duration(seconds: 15),
    );
    final request = ProjectCreateRequestViewData(
      title: title,
      projectTypeId: projectTypeId,
      storageStrategyId: storageStrategyId,
      runtimeBaselineId: runtimeBaselineId,
    );
    controller.onProjectCreationSubmitted(request);
    await waitUntil(
      () {
        final phase = workbench.projectLauncher?.creationPhase;
        return phase == ProjectCreationPhase.storageStrategy ||
            phase == ProjectCreationPhase.runtimeBaseline ||
            workbench.projectPath.trim().isNotEmpty;
      },
      description: 'project creation next phase',
      timeout: const Duration(seconds: 15),
    );
    if (workbench.projectLauncher?.creationPhase ==
        ProjectCreationPhase.storageStrategy) {
      controller.onProjectCreationSubmitted(request);
    }
    if (workbench.projectLauncher?.creationPhase ==
        ProjectCreationPhase.runtimeBaseline) {
      controller.onProjectCreationSubmitted(request);
    }
    await waitUntil(
      () => workbench.projectPath.trim().isNotEmpty,
      description: 'project path after creation',
      timeout: const Duration(seconds: 30),
    );
    await waitUntil(
      () =>
          !workbench.generationStatus.contains('正在打开项目') &&
          !workbench.generationStatus.contains('正在加载项目'),
      description: 'project load settle',
      timeout: const Duration(seconds: 30),
    );
  }

  Future<void> sendPrompt(String text) async {
    controller.onSendRequested(text);
  }

  Future<void> invokePrimaryAction(String actionId) async {
    controller.onPrimaryActionRequested(actionId);
  }

  Future<void> selectPendingOption(UserOptionViewData option) async {
    controller.onUserOptionSelected(option);
  }

  Future<void> showTaskCenter() async {
    controller.showTaskCenter();
  }

  Future<void> showLongTaskStation() async {
    controller.showLongTaskStation();
  }

  Future<void> refreshTaskCenter() async {
    controller.onTaskCenterRefreshRequested();
  }

  Future<void> submitTaskCenterWorkflowCreateRequest(
    TaskWorkflowCreateRequestViewData request,
  ) async {
    controller.onTaskCenterWorkflowCreateSubmitted(request);
  }

  Future<void> runTaskCenterQueue() async {
    controller.onTaskCenterRunQueueRequested();
  }

  Future<void> selectTaskCenterSharedAction(
    TaskCenterContractActionViewData action,
  ) async {
    controller.onTaskCenterSharedActionRequested(action);
  }

  Future<void> extractReferenceViaProjectAssets(
    String sourcePath, {
    String strategyProfileId = '',
  }) async {
    referenceSourcePickerService.enqueue(sourcePath);
    await controller.projectAssetsController.refresh();
    final action = controller.projectAssetsController
        .onProjectAssetsExtractReferenceRequested(
          strategyProfileId: strategyProfileId,
        );
    await waitUntil(
      () => controller.projectAssetsController.viewData.isLoading,
      description: 'project assets extraction loading',
      timeout: const Duration(seconds: 15),
    );
    await action;
    await waitUntil(
      () => !controller.projectAssetsController.viewData.isLoading,
      description: 'project assets extraction complete',
      timeout: const Duration(minutes: 15),
    );
  }

  Future<void> waitForConversationActivity({
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final initialSignature = _conversationSignature();
    await waitUntil(
      () =>
          _conversationSignature() != initialSignature ||
          conversation.isGenerating,
      description: 'conversation activity',
      timeout: timeout,
    );
  }

  Future<void> waitForConversationToSettle({
    Duration timeout = const Duration(minutes: 8),
    Duration quietPeriod = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    var lastSignature = _conversationSignature();
    DateTime? quietSince;
    while (DateTime.now().isBefore(deadline)) {
      final currentSignature = _conversationSignature();
      if (currentSignature != lastSignature) {
        lastSignature = currentSignature;
        quietSince = null;
      }
      final isIdle =
          !conversation.isGenerating &&
          !_hasToolStatus(ConversationToolLifecycleStatus.running);
      if (isIdle) {
        quietSince ??= DateTime.now();
        if (DateTime.now().difference(quietSince) >= quietPeriod) {
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw TimeoutException('Timed out waiting for conversation settle.');
  }

  Future<void> waitForTaskCenterToSettle({
    Duration timeout = const Duration(minutes: 8),
    Duration quietPeriod = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    var lastSignature = _taskCenterSignature();
    DateTime? quietSince;
    while (DateTime.now().isBefore(deadline)) {
      final currentSignature = _taskCenterSignature();
      if (currentSignature != lastSignature) {
        lastSignature = currentSignature;
        quietSince = null;
      }
      final status = taskCenter.status.trim();
      final isIdle =
          !status.startsWith('正在') &&
          !status.contains('生成中') &&
          !status.contains('加载中') &&
          !status.contains('刷新中');
      if (isIdle) {
        quietSince ??= DateTime.now();
        if (DateTime.now().difference(quietSince) >= quietPeriod) {
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw TimeoutException('Timed out waiting for task center settle.');
  }

  Future<void> waitUntil(
    bool Function() predicate, {
    required String description,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (predicate()) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    throw TimeoutException('Timed out waiting for $description.');
  }

  Future<void> recordStep({
    required String stepId,
    required String label,
    JsonMap modelEvent = const <String, Object?>{},
    List<Object?> toolEvents = const <Object?>[],
  }) async {
    await _writeJson(
      '${stepId}_viewmodel.json',
      await snapshot(stepId: stepId, label: label),
    );
    await _writeJson('${stepId}_model_event.json', modelEvent);
    await _writeJson('${stepId}_tool_events.json', <String, Object?>{
      'events': toolEvents,
    });
  }

  Future<void> writeLaneReport(JsonMap report) async {
    await _writeJson('lane_report.json', report);
  }

  Future<void> writeProjectManifest() async {
    await _writeJson('project_manifest.json', await projectManifest());
  }

  Future<void> writeFixLog(String content) async {
    final file = File(
      '${artifactRoot.path}${Platform.pathSeparator}fix_log.md',
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<JsonMap> projectManifest() async {
    final projectPath = workbench.projectPath.trim();
    final project = _currentProjectDescriptor();
    final expressionBindings = project == null
        ? const <ProjectExpressionConstraintBinding>[]
        : (await projectExpressionConstraintWorkspaceService.load(
            project,
          )).bindings;
    return <String, Object?>{
      'run_id': runId,
      'lane_id': laneId,
      'project_name': workbench.projectName,
      'project_type': _projectTypeId,
      'workspace_relative_project_path': _relativeToWorkspace(projectPath),
      'repo_relative_project_path': _relativeToRepo(projectPath),
      'model_label': workbench.modelLabel,
      'group_label': conversation.groupSelector.currentGroupLabel,
      'group_options': conversation.groupSelector.groupOptions
          .map(
            (option) => <String, Object?>{
              'id': option.id,
              'label': option.label,
              'note': option.note,
            },
          )
          .toList(growable: false),
      'primary_agent_label': conversation.groupSelector.primaryAgentLabel,
      'expression_constraint_binding_ids': expressionBindings
          .map((binding) => binding.id)
          .toList(growable: false),
      'expression_constraint_profile_ids': expressionBindings
          .map((binding) => binding.profileId)
          .toList(growable: false),
      'resource_entry_count': resources.resourceEntries.length,
      'information_summary': resources.informationViewData.summary,
      'information_usage_summary': resources.informationViewData.usageSummary,
    };
  }

  Future<JsonMap> snapshot({
    required String stepId,
    required String label,
  }) async {
    final projectEntries = await listProjectEntries();
    final longTaskView = controller.longTaskStationController.viewData;
    final projectAssetsView = controller.projectAssetsController.viewData;
    return <String, Object?>{
      'step_id': stepId,
      'label': label,
      'captured_at': DateTime.now().toIso8601String(),
      'workspace_relative_project_path': _relativeToWorkspace(
        workbench.projectPath,
      ),
      'repo_relative_project_path': _relativeToRepo(workbench.projectPath),
      'workbench': <String, Object?>{
        'project_name': workbench.projectName,
        'project_subtitle': workbench.projectSubtitle,
        'generation_status': workbench.generationStatus,
        'tool_core_status': workbench.toolCoreStatus,
        'is_generating': workbench.isGenerating,
        'context_summary': workbench.contextSummary,
        'workflow_title': workbench.workflowTitle,
        'workflow_description': workbench.workflowDescription,
        'resource_entry_count': workbench.resourceEntries.length,
        'active_document_path': workbench.activeDocumentPath,
        'group_label': workbench.groupSelector.currentGroupLabel,
      },
      'conversation': <String, Object?>{
        'generation_status': conversation.generationStatus,
        'tool_core_status': conversation.toolCoreStatus,
        'is_generating': conversation.isGenerating,
        'workflow_title': conversation.workflowTitle,
        'workflow_description': conversation.workflowDescription,
        'composer_hint': conversation.composerHint,
        'entry_count': conversation.conversationEntries.length,
        'primary_actions': conversation.primaryActions
            .map(
              (action) => <String, Object?>{
                'id': action.id,
                'title': action.title,
                'description': action.description,
                'command_id': action.commandId,
                'payload': action.payload,
              },
            )
            .toList(growable: false),
        'opening_panel': conversation.openingPanel == null
            ? const <String, Object?>{}
            : <String, Object?>{
                'title': conversation.openingPanel!.title,
                'summary': conversation.openingPanel!.summary,
                'current_group_display_name':
                    conversation.openingPanel!.currentGroupDisplayName,
                'selection_hint': conversation.openingPanel!.selectionHint,
                'supported_group_count':
                    conversation.openingPanel!.supportedGroups.length,
                'unsupported_group_count':
                    conversation.openingPanel!.unsupportedGroups.length,
              },
        'opening_state': conversation.openingState == null
            ? const <String, Object?>{}
            : <String, Object?>{
                'first_prompt': conversation.openingState!.firstPrompt,
                'next_step_label': conversation.openingState!.nextStepLabel,
                'has_project_foundation':
                    conversation.openingState!.hasProjectFoundation,
                'has_resolved_group':
                    conversation.openingState!.hasResolvedGroup,
                'missing_requirement_titles':
                    conversation.openingState!.missingRequirementTitles,
                'prefer_single_action':
                    conversation.openingState!.preferSingleAction,
                'next_action': conversation.openingState!.nextAction == null
                    ? const <String, Object?>{}
                    : <String, Object?>{
                        'id': conversation.openingState!.nextAction!.id,
                        'title': conversation.openingState!.nextAction!.title,
                        'description':
                            conversation.openingState!.nextAction!.description,
                        'command_id':
                            conversation.openingState!.nextAction!.commandId,
                        'payload':
                            conversation.openingState!.nextAction!.payload,
                      },
              },
        'entries': conversation.conversationEntries
            .map(_conversationEntryToJson)
            .toList(growable: false),
        'pending_options': conversation.pendingOptions
            .map(
              (option) => <String, Object?>{
                'label': option.label,
                'description': option.description,
                'prompt': option.prompt,
                'source_question': option.sourceQuestion,
              },
            )
            .toList(growable: false),
        'sub_agent_runs': conversation.subAgentRuns
            .map(
              (run) => <String, Object?>{
                'id': run.id,
                'agent_name': run.agentName,
                'task': run.task,
                'status': run.status,
                'summary': run.summary,
                'tool_count': run.toolCount,
                'events': run.events,
                'adoption_summary': run.adoptionSummary,
                'degradation_summary': run.degradationSummary,
                'diagnostic_items': run.diagnosticItems,
              },
            )
            .toList(growable: false),
      },
      'resource_view': <String, Object?>{
        'project_name': resources.projectName,
        'project_subtitle': resources.projectSubtitle,
        'entries': resources.resourceEntries
            .map(
              (entry) => <String, Object?>{
                'title': entry.title,
                'relative_path': entry.relativePath,
                'is_directory': entry.isDirectory,
                'is_selected': entry.isSelected,
                'has_children': entry.hasChildren,
              },
            )
            .toList(growable: false),
        'information_summary': resources.informationViewData.summary,
        'information_usage_summary': resources.informationViewData.usageSummary,
        'information_entries': resources.informationViewData.entries
            .map(
              (entry) => <String, Object?>{
                'id': entry.id,
                'title': entry.title,
                'summary': entry.summary,
                'status_label': entry.statusLabel,
                'relative_path': entry.relativePath,
                'source_identity_summary': entry.sourceIdentitySummary,
              },
            )
            .toList(growable: false),
      },
      'project_assets': <String, Object?>{
        'status': projectAssetsView.status,
        'active_tab_id': projectAssetsView.activeTabId,
        'entry_count': projectAssetsView.entries.length,
        'entries': projectAssetsView.entries
            .map(
              (entry) => <String, Object?>{
                'id': entry.id,
                'title': entry.title,
                'badge': entry.badge,
                'relative_path': entry.relativePath,
                'meta': entry.meta,
                'is_selected': entry.isSelected,
              },
            )
            .toList(growable: false),
        'inspector': <String, Object?>{
          'title': projectAssetsView.inspector.title,
          'subtitle': projectAssetsView.inspector.subtitle,
          'badge': projectAssetsView.inspector.badge,
          'source_path': projectAssetsView.inspector.sourcePath,
          'section_count': projectAssetsView.inspector.sections.length,
          'related_asset_count':
              projectAssetsView.inspector.relatedAssets.length,
        },
      },
      'long_task_station': <String, Object?>{
        'status_message': longTaskView.statusMessage,
        'supervisor_status_label': longTaskView.supervisorStatusLabel,
        'total_count': longTaskView.totalCount,
        'active_count': longTaskView.activeCount,
        'attention_count': longTaskView.attentionCount,
        'run_count': longTaskView.runs.length,
      },
      'task_center': <String, Object?>{
        'title': taskCenter.title,
        'status': taskCenter.status,
        'runtime_baseline_title': taskCenter.runtimeBaselineTitle,
        'runtime_mode_label': taskCenter.runtimeModeLabel,
        'runtime_policy_badges': taskCenter.runtimePolicyBadges,
        'task_count': taskCenter.tasks.length,
        'selected_task_id': taskCenter.selectedTaskId,
        'long_task_run_count': taskCenter.longTaskRuns.length,
        'task_queue_run_count': taskCenter.taskQueueRuns.length,
        'selected_long_task_run_path': taskCenter.selectedLongTaskRunPath,
        'selected_task_queue_run_path': taskCenter.selectedTaskQueueRunPath,
        'queue_summary': taskCenter.queueSummary,
        'scheduler_summary': taskCenter.schedulerSummary,
        'resume_brief_body': taskCenter.resumeBriefBody,
        'guidance_revisit_body': taskCenter.guidanceRevisitBody,
        'mode_options': taskCenter.modeOptions
            .map(
              (option) => <String, Object?>{
                'id': option.id,
                'label': option.label,
                'description': option.description,
              },
            )
            .toList(growable: false),
        'action_groups': taskCenter.actionGroups
            .map(
              (group) => <String, Object?>{
                'id': group.id,
                'title': group.title,
                'summary': group.summary,
                'actions': group.actions
                    .map(
                      (action) => <String, Object?>{
                        'id': action.id,
                        'label': action.label,
                        'note': action.note,
                        'tone': action.tone,
                        'invocation_kind': action.invocationKind,
                        'enabled': action.enabled,
                        'disabled_reason': action.disabledReason,
                        'owner_task_path': action.ownerTaskPath,
                        'checkpoint_review_path': action.checkpointReviewPath,
                        'is_recommended': action.isRecommended,
                      },
                    )
                    .toList(growable: false),
              },
            )
            .toList(growable: false),
        'long_task_runs': taskCenter.longTaskRuns
            .map(
              (run) => <String, Object?>{
                'relative_path': run.relativePath,
                'title': run.title,
                'subtitle': run.subtitle,
                'status_label': run.statusLabel,
                'phase_label': run.phaseLabel,
                'progress_percent': run.progressPercent,
                'active_task_title': run.activeTaskTitle,
                'updated_at': run.updatedAt,
                'is_waiting_user': run.isWaitingUser,
                'control_summary': run.controlSummary,
                'is_selected': run.isSelected,
              },
            )
            .toList(growable: false),
      },
      'project_files': projectEntries,
      'derived_statuses': <String, Object?>{
        'running_tools': _toolEntriesByStatus(
          conversation.conversationEntries,
          ConversationToolLifecycleStatus.running,
        ),
        'completed_tools': _toolEntriesByStatus(
          conversation.conversationEntries,
          ConversationToolLifecycleStatus.completed,
        ),
        'failed_tools': _toolEntriesByStatus(
          conversation.conversationEntries,
          ConversationToolLifecycleStatus.failed,
        ),
        'pending_confirmation_tools': _toolEntriesByStatus(
          conversation.conversationEntries,
          ConversationToolLifecycleStatus.pendingConfirmation,
        ),
        'waiting_user':
            conversation.pendingOptions.isNotEmpty ||
            _hasToolStatus(ConversationToolLifecycleStatus.pendingConfirmation),
      },
    };
  }

  Future<List<JsonMap>> listProjectEntries() async {
    final projectPath = workbench.projectPath.trim();
    if (projectPath.isEmpty) {
      return const <JsonMap>[];
    }
    final entries = await bundle.projectWorkspacePort.listEntries(projectPath);
    return entries
        .map(ValueReaders.mapValue)
        .map(
          (entry) => <String, Object?>{
            'relative_path': ValueReaders.stringValue(entry['relative_path']),
            'is_dir': ValueReaders.boolValue(entry['is_dir']),
          },
        )
        .toList(growable: false);
  }

  Future<String> readProjectFile(String relativePath) async {
    final projectPath = workbench.projectPath.trim();
    if (projectPath.isEmpty) {
      return '';
    }
    final normalized = relativePath.replaceAll('/', Platform.pathSeparator);
    final file = File('$projectPath${Platform.pathSeparator}$normalized');
    if (!await file.exists()) {
      return '';
    }
    return file.readAsString();
  }

  Future<List<String>> findProjectFiles(RegExp pattern) async {
    final entries = await listProjectEntries();
    return entries
        .map((entry) => ValueReaders.stringValue(entry['relative_path']))
        .where((path) => pattern.hasMatch(path))
        .toList(growable: false);
  }

  String relativeToRepo(String path) => _relativeToRepo(path);

  String relativeToWorkspace(String path) => _relativeToWorkspace(path);

  ProjectDescriptor? _currentProjectDescriptor() {
    final projectPath = workbench.projectPath.trim();
    if (projectPath.isEmpty) {
      return null;
    }
    return ProjectDescriptor(
      id: '',
      name: workbench.projectName,
      rootPath: projectPath,
      projectType: _projectTypeId,
    );
  }

  bool _hasToolStatus(ConversationToolLifecycleStatus status) {
    return conversation.conversationEntries.any(
      (entry) => entry.toolLifecycleStatus == status,
    );
  }

  String _conversationSignature() {
    return jsonEncode(<String, Object?>{
      'entry_count': conversation.conversationEntries.length,
      'is_generating': conversation.isGenerating,
      'generation_status': conversation.generationStatus,
      'tool_core_status': conversation.toolCoreStatus,
      'pending_options': conversation.pendingOptions.length,
      'primary_actions': conversation.primaryActions.length,
      'sub_agent_runs': conversation.subAgentRuns.length,
      'resource_entries': resources.resourceEntries.length,
      'information_entries': resources.informationViewData.entries.length,
    });
  }

  String _taskCenterSignature() {
    return jsonEncode(<String, Object?>{
      'status': taskCenter.status,
      'tasks': taskCenter.tasks.length,
      'selected_task_id': taskCenter.selectedTaskId,
      'long_task_runs': taskCenter.longTaskRuns.length,
      'selected_long_task_run_path': taskCenter.selectedLongTaskRunPath,
      'task_queue_runs': taskCenter.taskQueueRuns.length,
      'action_groups': taskCenter.actionGroups.length,
      'queue_summary': taskCenter.queueSummary,
      'scheduler_summary': taskCenter.schedulerSummary,
    });
  }

  List<JsonMap> _toolEntriesByStatus(
    List<ConversationEntryViewData> entries,
    ConversationToolLifecycleStatus status,
  ) {
    return entries
        .where((entry) => entry.toolLifecycleStatus == status)
        .map(_conversationEntryToJson)
        .toList(growable: false);
  }

  String _relativeToRepo(String absolutePath) {
    final cleanPath = absolutePath.trim();
    if (cleanPath.isEmpty) {
      return '';
    }
    final relative = _relativeToRoot(
      absolutePath: cleanPath,
      rootPath: repoRoot.path,
    );
    if (relative != null) {
      return relative;
    }
    return cleanPath;
  }

  String _relativeToWorkspace(String absolutePath) {
    final cleanPath = absolutePath.trim();
    if (cleanPath.isEmpty) {
      return '';
    }
    final relative = _relativeToRoot(
      absolutePath: cleanPath,
      rootPath: workspaceRoot.path,
    );
    if (relative != null) {
      return relative;
    }
    return _relativeToRepo(cleanPath);
  }

  String? _relativeToRoot({
    required String absolutePath,
    required String rootPath,
  }) {
    final normalizedPath = _normalizeComparablePath(absolutePath);
    final normalizedRoot = _normalizeComparablePath(rootPath);
    if (normalizedPath == normalizedRoot) {
      return '';
    }
    final rootPrefix = '$normalizedRoot/';
    if (!normalizedPath.startsWith(rootPrefix)) {
      return null;
    }
    return normalizedPath.substring(rootPrefix.length);
  }

  String _normalizeComparablePath(String path) {
    return path.trim().replaceAll('\\', '/').toLowerCase();
  }

  Future<void> _writeJson(String fileName, Object? payload) async {
    final file = File('${artifactRoot.path}${Platform.pathSeparator}$fileName');
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(payload)}\n');
  }

  static Map<String, String> _probeEnvironment(ProbeApiConfig apiConfig) {
    return <String, String>{
      'NOVEL_AGENT_PROVIDER_ID': 'hfvv-wave1-provider',
      if (apiConfig.baseUrl.trim().isNotEmpty)
        'NOVEL_AGENT_PROVIDER_BASE_URL': apiConfig.baseUrl,
      if (apiConfig.apiKey.trim().isNotEmpty)
        'NOVEL_AGENT_PROVIDER_API_KEY': apiConfig.apiKey,
      if (apiConfig.modelId.trim().isNotEmpty)
        'NOVEL_AGENT_MODEL_ID': apiConfig.modelId,
    };
  }

  static AppShellController _buildController({
    required AdapterBundle bundle,
    required AppSettings savedSettings,
    required ProjectExpressionConstraintWorkspaceService
    projectExpressionConstraintWorkspaceService,
    required QueuedDesktopTextFilePickerService referenceSourcePickerService,
  }) {
    final contextAssemblerService = ContextAssemblerService(
      budgetService: ContextBudgetService(),
      staticSectionService: ContextStaticSectionService(
        projectPromptContract: ProjectPromptContract(),
      ),
      projectFileSectionService: ContextProjectFileSectionService(),
    );
    final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
      projectWorkspacePort: bundle.projectWorkspacePort,
    );
    final modeGuidanceRepository = ProjectModeGuidanceRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    final generateCustomizationIndexesUseCase =
        GenerateCustomizationIndexesUseCase(
          writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        );
    final projectAgentSkillLoadoutRepository =
        ProjectAgentSkillLoadoutRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final projectAgentSkillLoadoutHistoryRepository =
        ProjectAgentSkillLoadoutHistoryRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final expressionConstraintProfileRepository =
        ExpressionConstraintProfileRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final projectExpressionConstraintBindingRepository =
        ProjectExpressionConstraintBindingRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final draftExecutionConstraintRuntimeService =
        ProjectDraftExecutionConstraintRuntimeService(
          expressionConstraintProfileRepository:
              expressionConstraintProfileRepository,
          projectExpressionConstraintBindingRepository:
              projectExpressionConstraintBindingRepository,
          constraintBindingRepository: LocalConstraintBindingRepository(
            workspacePort: bundle.projectWorkspacePort,
          ),
        );
    final projectSkillLoadoutSaveAsGroupService =
        ProjectSkillLoadoutSaveAsGroupService(
          workspacePort: bundle.projectWorkspacePort,
        );
    final projectTaskRepository = ProjectTaskRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    final promptTemplateService = ProjectPromptTemplateService(
      workspacePort: bundle.projectWorkspacePort,
    );
    final projectAssetLibraryService = ProjectAssetLibraryService(
      workspacePort: bundle.projectWorkspacePort,
      projectToolHostPort: bundle.projectToolHostPort,
    );
    final projectGeneralContinuitySetupService =
        ProjectGeneralContinuitySetupService(
          continuityRepository: ProjectContinuityRepository(
            workspacePort: bundle.projectWorkspacePort,
          ),
          inputRepository: ProjectContinuityInputRepository(
            workspacePort: bundle.projectWorkspacePort,
          ),
        );
    final projectTimelineRepository = ProjectTimelineRepository(
      hostPort: bundle.projectToolHostPort,
    );
    final projectRelationshipRepository = ProjectRelationshipRepository(
      hostPort: bundle.projectToolHostPort,
    );
    final projectChapterRewriteTaskService = ProjectChapterRewriteTaskService(
      taskRepository: projectTaskRepository,
    );
    final reviewReportService = ProjectReviewReportService(
      workspacePort: bundle.projectWorkspacePort,
      taskRepository: projectTaskRepository,
    );
    final longTaskStationDetailService = ProjectLongTaskStationDetailService(
      taskRepository: projectTaskRepository,
      reviewReportService: reviewReportService,
    );
    final workflowRuntimeService = ProjectWorkflowRuntimeService(
      taskRepository: projectTaskRepository,
      promptTemplateService: promptTemplateService,
      hostAwareGenerateDraftUseCaseFactory:
          (
            provider,
            networkSettings, {
            hostInformationPermissionContext,
            hostToolPermissionContext,
          }) => _createGenerateDraftUseCase(
            bundle: bundle,
            provider: provider,
            networkSettings: networkSettings,
            contextAssemblerService: contextAssemblerService,
            hostInformationPermissionContext: hostInformationPermissionContext,
            hostToolPermissionContext: hostToolPermissionContext,
          ),
      generateDraftUseCaseFactory: (provider, networkSettings) {
        return _createGenerateDraftUseCase(
          bundle: bundle,
          provider: provider,
          networkSettings: networkSettings,
          contextAssemblerService: contextAssemblerService,
        );
      },
      longTaskSupervisor: bundle.longTaskSupervisor,
    );
    final conversationDraftRuntimeService =
        ProjectConversationDraftRuntimeService(
          workspacePort: bundle.projectWorkspacePort,
          hostPort: bundle.projectToolHostPort,
        );
    final referenceExtractionRuntimeService =
        ProjectReferenceExtractionRuntimeService(
          workspacePort: bundle.projectWorkspacePort,
          loadAvailableAgents: (project) =>
              bundle.agentPackageCatalog.loadAgentPackages(project),
          loadAvailableGroups: (project) =>
              bundle.agentGroupCatalog.loadAgentGroups(project),
          groupBindingRepository: bundle.projectAgentGroupBindingRepository,
        );
    final longTaskStationController = LongTaskStationController(
      longTaskSupervisor: bundle.longTaskSupervisor,
      detailService: longTaskStationDetailService,
    );
    return AppShellController(
      settingsRepository: bundle.settingsRepository,
      loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
        projectRepository: bundle.projectRepository,
        projectWorkspacePort: bundle.projectWorkspacePort,
      ),
      loadModeGuidanceStateUseCase: LoadModeGuidanceStateUseCase(
        statePort: modeGuidanceRepository,
      ),
      answerModeGuidanceStageUseCase: AnswerModeGuidanceStageUseCase(
        statePort: modeGuidanceRepository,
      ),
      buildModeGuidancePlanInputUseCase: BuildModeGuidancePlanInputUseCase(
        statePort: modeGuidanceRepository,
      ),
      readProjectFileUseCase: ReadProjectFileUseCase(
        bundle.projectWorkspacePort,
      ),
      saveDraftUseCase: SaveDraftUseCase(
        projectWorkspacePort: bundle.projectWorkspacePort,
      ),
      createProjectWorkspaceUseCase: CreateProjectWorkspaceUseCase(
        projectRepository: bundle.projectRepository,
        projectWorkspacePort: bundle.projectWorkspacePort,
        projectContentRepository: bundle.projectContentRepository,
        projectReadableProjectionService:
            bundle.projectReadableProjectionService,
      ),
      createProjectEntryUseCase: CreateProjectEntryUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
      ),
      importProjectFilesUseCase: ImportProjectFilesUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
      ),
      updateProjectManifestUseCase: UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      ),
      projectToolHostPort: bundle.projectToolHostPort,
      bookDeconstructionNarrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: bundle.projectWorkspacePort,
          ),
      projectRuntimeProfileRepository: ProjectRuntimeProfileRepository(
        workspacePort: bundle.projectWorkspacePort,
      ),
      projectAgentGroupBindingRepository:
          bundle.projectAgentGroupBindingRepository,
      previewCustomizationBundleImportUseCase:
          PreviewCustomizationBundleImportUseCase(),
      importCustomizationBundleUseCase: ImportCustomizationBundleUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
        generateCustomizationIndexesUseCase:
            generateCustomizationIndexesUseCase,
      ),
      generateCustomizationIndexesUseCase: generateCustomizationIndexesUseCase,
      saveCustomizationMarketIndexUseCase: SaveCustomizationMarketIndexUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      ),
      settingsRootPath: bundle.settingsRootPath,
      settingsSearchRoots: bundle.settingsSearchRoots,
      defaultProjectsRootPath: bundle.defaultProjectRootPath,
      isMobileProjectRootLocked: false,
      loadAgentPackages: (project) =>
          bundle.agentPackageCatalog.loadAgentPackages(project),
      loadAgentGroups: (project) =>
          bundle.agentGroupCatalog.loadAgentGroups(project),
      loadSkillPackages: (project) =>
          bundle.skillPackageCatalog.loadSkillPackages(project),
      loadSkillGroups: (project) =>
          bundle.skillGroupCatalog.loadSkillGroups(project),
      loadProjectSkillLoadouts: (project) =>
          projectAgentSkillLoadoutRepository.loadLoadouts(project),
      saveProjectSkillLoadouts: (project, loadouts) =>
          projectAgentSkillLoadoutRepository.saveLoadouts(project, loadouts),
      loadProjectSkillLoadoutHistory: (project) =>
          projectAgentSkillLoadoutHistoryRepository.listEntries(project),
      saveProjectSkillLoadoutHistoryEntry: (project, entry) =>
          projectAgentSkillLoadoutHistoryRepository.saveEntry(project, entry),
      saveProjectSkillLoadoutAsGroup:
          ({
            required project,
            required loadout,
            required groupId,
            required displayName,
            required description,
          }) => projectSkillLoadoutSaveAsGroupService.saveAsGroup(
            project: project,
            loadout: loadout,
            groupId: groupId,
            displayName: displayName,
            description: description,
          ),
      writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      generateDraftUseCaseFactory: (provider, networkSettings) {
        return _createGenerateDraftUseCase(
          bundle: bundle,
          provider: provider,
          networkSettings: networkSettings,
          contextAssemblerService: contextAssemblerService,
        );
      },
      hostAwareGenerateDraftUseCaseFactory:
          (
            provider,
            networkSettings, {
            hostInformationPermissionContext,
            hostToolPermissionContext,
          }) => _createGenerateDraftUseCase(
            bundle: bundle,
            provider: provider,
            networkSettings: networkSettings,
            contextAssemblerService: contextAssemblerService,
            hostInformationPermissionContext: hostInformationPermissionContext,
            hostToolPermissionContext: hostToolPermissionContext,
          ),
      llmGatewayFactory: (provider, networkSettings) =>
          bundle.createGateway(provider, networkSettings: networkSettings),
      workflowRuntimeService: workflowRuntimeService,
      referenceExtractionRuntimeService: referenceExtractionRuntimeService,
      projectReferenceExtractionExecutionService:
          ProjectReferenceExtractionExecutionService(
            readSettings: () => savedSettings,
            llmGatewayFactory: (provider, networkSettings) => bundle
                .createGateway(provider, networkSettings: networkSettings),
            executeReferenceExtraction:
                ({
                  required project,
                  required llmGateway,
                  required modelId,
                  required request,
                }) => referenceExtractionRuntimeService.execute(
                  project: project,
                  llmGateway: llmGateway,
                  modelId: modelId,
                  request: request,
                ),
            sourcePickerService: referenceSourcePickerService,
          ),
      conversationDraftRuntimeService: conversationDraftRuntimeService,
      draftExecutionConstraintRuntimeService:
          draftExecutionConstraintRuntimeService,
      reviewReportService: reviewReportService,
      projectChapterRewriteTaskService: projectChapterRewriteTaskService,
      promptTemplateService: promptTemplateService,
      projectAssetLibraryService: projectAssetLibraryService,
      projectTimelineRepository: projectTimelineRepository,
      projectRelationshipRepository: projectRelationshipRepository,
      projectExpressionConstraintWorkspaceService:
          projectExpressionConstraintWorkspaceService,
      projectGeneralContinuitySetupService:
          projectGeneralContinuitySetupService,
      toolPermissionApprovalRecordService:
          ProjectToolPermissionApprovalRecordService(
            taskRepository: ProjectTaskRepository(
              workspacePort: bundle.projectWorkspacePort,
            ),
          ),
      longTaskSupervisor: bundle.longTaskSupervisor,
      longTaskStationController: longTaskStationController,
    );
  }

  static ProjectExpressionConstraintWorkspaceService
  _createProjectExpressionConstraintWorkspaceService(AdapterBundle bundle) {
    final profileRepository = ExpressionConstraintProfileRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    final bindingRepository = ProjectExpressionConstraintBindingRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    return ProjectExpressionConstraintWorkspaceService(
      loadProfiles: (project) =>
          profileRepository.loadProfiles(project, includeBuiltins: true),
      loadBindings: bindingRepository.loadBindings,
      saveBindings: bindingRepository.saveBindings,
    );
  }

  static GenerateDraftUseCase _createGenerateDraftUseCase({
    required AdapterBundle bundle,
    required ProviderEndpointSettings provider,
    required JsonMap networkSettings,
    required ContextAssemblerService contextAssemblerService,
    HostInformationPermissionContext? hostInformationPermissionContext,
    HostToolPermissionContext? hostToolPermissionContext,
  }) {
    final basePort = bundle.projectToolExecutionPort;
    final scopedToolPort =
        basePort is ProjectToolDispatcher &&
            (hostInformationPermissionContext != null ||
                hostToolPermissionContext != null)
        ? basePort.scopedWithHostPermissionContexts(
            hostInformationPermissionContext: hostInformationPermissionContext,
            hostToolPermissionContext: hostToolPermissionContext,
          )
        : basePort;
    return GenerateDraftUseCase(
      projectWorkspacePort: bundle.projectWorkspacePort,
      llmGateway: bundle.createGateway(
        provider,
        networkSettings: networkSettings,
      ),
      toolExecutionPort: scopedToolPort,
      contextAssemblerService: contextAssemblerService,
      projectPromptContract: ProjectPromptContract(),
      hostToolPermissionContext: hostToolPermissionContext,
      hostPlatform: _currentHostPlatform(),
      loadAvailableAgents: (project) =>
          bundle.agentPackageCatalog.loadAgentPackages(project),
      loadAvailableAgentGroups: (project) =>
          bundle.agentGroupCatalog.loadAgentGroups(project),
    );
  }

  static JsonMap _conversationEntryToJson(ConversationEntryViewData entry) {
    return <String, Object?>{
      'id': entry.id,
      'kind': entry.kind.name,
      'title': entry.title,
      'body': entry.body,
      'is_error': entry.isError,
      'is_retryable_failure': entry.isRetryableFailure,
      'tool_lifecycle_status': entry.toolLifecycleStatus?.name ?? '',
      'detail_title': entry.detailTitle,
      'detail_summary': entry.detailSummary,
      'detail_body': entry.detailBody,
      'detail_expanded_by_default': entry.detailExpandedByDefault,
    };
  }

  static HostPlatform _currentHostPlatform() {
    if (Platform.isWindows) {
      return HostPlatform.windows;
    }
    if (Platform.isLinux) {
      return HostPlatform.linux;
    }
    if (Platform.isMacOS) {
      return HostPlatform.macos;
    }
    if (Platform.isAndroid) {
      return HostPlatform.android;
    }
    if (Platform.isIOS) {
      return HostPlatform.ios;
    }
    return HostPlatform.unknown;
  }
}

@visibleForTesting
AppSettings buildHfvvWave1SeedSettings({
  required ProbeApiConfig apiConfig,
  required AppSettings hostSettings,
  String streamMode = 'stream',
}) {
  return AppSettings(
    defaultProviderId: 'hfvv-wave1-provider',
    defaultAgentId: 'default_generalist',
    defaultModelId: apiConfig.modelId,
    defaultProjectPath: '',
    autoSaveDrafts: true,
    providers: <ProviderEndpointSettings>[
      ProviderEndpointSettings(
        id: 'hfvv-wave1-provider',
        title: 'HFVV Wave1 Provider',
        protocol: 'openai_compatible',
        baseUrl: apiConfig.baseUrl,
        apiKey: '',
        modelId: apiConfig.modelId,
        description:
            'HFVV Wave 1 provider config. Credentials resolved from environment override.',
        isDefault: true,
      ),
    ],
    permissionSettings: const <String, Object?>{
      'information_permission_mode': 'open',
      'allow_network': true,
      'allow_import_collection': true,
      'information_confirmation_mode': 'automatic',
    },
    networkSettings: hostSettings.networkSettings.isEmpty
        ? const <String, Object?>{'proxy_mode': 'system'}
        : hostSettings.networkSettings,
    contextSettings: hostSettings.contextSettings,
    extraSettings: <String, Object?>{
      'model_settings': <String, Object?>{
        'provider_id': 'hfvv-wave1-provider',
        'model_id': apiConfig.modelId,
        'stream_mode': streamMode.trim().isEmpty ? 'stream' : streamMode,
        'api_mode': 'chat',
      },
    },
  );
}
