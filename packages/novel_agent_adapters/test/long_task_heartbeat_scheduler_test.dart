import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskHeartbeatScheduler', () {
    test(
      'collects due and stale events from active global runs only',
      () async {
        // 中文注释: scheduler 只扫描 registry 并产出心跳事件，不直接恢复任务，也不理会暂停或终态实例。
        final tempRoot = await Directory.systemTemp.createTemp(
          'novel-agent-heartbeat-scheduler-',
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
          final startedAt = DateTime.parse('2026-05-25T10:00:00.000Z');
          await registry.save(
            _runInstance(
              runId: 'run_due',
              projectId: 'project_due',
              projectName: '项目 Due',
              projectRootPath: 'D:/projects/due',
              status: LongTaskRunStatus.running,
              now: startedAt,
            ),
          );
          await registry.save(
            _runInstance(
              runId: 'run_paused',
              projectId: 'project_paused',
              projectName: '项目 Paused',
              projectRootPath: 'D:/projects/paused',
              status: LongTaskRunStatus.paused,
              now: startedAt,
            ),
          );

          final dueEvents = await scheduler.pollOnce(
            now: startedAt.add(const Duration(seconds: 46)),
          );
          final staleEvents = await scheduler.pollOnce(
            now: startedAt.add(const Duration(minutes: 6)),
          );

          expect(
            dueEvents.any((event) => event.runInstance.id == 'run_due'),
            isTrue,
          );
          expect(
            dueEvents.any((event) => event.runInstance.id == 'run_paused'),
            isFalse,
          );
          expect(
            staleEvents.any((event) => event.reason == 'stale_run'),
            isTrue,
          );
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
      storageStrategy: ProjectStorageStrategy.markdownProjectStore,
    ),
    runtimeBaseline: baseline,
    modeId: 'seed_autopilot_novel',
    workflowStrategyId: 'resumable_long_task',
    initialStatus: status,
    now: now,
  );
}
