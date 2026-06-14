import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_contract_action_view_data.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_path_leak_support.dart';
import 'hfvv_wave2_long_task_progress_support.dart';
import 'hfvv_wave1_viewmodel_support.dart';
import 'hfvv_wave2_user_decision_support.dart';
import 'probe_support.dart';
import '../../../tools/probe_config_support.dart';

const String _defaultRunId = '2026-06-10T01-35-42';
const TaskCenterChapterLengthConfigViewData _defaultLongTaskChapterLength =
    TaskCenterChapterLengthConfigViewData(
      enableChapterWordConstraints: true,
      chapterWordTarget: 2000,
      chapterWordMin: 1600,
      chapterWordMax: 2600,
      sampleChapterWordTarget: 1800,
      sampleChapterWordMin: 1400,
      sampleChapterWordMax: 2400,
    );

class HfvvWave2RunConfig {
  const HfvvWave2RunConfig({
    required this.runId,
    this.enabledLaneIds = const <String>{},
    this.chapterCountOverride,
    this.checkpointIntervalOverride,
    this.targetEffectiveChapterCountOverride,
  });

  final String runId;
  final Set<String> enabledLaneIds;
  final int? chapterCountOverride;
  final int? checkpointIntervalOverride;
  final int? targetEffectiveChapterCountOverride;
}

HfvvWave2RunConfig parseHfvvWave2RunConfig(
  List<String> arguments, {
  String defaultRunId = _defaultRunId,
}) {
  var runId = defaultRunId.trim().isEmpty ? _defaultRunId : defaultRunId.trim();
  final enabledLaneIds = <String>{};
  for (final raw in arguments) {
    final argument = raw.trim();
    if (argument.startsWith('--run-id=')) {
      final candidate = argument.substring('--run-id='.length).trim();
      if (candidate.isNotEmpty) {
        runId = candidate;
      }
      continue;
    }
    if (argument.startsWith('--lane=')) {
      final candidate = argument.substring('--lane='.length).trim();
      if (candidate.isNotEmpty) {
        enabledLaneIds.add(candidate);
      }
    }
  }
  return HfvvWave2RunConfig(
    runId: runId,
    enabledLaneIds: Set<String>.unmodifiable(enabledLaneIds),
  );
}

List<String> resolveHfvvWave2LaneIds({
  Iterable<String> enabledLaneIds = const <String>[],
}) {
  const laneOrder = <String>[
    'lane_f_harry_potter_fanfic_consumption',
    'lane_g_general_long_task_stability',
    'lane_h_general_long_task_multi_agent',
    'lane_i_high_variance_story_arc',
  ];
  final filters = enabledLaneIds
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();
  if (filters.isEmpty) {
    return laneOrder;
  }
  return laneOrder.where(filters.contains).toList(growable: false);
}

Future<void> main(List<String> arguments) async {
  final config = parseHfvvWave2RunConfig(arguments);
  final summary = await runHfvvWave2(config: config);
  stdout.writeln(ValueReaders.boolValue(summary['ok']) ? 'PASS' : 'FAIL');
  if (!ValueReaders.boolValue(summary['ok'])) {
    exitCode = 1;
  }
}

