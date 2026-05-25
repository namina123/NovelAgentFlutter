import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskRunStateMachine', () {
    const factory = RunInstanceFactoryService();
    const machine = LongTaskRunStateMachine();
    const baselineCatalog = RuntimeBaselineCatalogService();
    final baseline = baselineCatalog.byId('continuous_autonomous')!;
    final project = ProjectDescriptor(
      id: 'global_run_demo',
      name: '全局运行测试项目',
      rootPath: 'D:/projects/demo',
      projectType: 'long_novel',
      storageStrategy: ProjectStorageStrategy.markdownProjectStore,
    );

    test(
      'creates run instance with project association outside page state',
      () {
        // 中文注释: 运行实例必须自带项目引用和运行基线，才能在切换页面或切换项目后继续作为全局对象存在。
        final instance = factory.createLongTaskInstance(
          runId: 'run_001',
          project: project,
          runtimeBaseline: baseline,
          modeId: 'seed_autopilot_novel',
          workflowStrategyId: 'resumable_long_task',
        );

        expect(instance.project.projectId, project.id);
        expect(instance.project.projectKey, project.rootPath);
        expect(instance.runtimeBaselineId, baseline.id);
        expect(instance.status, LongTaskRunStatus.draftingGuidance);
        expect(instance.isGlobal, isTrue);
      },
    );

    test('allows valid long task transitions and marks stop as terminal', () {
      // 中文注释: 基础状态机现在只管运行态推进，不让 UI 或 adapter 自由拼接非法状态跳转。
      final base = factory.createLongTaskInstance(
        runId: 'run_002',
        project: project,
        runtimeBaseline: baseline,
        modeId: 'seed_autopilot_novel',
        workflowStrategyId: 'resumable_long_task',
      );
      final ready = machine.transition(base, LongTaskRunStatus.readyToStart);
      final running = machine.transition(ready, LongTaskRunStatus.running);
      final gate = machine.transition(running, LongTaskRunStatus.waitingGate);
      final stopped = machine.transition(
        gate,
        LongTaskRunStatus.stopped,
        stopReason: 'completed',
      );

      expect(running.startedAt, isNotNull);
      expect(stopped.isTerminal, isTrue);
      expect(stopped.stopReason, 'completed');
      expect(stopped.stoppedAt, isNotNull);
    });

    test('rejects invalid transition from stopped back to running', () {
      // 中文注释: 终态运行实例不能被直接改回运行中，后续如果需要重开，应创建新的 run instance。
      final base = factory.createLongTaskInstance(
        runId: 'run_003',
        project: project,
        runtimeBaseline: baseline,
        modeId: 'seed_autopilot_novel',
        workflowStrategyId: 'resumable_long_task',
        initialStatus: LongTaskRunStatus.stopped,
      );

      expect(
        () => machine.transition(base, LongTaskRunStatus.running),
        throwsStateError,
      );
    });
  });
}
