import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LocalLongTaskRunRegistry', () {
    test(
      'persists and reloads global run instances under settings root',
      () async {
        // 中文注释: 这里验证全局 run registry 真正落在设置根目录，而不是偷偷混进某个项目目录或页面状态。
        final tempRoot = await Directory.systemTemp.createTemp(
          'novel-agent-run-registry-',
        );
        try {
          final registry = LocalLongTaskRunRegistry(
            settingsRootPath: tempRoot.path,
          );
          final instance = _runInstance(
            runId: 'Run_A',
            projectId: 'project_a',
            projectName: '项目 A',
            projectRootPath: 'D:/projects/a',
            status: LongTaskRunStatus.running,
            now: DateTime.parse('2026-05-25T10:00:00.000Z'),
          ).copyWith(
            stopOutcome: const LongTaskStopOutcome(
              present: true,
              category: LongTaskStopOutcomeCategories.waitingUser,
              reason: 'waiting_user_checkpoint',
              legacyStopReason: 'waiting_user_checkpoint',
              summary: '等待用户确认。',
            ),
            recoveryState: const LongTaskRecoveryState(
              present: true,
              state: LongTaskRecoveryStates.waitingUser,
              runStatus: 'waiting_gate',
              recommendedAction: 'resume_when_user_confirms',
              reason: 'waiting_user_checkpoint',
              note: '等待用户确认。',
              waitingUser: true,
              blocksProgress: true,
            ),
          );

          await registry.save(instance);

          final reloaded = await registry.findById('Run_A');
          final all = await registry.listAll();
          final byProject = await registry.listByProject('D:/projects/a');

          expect(reloaded, isNotNull);
          expect(reloaded!.project.title, '项目 A');
          expect(reloaded.runtimeBaselineId, 'continuous_autonomous');
          expect(
            reloaded.stopOutcome.category,
            LongTaskStopOutcomeCategories.waitingUser,
          );
          expect(reloaded.stopOutcome.reason, 'waiting_user_checkpoint');
          expect(reloaded.recoveryState.state, LongTaskRecoveryStates.waitingUser);
          expect(all, hasLength(1));
          expect(byProject, hasLength(1));
        } finally {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        }
      },
    );

    test(
      'stores project paths relative to settings root and reloads them as absolute paths',
      () async {
        final tempRoot = await Directory.systemTemp.createTemp(
          'novel-agent-run-registry-relative-',
        );
        try {
          final registry = LocalLongTaskRunRegistry(
            settingsRootPath: tempRoot.path,
          );
          final projectRootPath =
              '${tempRoot.path}${Platform.pathSeparator}projects${Platform.pathSeparator}demo_project';
          final instance = _runInstance(
            runId: 'Run_B',
            projectId: 'project_b',
            projectName: '项目 B',
            projectRootPath: projectRootPath,
            status: LongTaskRunStatus.running,
            now: DateTime.parse('2026-05-25T10:30:00.000Z'),
          );

          await registry.save(instance);

          final raw = await File(
            '${tempRoot.path}${Platform.pathSeparator}long_task_runtime${Platform.pathSeparator}runs${Platform.pathSeparator}run_b.json',
          ).readAsString();
          final reloaded = await registry.findById('Run_B');

          expect(raw, contains('"project_key": "projects/demo_project"'));
          expect(raw, contains('"root_path": "projects/demo_project"'));
          expect(reloaded, isNotNull);
          expect(reloaded!.project.projectKey, projectRootPath);
          expect(reloaded.project.rootPath, projectRootPath);
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