Future<JsonMap> runHfvvWave2({
  bool requireRealProbeOptIn = true,
  HfvvWave2RunConfig config = const HfvvWave2RunConfig(runId: _defaultRunId),
}) async {
  if (requireRealProbeOptIn) {
    await ensureLocalRealProbeOptIn(probeName: 'hfvv_wave2_viewmodel_runner');
  }
  final repoRoot = resolveLocalProbeRepoRoot();
  final apiConfig = await loadProbeApiConfig(
    probeName: 'hfvv_wave2_viewmodel_runner',
    repoRootOverride: repoRoot,
    requireRealProbeOptIn: requireRealProbeOptIn,
  );
  final laneIds = resolveHfvvWave2LaneIds(
    enabledLaneIds: config.enabledLaneIds,
  );
  final summary = <String, Object?>{
    'session': 'HFVV-06',
    'run_id': config.runId,
    'started_at': DateTime.now().toIso8601String(),
    'provider_source': apiConfig.sourceLabel,
    'model_id': apiConfig.modelId,
    'selected_lane_ids': laneIds,
    'lanes': <Object?>[],
  };

  try {
    final laneReports = <JsonMap>[];
    for (final laneId in laneIds) {
      switch (laneId) {
        case 'lane_f_harry_potter_fanfic_consumption':
          laneReports.add(await _runLaneF(apiConfig, runId: config.runId));
          break;
        case 'lane_g_general_long_task_stability':
          laneReports.add(
            await _runLongTaskLane(
              apiConfig,
              runId: config.runId,
              plan: const _LongTaskLanePlan(
                laneId: 'lane_g_general_long_task_stability',
                title: 'HFVV-06 Lane G 一般长任务稳定性',
                seedPrompt: _laneGSeedPrompt,
                chapterCount: 60,
                checkpointInterval: 4,
                targetEffectiveChapterCount: 50,
                expectSubAgentEvidence: false,
                expectedVarianceAnchors: <String>[],
              ),
              chapterCountOverride: config.chapterCountOverride,
              checkpointIntervalOverride: config.checkpointIntervalOverride,
              targetEffectiveChapterCountOverride:
                  config.targetEffectiveChapterCountOverride,
            ),
          );
          break;
        case 'lane_h_general_long_task_multi_agent':
          laneReports.add(
            await _runLongTaskLane(
              apiConfig,
              runId: config.runId,
              plan: const _LongTaskLanePlan(
                laneId: 'lane_h_general_long_task_multi_agent',
                title: 'HFVV-06 Lane H 长任务多智能体',
                seedPrompt: _laneHSeedPrompt,
                chapterCount: 60,
                checkpointInterval: 4,
                targetEffectiveChapterCount: 50,
                expectSubAgentEvidence: true,
                expectedVarianceAnchors: <String>[],
              ),
              chapterCountOverride: config.chapterCountOverride,
              checkpointIntervalOverride: config.checkpointIntervalOverride,
              targetEffectiveChapterCountOverride:
                  config.targetEffectiveChapterCountOverride,
            ),
          );
          break;
        case 'lane_i_high_variance_story_arc':
          laneReports.add(
            await _runLongTaskLane(
              apiConfig,
              runId: config.runId,
              plan: const _LongTaskLanePlan(
                laneId: 'lane_i_high_variance_story_arc',
                title: 'HFVV-06 Lane I 多剧烈变化剧情',
                seedPrompt: _laneISeedPrompt,
                chapterCount: 60,
                checkpointInterval: 3,
                targetEffectiveChapterCount: 50,
                expectSubAgentEvidence: false,
                expectedVarianceAnchors: <String>[
                  '武侠世界',
                  '末世废土',
                  '魔法学园',
                  '现代都市',
                ],
              ),
              chapterCountOverride: config.chapterCountOverride,
              checkpointIntervalOverride: config.checkpointIntervalOverride,
              targetEffectiveChapterCountOverride:
                  config.targetEffectiveChapterCountOverride,
            ),
          );
          break;
      }
    }
    summary['lanes'] = laneReports;
    summary['ok'] = laneReports.every(
      (lane) => ValueReaders.boolValue(lane['ok']),
    );
  } catch (error, stackTrace) {
    summary['ok'] = false;
    summary['error'] = '$error';
    summary['stack_trace'] = '$stackTrace';
  } finally {
    summary['finished_at'] = DateTime.now().toIso8601String();
    await _writeSummary(repoRoot, summary, runId: config.runId);
  }
  return summary;
}

