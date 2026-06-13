import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuousTaskSupervisorBridgeService', () {
    test(
      'tracks reference extraction and research runs as formal watchdog objects',
      () async {
        final tempRoot = await Directory.systemTemp.createTemp(
          'continuous-task-supervisor-bridge-',
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
          final bridge = ContinuousTaskSupervisorBridgeService(
            supervisor: supervisor,
          );
          final startedAt = DateTime.parse('2026-06-08T10:00:00.000Z');
          final project = ProjectDescriptor(
            id: 'project_bridge',
            name: '连续任务控制桥测试项目',
            rootPath: tempRoot.path,
            storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          );

          await bridge.trackTaskFamilyRun(
            runId: 'reference_run',
            project: project,
            familyId: ContinuousTaskFamilies.referenceExtraction,
            workflowStrategyId: 'reference_extraction.standard',
            activeTaskTitle: '参考提取',
            occurredAt: startedAt,
          );
          await bridge.trackTaskFamilyRun(
            runId: 'research_run',
            project: project,
            familyId: ContinuousTaskFamilies.researchConsolidation,
            workflowStrategyId: 'research_consolidation',
            activeTaskTitle: '研究整编',
            occurredAt: startedAt,
          );

          final activeRuns = await supervisor.listActiveRuns();
          final pulse = await watchdog.pulseOnce(
            now: startedAt.add(const Duration(minutes: 1)),
          );
          final referenceRun = await supervisor.loadRun('reference_run');
          final researchRun = await supervisor.loadRun('research_run');

          expect(activeRuns, hasLength(2));
          expect(
            activeRuns.map((run) => run.id),
            containsAll(<String>['reference_run', 'research_run']),
          );
          expect(pulse.heartbeatEvents, hasLength(2));
          expect(
            ValueReaders.stringValue(
              referenceRun!.metadata['continuous_task_family_id'],
            ),
            ContinuousTaskFamilies.referenceExtraction,
          );
          expect(
            ValueReaders.stringValue(
              researchRun!.metadata['continuous_task_family_id'],
            ),
            ContinuousTaskFamilies.researchConsolidation,
          );
        } finally {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        }
      },
    );

    test(
      'reuses shared supervisor path for pause, resume, recover and retry',
      () async {
        final tempRoot = await Directory.systemTemp.createTemp(
          'continuous-task-supervisor-bridge-state-',
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
          final bridge = ContinuousTaskSupervisorBridgeService(
            supervisor: supervisor,
          );
          final startedAt = DateTime.parse('2026-06-08T12:00:00.000Z');
          final project = ProjectDescriptor(
            id: 'project_bridge_state',
            name: '连续任务桥状态测试项目',
            rootPath: tempRoot.path,
          );

          await bridge.trackTaskFamilyRun(
            runId: 'research_state_run',
            project: project,
            familyId: ContinuousTaskFamilies.researchConsolidation,
            workflowStrategyId: 'research_consolidation',
            activeTaskTitle: '研究整编状态链',
            occurredAt: startedAt,
          );

          final paused = await bridge.pauseRun(
            'research_state_run',
            occurredAt: startedAt.add(const Duration(minutes: 1)),
            note: 'pause_for_followup',
            reason: 'coverage_followup_required',
          );
          final resumed = await bridge.resumeRun(
            'research_state_run',
            occurredAt: startedAt.add(const Duration(minutes: 2)),
            note: 'resume_after_followup',
          );
          final recovering = await bridge.recoverRun(
            'research_state_run',
            occurredAt: startedAt.add(const Duration(minutes: 3)),
            note: 'technical_retry_window',
          );
          final retried = await bridge.retryRun(
            'research_state_run',
            occurredAt: startedAt.add(const Duration(minutes: 4)),
            note: 'retry_dispatched',
          );

          expect(paused, isNotNull);
          expect(paused!.status, LongTaskRunStatus.paused);
          expect(
            paused.stopOutcome.category,
            LongTaskStopOutcomeCategories.constraintGatePause,
          );

          expect(resumed, isNotNull);
          expect(resumed!.status, LongTaskRunStatus.running);

          expect(recovering, isNotNull);
          expect(recovering!.status, LongTaskRunStatus.recovering);
          expect(
            recovering.recoveryState.state,
            LongTaskRecoveryStates.resumeReady,
          );
          expect(
            recovering.recoveryState.stopOutcome.category,
            LongTaskStopOutcomeCategories.technicalFailure,
          );
          expect(
            recovering.recoveryState.stopOutcome.summary,
            'technical_retry_window',
          );

          expect(retried, isNotNull);
          expect(retried!.status, LongTaskRunStatus.running);
          expect(retried.recoveryState.state, LongTaskRecoveryStates.retrying);
        } finally {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        }
      },
    );
  });
}
