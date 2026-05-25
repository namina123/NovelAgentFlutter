import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultLongTaskHeartbeatPolicy', () {
    const policy = DefaultLongTaskHeartbeatPolicy();
    const factory = RunInstanceFactoryService();
    const baselineCatalog = RuntimeBaselineCatalogService();
    final baseline = baselineCatalog.byId('continuous_autonomous')!;
    final project = ProjectDescriptor(
      id: 'heartbeat_project',
      name: '心跳测试项目',
      rootPath: 'D:/projects/heartbeat',
      projectType: 'long_novel',
      storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
    );

    test('tracks heartbeat only for active global run states', () {
      // 中文注释: 心跳合同只服务真正的全局运行态，暂停、引导和终态都不应该继续索要心跳。
      final now = DateTime.parse('2026-05-25T10:00:00.000Z');
      final running = factory.createLongTaskInstance(
        runId: 'heartbeat_run',
        project: project,
        runtimeBaseline: baseline,
        modeId: 'seed_autopilot_novel',
        workflowStrategyId: 'resumable_long_task',
        initialStatus: LongTaskRunStatus.running,
        now: now,
      );
      final paused = running.copyWith(
        status: LongTaskRunStatus.paused,
        updatedAt: now,
      );

      expect(
        policy.heartbeatIntervalFor(running, baseline),
        greaterThan(Duration.zero),
      );
      expect(
        policy.nextHeartbeatAt(running, baseline),
        now.add(const Duration(seconds: 45)),
      );
      expect(policy.nextHeartbeatAt(paused, baseline), isNull);
    });

    test('reports due and stale heartbeats without auto recovery behavior', () {
      // 中文注释: 这轮只定义“何时该打心跳、何时算陈旧”，并不在策略层偷偷引入自动恢复动作。
      final startedAt = DateTime.parse('2026-05-25T10:00:00.000Z');
      final instance = factory.createLongTaskInstance(
        runId: 'heartbeat_run_2',
        project: project,
        runtimeBaseline: baseline,
        modeId: 'seed_autopilot_novel',
        workflowStrategyId: 'resumable_long_task',
        initialStatus: LongTaskRunStatus.running,
        now: startedAt,
      );

      expect(
        policy.isHeartbeatDue(
          instance,
          baseline,
          now: startedAt.add(const Duration(seconds: 46)),
        ),
        isTrue,
      );
      expect(
        policy.isStale(
          instance,
          baseline,
          now: startedAt.add(const Duration(minutes: 6)),
        ),
        isTrue,
      );
    });
  });
}