Future<JsonMap> _runLaneF(
  ProbeApiConfig apiConfig, {
  required String runId,
}) async {
  const laneId = 'lane_f_harry_potter_fanfic_consumption';
  final harness = await HfvvWave1AppShellHarness.create(
    runId: runId,
    laneId: laneId,
    apiConfig: apiConfig,
  );
  final steps = <String>[];
  final modelDecisions = <JsonMap>[];
  var stepIndex = 0;

  Future<void> capture(String label) async {
    stepIndex += 1;
    final stepId = _stepId(stepIndex);
    final event = _conversationEvent(harness, phase: label);
    steps.add(stepId);
    modelDecisions.add(event);
    await harness.recordStep(
      stepId: stepId,
      label: label,
      modelEvent: event,
      toolEvents: _toolEvents(harness),
    );
  }

  JsonMap report = <String, Object?>{
    'lane_id': laneId,
    'run_id': runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace': 'artifacts/high_fidelity_viewmodel_validation/$runId/$laneId/',
    'fixes_applied': const <Object?>[],
    'rerun_count': 0,
  };

  try {
    await capture('initialized');
    await harness.createProject(
      title: 'HFVV-06 Lane F 哈利波特同人消费',
      projectTypeId: 'novel',
    );
    await harness.writeProjectManifest();
    await capture('project_created');

    final sourceFile = _harryPotterSourceFile(harness, runId: runId);
    if (!sourceFile.existsSync()) {
      throw StateError('Lane F source file missing: ${sourceFile.path}');
    }
    await harness.extractReferenceViaProjectAssets(sourceFile.path);
    await capture('reference_extraction_settled');

    await harness.sendPrompt(_laneFPrompt);
    await harness.waitForConversationActivity(
      timeout: const Duration(minutes: 2),
    );
    await capture('turn_1_active');
    await harness.waitForConversationToSettle(
      timeout: const Duration(minutes: 12),
    );
    await capture('turn_1_settled');

    if (harness.conversation.pendingOptions.isNotEmpty) {
      final option = chooseLaneFFanficPendingOption(
        harness.conversation.pendingOptions,
      );
      if (option != null) {
        await harness.selectPendingOption(option);
      } else {
        await harness.sendPrompt(_laneFFollowUpPrompt);
      }
      await harness.waitForConversationActivity(
        timeout: const Duration(minutes: 2),
      );
      await capture('turn_2_active');
      await harness.waitForConversationToSettle(
        timeout: const Duration(minutes: 12),
      );
      await capture('turn_2_settled');
    }

    final projectEntries = await harness.listProjectEntries();
    final latestAssistant = _latestAssistantText(
      harness.conversation.conversationEntries,
    );
    final mountedKnowledgeEvidence =
        _hasProjectPath(projectEntries, const <String>[
          '.novel_agent/sqlite/novel_agent.db',
          'knowledge/',
          'references/引用作品边界.md',
        ]) ||
        harness.resources.informationViewData.entries.isNotEmpty;
    final fanficAnchorCount = _anchorHitCount(latestAssistant, const <String>[
      '哈利',
      '霍格沃茨',
      '海格',
      '对角巷',
    ]);
    final biasShiftEvidence =
        latestAssistant.contains('偏移') ||
        latestAssistant.contains('代价') ||
        latestAssistant.contains('原作');
    final leakCheck = await _containsSourceLeak(
      harness,
      disallowedFragments: <String>[
        harness.repoRoot.path,
        harness.workspaceRoot.path,
      ],
    );
    final ok =
        mountedKnowledgeEvidence &&
        fanficAnchorCount >= 2 &&
        biasShiftEvidence &&
        !leakCheck;

    report = <String, Object?>{
      ...report,
      'ok': ok,
      'report_category': ok ? 'success' : 'content_quality_failure',
      'finished_at': DateTime.now().toIso8601String(),
      'project_manifest': await harness.projectManifest(),
      'viewmodel_steps': steps,
      'model_decisions': modelDecisions,
      'tool_events': _toolEvents(harness),
      'validation': <String, Object?>{
        'source_file_repo_relative': harness.relativeToRepo(sourceFile.path),
        'mounted_knowledge_evidence': mountedKnowledgeEvidence,
        'fanfic_anchor_count': fanficAnchorCount,
        'bias_shift_evidence': biasShiftEvidence,
        'absolute_source_path_leak_detected': leakCheck,
        'latest_assistant_excerpt': _clip(latestAssistant, 900),
      },
      'files_created': projectEntries,
      'failures': ok
          ? const <Object?>[]
          : <Object?>[
              <String, Object?>{
                'category': 'content_quality_failure',
                'summary': '哈利波特同人消费没有留下足够的知识消费或剧情偏移证据。',
              },
            ],
    };
  } catch (error, stackTrace) {
    report = _laneExceptionReport(
      base: report,
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await harness.writeLaneReport(report);
    await harness.writeFixLog(_fixLog(report));
    harness.controller.dispose();
  }
  return report;
}

Future<JsonMap> _runLongTaskLane(
  ProbeApiConfig apiConfig, {
  required String runId,
  required _LongTaskLanePlan plan,
  int? chapterCountOverride,
  int? checkpointIntervalOverride,
  int? targetEffectiveChapterCountOverride,
}) async {
  final harness = await HfvvWave1AppShellHarness.create(
    runId: runId,
    laneId: plan.laneId,
    apiConfig: apiConfig,
  );
  final steps = <String>[];
  final modelDecisions = <JsonMap>[];
  final batchReports = <JsonMap>[];
  var stepIndex = 0;
  var stagnationCount = 0;
  var previousEffectiveChapters = 0;
  var sharedActionCount = 0;
  var queueRunCount = 0;
  var previousTaskCount = 0;
  var previousSelectedTaskId = '';
  var previousQueueSummary = '';
  var previousSchedulerSummary = '';

  Future<void> capture(String label) async {
    stepIndex += 1;
    final stepId = _stepId(stepIndex);
    final event = _conversationEvent(harness, phase: label);
    steps.add(stepId);
    modelDecisions.add(event);
    await harness.recordStep(
      stepId: stepId,
      label: label,
      modelEvent: event,
      toolEvents: _toolEvents(harness),
    );
  }

  JsonMap report = <String, Object?>{
    'lane_id': plan.laneId,
    'run_id': runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace':
        'artifacts/high_fidelity_viewmodel_validation/$runId/${plan.laneId}/',
    'fixes_applied': const <Object?>[],
    'rerun_count': 0,
  };

  try {
    await capture('initialized');
    await harness.createProject(
      title: plan.title,
      projectTypeId: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
    );
    await harness.writeProjectManifest();
    await capture('project_created');

    await harness.showTaskCenter();
    await harness.refreshTaskCenter();
    await harness.waitForTaskCenterToSettle(
      timeout: const Duration(seconds: 45),
    );
    await capture('task_center_ready');

    final mode = harness.taskCenter.defaultMode.trim().isNotEmpty
        ? harness.taskCenter.defaultMode.trim()
        : (harness.taskCenter.modeOptions.isEmpty
              ? 'seed_to_full_novel'
              : harness.taskCenter.modeOptions.first.id);
    final createSignature = _taskCenterSignature(harness.taskCenter);
    await harness.submitTaskCenterWorkflowCreateRequest(
        TaskWorkflowCreateRequestViewData(
          mode: mode,
          outlinePath: harness.taskCenter.defaultOutlinePath,
          seedPrompt: plan.seedPrompt,
        chapterCount: chapterCountOverride ?? plan.chapterCount,
        checkpointInterval:
            checkpointIntervalOverride ?? plan.checkpointInterval,
          chapterLength: _defaultLongTaskChapterLength,
        ),
      );
    await harness.waitUntil(
      () =>
          _taskCenterSignature(harness.taskCenter) != createSignature ||
          harness.taskCenter.status.startsWith('正在'),
      description: '${plan.laneId} task center create start',
      timeout: const Duration(seconds: 30),
    );
    await capture('workflow_create_active');
    await harness.waitForTaskCenterToSettle(
      timeout: const Duration(minutes: 5),
    );
    await capture('workflow_create_settled');
    previousTaskCount = harness.taskCenter.tasks.length;
    previousSelectedTaskId = harness.taskCenter.selectedTaskId;
    previousQueueSummary = harness.taskCenter.queueSummary;
    previousSchedulerSummary = harness.taskCenter.schedulerSummary;

    final targetEffectiveChapterCount =
        targetEffectiveChapterCountOverride ??
        plan.targetEffectiveChapterCount;
    final plannedBatchCount = (chapterCountOverride ?? plan.chapterCount) * 4;
    final maxBatches = plannedBatchCount < 16 ? 16 : plannedBatchCount;
    for (var batchIndex = 1; batchIndex <= maxBatches; batchIndex += 1) {
      final effectiveChapters = await _countEffectiveChapters(harness);
      final currentAction = chooseWave2TaskCenterSharedAction(
        _flattenTaskCenterActions(harness.taskCenter),
      );
      if (effectiveChapters >= targetEffectiveChapterCount) {
        break;
      }

      if (currentAction != null) {
        final actionSignature = _taskCenterSignature(harness.taskCenter);
        await harness.selectTaskCenterSharedAction(currentAction);
        sharedActionCount += 1;
        await harness.waitUntil(
          () =>
              _taskCenterSignature(harness.taskCenter) != actionSignature ||
              harness.taskCenter.status.startsWith('正在'),
          description: '${plan.laneId} shared action start',
          timeout: const Duration(seconds: 30),
        );
        await _waitForWave2PendingTaskCenterEvidence(
          harness,
          description: '${plan.laneId} shared action pending evidence',
        );
        await capture('shared_action_${batchIndex}_active');
        await harness.waitForTaskCenterToSettle(
          timeout: const Duration(minutes: 10),
        );
        await capture('shared_action_${batchIndex}_settled');
      } else {
        final queueSignature = _taskCenterSignature(harness.taskCenter);
        await harness.runTaskCenterQueue();
        queueRunCount += 1;
        await harness.waitUntil(
          () =>
              _taskCenterSignature(harness.taskCenter) != queueSignature ||
              harness.taskCenter.status.startsWith('正在'),
          description: '${plan.laneId} queue run start',
          timeout: const Duration(seconds: 30),
        );
        await _waitForWave2PendingTaskCenterEvidence(
          harness,
          description: '${plan.laneId} queue pending evidence',
        );
        await capture('queue_batch_${batchIndex}_active');
        await harness.waitForTaskCenterToSettle(
          timeout: const Duration(minutes: 45),
        );
        await capture('queue_batch_${batchIndex}_settled');
      }

      final chapterPaths = await _effectiveChapterPaths(harness);
      final newEffectiveChapters = chapterPaths.length;
      final pendingSharedAction = chooseWave2TaskCenterSharedAction(
        _flattenTaskCenterActions(harness.taskCenter),
      );
      final structuralProgressObserved =
          harness.taskCenter.tasks.length != previousTaskCount ||
          harness.taskCenter.selectedTaskId != previousSelectedTaskId ||
          harness.taskCenter.queueSummary != previousQueueSummary ||
          harness.taskCenter.schedulerSummary != previousSchedulerSummary;
      stagnationCount = nextWave2LongTaskStagnationCount(
        currentStagnationCount: stagnationCount,
        previousEffectiveChapters: previousEffectiveChapters,
        newEffectiveChapters: newEffectiveChapters,
        structuralProgressObserved: structuralProgressObserved,
        actionUsed: currentAction != null,
        pendingSharedActionAvailable: pendingSharedAction != null,
      );
      previousEffectiveChapters = newEffectiveChapters;
      previousTaskCount = harness.taskCenter.tasks.length;
      previousSelectedTaskId = harness.taskCenter.selectedTaskId;
      previousQueueSummary = harness.taskCenter.queueSummary;
      previousSchedulerSummary = harness.taskCenter.schedulerSummary;

      batchReports.add(<String, Object?>{
        'batch_index': batchIndex,
        'effective_chapter_count': newEffectiveChapters,
        'stagnation_count': stagnationCount,
        'task_center_status': harness.taskCenter.status,
        'long_task_run_count': harness.taskCenter.longTaskRuns.length,
        'task_queue_run_count': harness.taskCenter.taskQueueRuns.length,
        'selected_long_task_run_path':
            harness.taskCenter.selectedLongTaskRunPath,
        'shared_action_used': currentAction != null,
        'shared_action_id': currentAction?.id ?? '',
        'shared_action_label': currentAction?.label ?? '',
        'next_shared_action_available': pendingSharedAction != null,
        'next_shared_action_id': pendingSharedAction?.id ?? '',
        'next_shared_action_label': pendingSharedAction?.label ?? '',
        'queue_summary': harness.taskCenter.queueSummary,
        'scheduler_summary': harness.taskCenter.schedulerSummary,
        'chapter_paths_tail': chapterPaths.length <= 5
            ? chapterPaths
            : chapterPaths.sublist(chapterPaths.length - 5),
      });
      if (shouldStopWave2LongTaskLoop(
        stagnationCount: stagnationCount,
        pendingSharedActionAvailable: pendingSharedAction != null,
      )) {
        break;
      }
    }

    await harness.showLongTaskStation();
    await capture('long_task_station_observed');

    final projectEntries = await harness.listProjectEntries();
    final effectiveChapterPaths = await _effectiveChapterPaths(harness);
    final effectiveChapterCount = effectiveChapterPaths.length;
    final longTaskRunCount = harness.taskCenter.longTaskRuns.length;
    final taskQueueRunCount = harness.taskCenter.taskQueueRuns.length;
    final runningToolObserved = modelDecisions.any(
      (decision) => ValueReaders.stringValue(decision['phase']).contains(
        'active',
      ),
    );
    final subAgentEvidenceCount = await _countFilesContainingPatterns(
      harness,
      filePattern: RegExp(r'activation_report\.json$'),
      patterns: const <Pattern>['sub_agent', '子智能体', 'call_sub_agent'],
    );
    final varianceAnchorHitCount = await _countFilesContainingPatterns(
      harness,
      filePattern: RegExp(r'^chapters\/.*\.md$'),
      patterns: plan.expectedVarianceAnchors,
    );
    final ok =
        effectiveChapterCount >= targetEffectiveChapterCount &&
        longTaskRunCount >= 1 &&
        taskQueueRunCount >= 1 &&
        runningToolObserved &&
        (!plan.expectSubAgentEvidence || subAgentEvidenceCount >= 1) &&
        (plan.expectedVarianceAnchors.isEmpty || varianceAnchorHitCount >= 2);

    final failures = <Object?>[];
    if (effectiveChapterCount < targetEffectiveChapterCount) {
      failures.add(<String, Object?>{
        'category': 'runtime_stability_failure',
        'summary':
            '有效章节数只有 $effectiveChapterCount，未达到 $targetEffectiveChapterCount 章验收线。',
      });
    }
    if (longTaskRunCount < 1 || taskQueueRunCount < 1) {
      failures.add(<String, Object?>{
        'category': 'validation_failure',
        'summary': 'Task Center / Long Task Station 没有形成足够的长任务运行证据。',
      });
    }
    if (plan.expectSubAgentEvidence && subAgentEvidenceCount < 1) {
      failures.add(<String, Object?>{
        'category': 'content_quality_failure',
        'summary': '长任务没有留下可证明的多智能体调度痕迹。',
      });
    }
    if (plan.expectedVarianceAnchors.isNotEmpty && varianceAnchorHitCount < 2) {
      failures.add(<String, Object?>{
        'category': 'content_quality_failure',
        'summary': '章节正文里没有形成足够的世界切换/剧情变化锚点。',
      });
    }

    report = <String, Object?>{
      ...report,
      'ok': ok,
      'report_category': ok
          ? 'success'
          : (effectiveChapterCount < targetEffectiveChapterCount
                ? 'runtime_stability_failure'
                : 'content_quality_failure'),
      'finished_at': DateTime.now().toIso8601String(),
      'project_manifest': await harness.projectManifest(),
      'viewmodel_steps': steps,
      'model_decisions': modelDecisions,
      'tool_events': _toolEvents(harness),
      'validation': <String, Object?>{
        'effective_chapter_count': effectiveChapterCount,
        'effective_chapter_paths_tail': effectiveChapterPaths.length <= 8
            ? effectiveChapterPaths
            : effectiveChapterPaths.sublist(effectiveChapterPaths.length - 8),
        'long_task_run_count': longTaskRunCount,
        'task_queue_run_count': taskQueueRunCount,
        'shared_action_count': sharedActionCount,
        'queue_run_count': queueRunCount,
        'sub_agent_evidence_count': subAgentEvidenceCount,
        'variance_anchor_hit_count': varianceAnchorHitCount,
        'running_tool_observed': runningToolObserved,
        'task_center_status': harness.taskCenter.status,
        'queue_summary': harness.taskCenter.queueSummary,
        'scheduler_summary': harness.taskCenter.schedulerSummary,
        'stagnation_count': stagnationCount,
        'batch_reports': batchReports,
      },
      'files_created': projectEntries,
      'failures': failures,
    };
  } catch (error, stackTrace) {
    report = _laneExceptionReport(
      base: report,
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await harness.writeLaneReport(report);
    await harness.writeFixLog(_fixLog(report));
    harness.controller.dispose();
  }
  return report;
}

class _LongTaskLanePlan {
  const _LongTaskLanePlan({
    required this.laneId,
    required this.title,
    required this.seedPrompt,
    required this.chapterCount,
    required this.checkpointInterval,
    required this.targetEffectiveChapterCount,
    required this.expectSubAgentEvidence,
    required this.expectedVarianceAnchors,
  });

  final String laneId;
  final String title;
  final String seedPrompt;
  final int chapterCount;
  final int checkpointInterval;
  final int targetEffectiveChapterCount;
  final bool expectSubAgentEvidence;
  final List<String> expectedVarianceAnchors;
}

String _stepId(int value) => 'step_${value.toString().padLeft(3, '0')}';

JsonMap _conversationEvent(
  HfvvWave1AppShellHarness harness, {
  required String phase,
}) {
  final latestAssistant = _latestAssistantText(
    harness.conversation.conversationEntries,
  );
  return <String, Object?>{
    'phase': phase,
    'captured_at': DateTime.now().toIso8601String(),
    'generation_status': harness.conversation.generationStatus,
    'tool_core_status': harness.conversation.toolCoreStatus,
    'pending_option_labels': harness.conversation.pendingOptions
        .map((option) => option.label)
        .toList(growable: false),
    'primary_action_ids': harness.conversation.primaryActions
        .map((action) => action.id)
        .toList(growable: false),
    'primary_action_commands': harness.conversation.primaryActions
        .map((action) => action.commandId)
        .toList(growable: false),
    'sub_agent_run_count': harness.conversation.subAgentRuns.length,
    'information_entry_count':
        harness.resources.informationViewData.entries.length,
    'task_center_status': harness.taskCenter.status,
    'task_center_task_count': harness.taskCenter.tasks.length,
    'task_center_long_task_run_count': harness.taskCenter.longTaskRuns.length,
    'task_center_action_group_count': harness.taskCenter.actionGroups.length,
    'latest_assistant_excerpt': _clip(latestAssistant, 500),
  };
}

List<Object?> _toolEvents(HfvvWave1AppShellHarness harness) {
  return harness.conversation.conversationEntries
      .where((entry) => entry.toolLifecycleStatus != null)
      .map(
        (entry) => <String, Object?>{
          'id': entry.id,
          'title': entry.title,
          'body': _clip(entry.body, 240),
          'status': entry.toolLifecycleStatus?.name ?? '',
          'detail_summary': entry.detailSummary,
        },
      )
      .toList(growable: false);
}

Future<int> _countEffectiveChapters(HfvvWave1AppShellHarness harness) async {
  return (await _effectiveChapterPaths(harness)).length;
}

Future<List<String>> _effectiveChapterPaths(
  HfvvWave1AppShellHarness harness,
) async {
  final entries = await harness.listProjectEntries();
  final results = <String>[];
  for (final entry in entries) {
    final path = ValueReaders.stringValue(
      entry['relative_path'],
    ).replaceAll('\\', '/');
    if (ValueReaders.boolValue(entry['is_dir']) ||
        !path.startsWith('chapters/') ||
        !path.endsWith('.md')) {
      continue;
    }
    final content = await harness.readProjectFile(path);
    final normalized = content
        .replaceAll(RegExp(r'^#.*$', multiLine: true), '')
        .replaceAll(RegExp(r'[`*_>\-\[\]\(\)]'), ' ')
        .trim();
    if (normalized.length >= 500) {
      results.add(path);
    }
  }
  return results;
}

@visibleForTesting
bool hasWave2ObservablePendingTaskCenterState(TaskCenterViewData viewData) {
  if (!viewData.status.startsWith('正在')) {
    return true;
  }
  if (viewData.longTaskRuns.isNotEmpty || viewData.taskQueueRuns.isNotEmpty) {
    return true;
  }
  if (viewData.selectedLongTaskRunPath.trim().isNotEmpty ||
      viewData.selectedTaskQueueRunPath.trim().isNotEmpty) {
    return true;
  }
  final schedulerSummary = viewData.schedulerSummary.trim();
  if (schedulerSummary.isNotEmpty &&
      !schedulerSummary.contains('Long task run not found.')) {
    return true;
  }
  return false;
}

Future<void> _waitForWave2PendingTaskCenterEvidence(
  HfvvWave1AppShellHarness harness, {
  required String description,
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (!harness.taskCenter.status.startsWith('正在')) {
    return;
  }
  await harness.waitUntil(
    () {
      final viewData = harness.taskCenter;
      final longTaskStation = harness.controller.longTaskStationController.viewData;
      return !viewData.status.startsWith('正在') ||
          longTaskStation.runs.isNotEmpty ||
          hasWave2ObservablePendingTaskCenterState(viewData);
    },
    description: description,
    timeout: timeout,
  );
}

Future<int> _countFilesContainingPatterns(
  HfvvWave1AppShellHarness harness, {
    required RegExp filePattern,
    required List<Pattern> patterns,
}) async {
  if (patterns.isEmpty) {
    return 0;
  }
  final entries = await harness.listProjectEntries();
  var count = 0;
  for (final entry in entries) {
    final path = ValueReaders.stringValue(
      entry['relative_path'],
    ).replaceAll('\\', '/');
    if (ValueReaders.boolValue(entry['is_dir']) ||
        !filePattern.hasMatch(path)) {
      continue;
    }
    final content = await harness.readProjectFile(path);
    if (patterns.any((pattern) => content.contains(pattern))) {
      count += 1;
    }
  }
  return count;
}

List<TaskCenterContractActionViewData> _flattenTaskCenterActions(
  TaskCenterViewData taskCenter,
) {
  final result = <TaskCenterContractActionViewData>[];
  for (final group in taskCenter.actionGroups) {
    result.addAll(group.actions);
  }
  return result;
}

String _taskCenterSignature(TaskCenterViewData viewData) {
  return jsonEncode(<String, Object?>{
    'status': viewData.status,
    'task_count': viewData.tasks.length,
    'selected_task_id': viewData.selectedTaskId,
    'long_task_run_count': viewData.longTaskRuns.length,
    'task_queue_run_count': viewData.taskQueueRuns.length,
    'selected_long_task_run_path': viewData.selectedLongTaskRunPath,
    'selected_task_queue_run_path': viewData.selectedTaskQueueRunPath,
    'action_group_count': viewData.actionGroups.length,
    'queue_summary': viewData.queueSummary,
    'scheduler_summary': viewData.schedulerSummary,
  });
}

File _harryPotterSourceFile(
  HfvvWave1AppShellHarness harness, {
  required String runId,
}) {
  return File(
    '${harness.repoRoot.path}${Platform.pathSeparator}artifacts'
    '${Platform.pathSeparator}high_fidelity_viewmodel_validation'
    '${Platform.pathSeparator}$runId${Platform.pathSeparator}hfvv_03'
    '${Platform.pathSeparator}source_assets${Platform.pathSeparator}utf8'
    '${Platform.pathSeparator}harry_potter_volume1_raw_utf8.txt',
  );
}

String _latestAssistantText(List<ConversationEntryViewData> entries) {
  for (final entry in entries.reversed) {
    final body = entry.body.trim();
    if (body.isNotEmpty &&
        entry.toolLifecycleStatus == null &&
        !entry.isError &&
        entry.kind.name != 'user') {
      return body;
    }
  }
  for (final entry in entries.reversed) {
    final body = entry.body.trim();
    if (body.isNotEmpty && !entry.isError) {
      return body;
    }
  }
  return '';
}

bool _hasProjectPath(List<JsonMap> entries, List<String> prefixes) {
  for (final entry in entries) {
    final path = ValueReaders.stringValue(
      entry['relative_path'],
    ).replaceAll('\\', '/');
    for (final prefix in prefixes) {
      if (path.contains(prefix)) {
        return true;
      }
    }
  }
  return false;
}

int _anchorHitCount(String text, List<String> anchors) {
  var result = 0;
  for (final anchor in anchors) {
    if (text.contains(anchor)) {
      result += 1;
    }
  }
  return result;
}

Future<bool> _containsSourceLeak(
  HfvvWave1AppShellHarness harness, {
  required List<String> disallowedFragments,
}) async {
  final entries = await harness.listProjectEntries();
  for (final entry in entries) {
    final relativePath = ValueReaders.stringValue(entry['relative_path']);
    if (ValueReaders.boolValue(entry['is_dir'])) {
      continue;
    }
    if (!_looksTextLike(relativePath)) {
      continue;
    }
    final content = await harness.readProjectFile(relativePath);
    final cleanContent = content.replaceAll('\\', '/');
    for (final fragment in disallowedFragments) {
      final cleanFragment = fragment.replaceAll('\\', '/');
      if (cleanFragment.trim().isNotEmpty &&
          cleanContent.contains(cleanFragment)) {
        return true;
      }
    }
    if (containsProbableAbsolutePathLeak(cleanContent)) {
      return true;
    }
  }
  return false;
}

bool _looksTextLike(String relativePath) {
  final cleanPath = relativePath.toLowerCase();
  return cleanPath.endsWith('.json') ||
      cleanPath.endsWith('.md') ||
      cleanPath.endsWith('.txt') ||
      cleanPath.endsWith('.yaml') ||
      cleanPath.endsWith('.yml');
}

String _clip(String text, int maxLength) {
  final cleanText = text.trim();
  if (cleanText.length <= maxLength) {
    return cleanText;
  }
  return '${cleanText.substring(0, maxLength)}...';
}

JsonMap _laneExceptionReport({
  required JsonMap base,
  required Object error,
  required StackTrace stackTrace,
}) {
  final summary = '$error';
  return <String, Object?>{
    ...base,
    'ok': false,
    'report_category': _categorizeException(summary),
    'finished_at': DateTime.now().toIso8601String(),
    'error': summary,
    'stack_trace': '$stackTrace',
    'failures': <Object?>[
      <String, Object?>{
        'category': _categorizeException(summary),
        'summary': summary,
      },
    ],
  };
}

String _categorizeException(String summary) {
  final lower = summary.toLowerCase();
  if (lower.contains('timed out') ||
      lower.contains('429') ||
      lower.contains('quota') ||
      lower.contains('connection') ||
      lower.contains('socket') ||
      lower.contains('tls') ||
      lower.contains('api')) {
    return 'blocked_external';
  }
  return 'technical_failure';
}

String _fixLog(JsonMap report) {
  final ok = ValueReaders.boolValue(report['ok']);
  final category = ValueReaders.stringValue(report['report_category']);
  final summary = ok
      ? '本轮已完成 HFVV-06 真实运行与证据落盘。'
      : '本轮已冻结 HFVV-06 失败现场，等待 HFVV-07 进入生产链路修复与重跑。';
  return '''
# ${ValueReaders.stringValue(report['lane_id'])}

- status: ${ok ? 'passed' : 'failed'}
- report_category: $category
- note: $summary
''';
}

Future<void> _writeSummary(
  String repoRoot,
  JsonMap summary, {
  required String runId,
}) async {
  final root = Directory(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
    'high_fidelity_viewmodel_validation${Platform.pathSeparator}$runId',
  )..createSync(recursive: true);
  final jsonFile = File(
    '${root.path}${Platform.pathSeparator}hfvv_06_wave2_summary.json',
  );
  await jsonFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(summary)}\n',
  );
  final markdownFile = File(
    '${root.path}${Platform.pathSeparator}hfvv_06_wave2_summary.md',
  );
  final lanes = ValueReaders.objectList(summary['lanes']);
  final lines = <String>[
    '# HFVV-06 Wave 2 Summary',
    '',
    '- run_id: $runId',
    '- model_id: ${ValueReaders.stringValue(summary['model_id'])}',
    '- ok: ${ValueReaders.boolValue(summary['ok'])}',
    '',
    '## Lanes',
    '',
    for (final lane in lanes)
      '- ${ValueReaders.stringValue(ValueReaders.mapValue(lane)['lane_id'])}: ${ValueReaders.boolValue(ValueReaders.mapValue(lane)['ok']) ? 'passed' : ValueReaders.stringValue(ValueReaders.mapValue(lane)['report_category'])}',
  ];
  await markdownFile.writeAsString('${lines.join('\n')}\n');
}

const String _laneFPrompt = '''
请把当前项目当成“哈利波特第一卷知识已挂载的新同人项目”来推进，不要复述原作，也不要脱离当前知识范围胡编。

题材：
- 地球中国主角，前世是年老天师，死后转生到哈利波特世界，与哈利同级。
- 轻松向，但不能把重大剧情偏移写得没有代价。
- 请优先利用当前项目里已经挂载/提取出的哈利波特知识，而不是重新假装检索原作。

本轮目标：
1. 先用中文说明这条同人线会借用哪些原作事实、哪些地方会产生剧情偏移。
2. 给出一版开局方案。
3. 提供 800-1200 字试写。

要求：
- 明确区分“原作已知事实”和“本同人新增偏移”。
- 如果知识库不足，请直接指出不足点。
- 不要泄漏本机绝对路径。
''';

const String _laneFFollowUpPrompt = '''
继续按“先交代原作事实与偏移边界，再给开局方案和试写”的顺序完成这条哈利波特同人开局，不要跳回空泛口号。
''';

const String _laneGSeedPrompt = '''
请创建一个从零开始的长篇长任务项目，不要预先排出 1-60 章清单，而是让智能体自然规划推进。

题材：
- 历史科技轻喜剧。
- 现代社畜穿到明代后期江南小镇，靠基础化学、手工业改良、农业与物流常识一点点改变身边人。
- 节奏要稳，不是爽文暴冲。

硬要求：
- 涉及制度、工艺、农业、水利、交通、税契时，要优先形成资料请求或研究笔记，不能假装已经查过。
- 要求持续产出正文，允许中途停在 checkpoint / review / waiting_user，但要能继续推进。
- 不要写死章节提纲列表；自然规划即可。
''';

const String _laneHSeedPrompt = '''
请创建一个从零开始的多智能体长篇长任务项目，不要预先排出 1-60 章清单，而是让智能体自然规划推进。

题材：
- 仍然是“现代社畜穿到明代做小改良”，但这次明确要求多智能体协作。

协作要求：
- 主智能体负责总体推进与章节交付。
- 资料考据子智能体负责制度、技术、历史事实核查。
- 连续性子智能体负责角色状态、设定一致性和伏笔回收。
- 审核子智能体负责发现节奏断点、只读轮和质量风险。

硬要求：
- 真正调用子智能体，不要只口头模拟多视角。
- 不要预排整套章节清单。
- 长任务中要保留可诊断、可恢复的协作痕迹。
''';

const String _laneISeedPrompt = '''
请创建一个从零开始的高变化剧情长篇长任务项目，不要预先排出 1-60 章清单，而是让智能体自然规划推进。

题材：
- 只作为测试输入，不要把题材特性写进系统规则。
- 主角会在多个世界之间往返，但所有变化都必须有状态记录与因果代价。

世界锚点：
- 武侠世界
- 末世废土
- 魔法学园
- 现代都市

硬要求：
- 世界切换、回归、记忆残留、阶段目标都要能被持续记录。
- 不要写成无代价的乱跳。
- 允许章节中部发生转场，但叙事要连贯。
''';
