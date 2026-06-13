import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskSupervisor', () {
    test(
      'tracks runs and exposes watchdog running state without owning heartbeat mechanics',
      () async {
        // 中文注释: supervisor 本轮只保留状态调度与结构结果消费；watchdog 运行态只作为只读边界透出。
        final tempRoot = await Directory.systemTemp.createTemp(
          'novel-agent-supervisor-',
        );
        try {
          final registry = LocalLongTaskRunRegistry(
            settingsRootPath: tempRoot.path,
          );
          final scheduler = LongTaskHeartbeatScheduler(
            runRegistry: registry,
            runtimeBaselineCatalogService:
                const RuntimeBaselineCatalogService(),
          );
          final watchdog = LongTaskWatchdog(
            runRegistry: registry,
            heartbeatScheduler: scheduler,
          );
          final supervisor = LongTaskSupervisor(
            runRegistry: registry,
            watchdogDispatchPort: watchdog,
          );
          final startedAt = DateTime.parse('2026-05-25T10:00:00.000Z');
          final instance = _runInstance(
            runId: 'run_supervisor',
            projectId: 'project_supervisor',
            projectName: '项目 Supervisor',
            projectRootPath: 'D:/projects/supervisor',
            status: LongTaskRunStatus.running,
            now: startedAt,
          );

          await supervisor.trackRun(instance);
          final tracked = await supervisor.loadRun('run_supervisor');
          final activeRuns = await supervisor.listActiveRuns();
          final projectRuns = await supervisor.listProjectRuns(
            'D:/projects/supervisor',
          );

          expect(tracked, isNotNull);
          expect(activeRuns, hasLength(1));
          expect(projectRuns, hasLength(1));
          expect(supervisor.isRunning, isFalse);

          watchdog.start();
          expect(supervisor.isRunning, isTrue);
          await watchdog.stop();
          expect(supervisor.isRunning, isFalse);
        } finally {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        }
      },
    );

    test(
      'pause, resume and stop transition through core state machine',
      () async {
        final tempRoot = await Directory.systemTemp.createTemp(
          'novel-agent-supervisor-transition-',
        );
        try {
          final registry = LocalLongTaskRunRegistry(
            settingsRootPath: tempRoot.path,
          );
          final scheduler = LongTaskHeartbeatScheduler(
            runRegistry: registry,
            runtimeBaselineCatalogService:
                const RuntimeBaselineCatalogService(),
          );
          final supervisor = LongTaskSupervisor(
            runRegistry: registry,
            watchdogDispatchPort: LongTaskWatchdog(
              runRegistry: registry,
              heartbeatScheduler: scheduler,
            ),
          );
          final now = DateTime.parse('2026-05-25T12:00:00.000Z');
          final instance = _runInstance(
            runId: 'run_transition',
            projectId: 'project_transition',
            projectName: '项目 Transition',
            projectRootPath: 'D:/projects/transition',
            status: LongTaskRunStatus.running,
            now: now,
          );

          await supervisor.trackRun(instance);
          final paused = await supervisor.pauseRun(
            'run_transition',
            occurredAt: now.add(const Duration(seconds: 30)),
            note: 'manual_pause',
          );
          final resumed = await supervisor.resumeRun(
            'run_transition',
            occurredAt: now.add(const Duration(minutes: 1)),
            note: 'manual_resume',
          );
          final stopped = await supervisor.stopRun(
            'run_transition',
            occurredAt: now.add(const Duration(minutes: 2)),
            note: 'manual_stop',
            stopReason: 'user_requested',
          );

          expect(paused, isNotNull);
          expect(paused!.status, LongTaskRunStatus.paused);
          expect(paused.note, 'manual_pause');

          expect(resumed, isNotNull);
          expect(resumed!.status, LongTaskRunStatus.running);
          expect(resumed.note, 'manual_resume');

          expect(stopped, isNotNull);
          expect(stopped!.status, LongTaskRunStatus.stopped);
          expect(stopped.stopReason, 'user_requested');
          expect(stopped.note, 'manual_stop');
        } finally {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        }
      },
    );

    test(
      'applyWritingExecutionResult maps shared category into run metadata',
      () async {
        final tempRoot = await Directory.systemTemp.createTemp(
          'novel-agent-supervisor-writing-result-',
        );
        try {
          final registry = LocalLongTaskRunRegistry(
            settingsRootPath: tempRoot.path,
          );
          final scheduler = LongTaskHeartbeatScheduler(
            runRegistry: registry,
            runtimeBaselineCatalogService:
                const RuntimeBaselineCatalogService(),
          );
          final supervisor = LongTaskSupervisor(
            runRegistry: registry,
            watchdogDispatchPort: LongTaskWatchdog(
              runRegistry: registry,
              heartbeatScheduler: scheduler,
            ),
          );
          final now = DateTime.parse('2026-05-25T14:00:00.000Z');
          final instance = _runInstance(
            runId: 'run_writing_execution',
            projectId: 'project_writing_execution',
            projectName: '项目 Shared Result',
            projectRootPath: 'D:/projects/shared-result',
            status: LongTaskRunStatus.running,
            now: now,
          );
          await supervisor.trackRun(instance);

          final updated = await supervisor.applyWritingExecutionResult(
            'run_writing_execution',
            <String, Object?>{
              'execution_id': 'task_001',
              'workflow_kind': 'workflow_task',
              'overall_status':
                  WritingExecutionOutcomeStatuses.contentQualityIssue,
              'summary': '正文质量不达标，需要人工复核。',
              'delivery': const <String, Object?>{
                'present': true,
                'state': 'invalid_output_rewrite_required',
                'summary': '正文质量不达标，需要人工复核。',
                'blocks_progress': true,
              },
              'constraints': const <String, Object?>{},
              'information': const <String, Object?>{},
              'collaboration': const <String, Object?>{},
              'recovery': const <String, Object?>{},
              'next_action': '',
              'blocks_progress': true,
              'retryable': false,
              'requires_user_action': false,
              'schema_version': 1,
              'metadata': const <String, Object?>{},
            },
          );

          expect(updated, isNotNull);
          expect(updated!.status, LongTaskRunStatus.failedManualAttention);
          expect(updated.note, contains('人工复核'));
          expect(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                updated.metadata,
              )['writing_execution_signal'],
            ).isNotEmpty,
            isTrue,
          );
        } finally {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        }
      },
    );

    test('applyRecoveryState persists formal recovery state onto run instance', () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'novel-agent-supervisor-recovery-state-',
      );
      try {
        final registry = LocalLongTaskRunRegistry(
          settingsRootPath: tempRoot.path,
        );
        final scheduler = LongTaskHeartbeatScheduler(
          runRegistry: registry,
          runtimeBaselineCatalogService:
              const RuntimeBaselineCatalogService(),
        );
        final supervisor = LongTaskSupervisor(
          runRegistry: registry,
          watchdogDispatchPort: LongTaskWatchdog(
            runRegistry: registry,
            heartbeatScheduler: scheduler,
          ),
        );
        final now = DateTime.parse('2026-05-25T18:00:00.000Z');
        final instance = _runInstance(
          runId: 'run_recovery_state',
          projectId: 'project_recovery_state',
          projectName: '项目 Recovery State',
          projectRootPath: 'D:/projects/recovery-state',
          status: LongTaskRunStatus.running,
          now: now,
        );
        await supervisor.trackRun(instance);

        final updated = await supervisor.applyRecoveryState(
          'run_recovery_state',
          <String, Object?>{
            'recovery_state': const LongTaskRecoveryState(
              present: true,
              state: LongTaskRecoveryStates.exhausted,
              runStatus: 'failed_manual_attention',
              recommendedAction: 'pause_for_manual_attention',
              reason: 'recovery_exhausted',
              note: '自动重试预算已耗尽，升级为人工处理。',
              retryCount: 2,
              retryBudget: 2,
              retriesRemaining: 0,
              autoRetryEligible: true,
              blocksProgress: true,
              manualAttentionRequired: true,
              exhausted: true,
              exhaustedDisposition: 'manual_attention',
              stopOutcome: LongTaskStopOutcome(
                present: true,
                category: LongTaskStopOutcomeCategories.recoveryExhausted,
                reason: 'recovery_exhausted',
                legacyStopReason: 'recovery_exhausted',
                summary: '自动重试预算已耗尽。',
              ),
            ).toJson(),
          },
          occurredAt: now.add(const Duration(minutes: 1)),
        );

        expect(updated, isNotNull);
        expect(updated!.status, LongTaskRunStatus.failedManualAttention);
        expect(updated.recoveryState.state, LongTaskRecoveryStates.exhausted);
        expect(
          updated.stopOutcome.category,
          LongTaskStopOutcomeCategories.recoveryExhausted,
        );
      } finally {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      }
    });
  });

  group('LongTaskWatchdog', () {
    test(
      'handles heartbeat, stale polling and orphan dispatch reconcile without doing supervisor state transitions',
      () async {
        final tempRoot = await Directory.systemTemp.createTemp(
          'novel-agent-watchdog-',
        );
        try {
          final registry = LocalLongTaskRunRegistry(
            settingsRootPath: tempRoot.path,
          );
          final scheduler = LongTaskHeartbeatScheduler(
            runRegistry: registry,
            runtimeBaselineCatalogService:
                const RuntimeBaselineCatalogService(),
          );
          final watchdog = LongTaskWatchdog(
            runRegistry: registry,
            heartbeatScheduler: scheduler,
          );
          final startedAt = DateTime.parse('2026-05-25T16:00:00.000Z');
          final activeRun = _runInstance(
            runId: 'run_watchdog_active',
            projectId: 'project_watchdog',
            projectName: '项目 Watchdog',
            projectRootPath: 'D:/projects/watchdog',
            status: LongTaskRunStatus.running,
            now: startedAt,
          );
          await registry.save(activeRun);

          final heartbeatUpdated = await watchdog.markHeartbeat(
            activeRun.id,
            occurredAt: startedAt.add(const Duration(seconds: 20)),
            note: 'watchdog_ping',
          );
          expect(heartbeatUpdated, isNotNull);
          expect(
            heartbeatUpdated!.lastHeartbeatAt,
            startedAt.add(const Duration(seconds: 20)),
          );

          final firstPulse = await watchdog.pulseOnce(
            now: startedAt.add(const Duration(seconds: 66)),
          );
          expect(firstPulse.heartbeatEvents, hasLength(1));
          expect(firstPulse.orphanDispatchStateReconciledCount, 0);

          await registry.delete(activeRun.id);

          final secondPulse = await watchdog.pulseOnce(
            now: startedAt.add(const Duration(seconds: 70)),
          );
          expect(secondPulse.heartbeatEvents, isEmpty);
          expect(secondPulse.orphanDispatchStateReconciledCount, 1);
        } finally {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        }
      },
    );
  });
}

RunInstance _runInstance({
  required String runId,
  required String projectId,
  required String projectName,
  required String projectRootPath,
  required LongTaskRunStatus status,
  required DateTime now,
}) {
  final baseline = const RuntimeBaselineCatalogService().byId(
    'continuous_autonomous',
  )!;
  return const RunInstanceFactoryService().createLongTaskInstance(
    runId: runId,
    project: ProjectDescriptor(
      id: projectId,
      name: projectName,
      rootPath: projectRootPath,
      projectType: 'long_novel',
      storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
    ),
    runtimeBaseline: baseline,
    modeId: 'seed_autopilot_novel',
    workflowStrategyId: 'resumable_long_task',
    initialStatus: status,
    now: now,
  );
}
