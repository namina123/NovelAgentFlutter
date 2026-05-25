import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskSupervisor', () {
    test(
      'tracks runs, updates heartbeats and delegates scheduler pulses',
      () async {
        // 中文注释: supervisor 只编排 registry 和 scheduler，不直接改 workflow；这里验证三者边界已经分开。
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
          final supervisor = LongTaskSupervisor(
            runRegistry: registry,
            heartbeatScheduler: scheduler,
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

          final beatAt = startedAt.add(const Duration(seconds: 20));
          final updated = await supervisor.markHeartbeat(
            'run_supervisor',
            occurredAt: beatAt,
            note: 'scheduler_ping',
          );
          final events = await supervisor.pulseOnce(
            now: beatAt.add(const Duration(seconds: 46)),
          );

          expect(updated, isNotNull);
          expect(updated!.lastHeartbeatAt, beatAt);
          expect(events, hasLength(1));
          expect(events.first.runInstance.id, 'run_supervisor');
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
            heartbeatScheduler: scheduler,
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
