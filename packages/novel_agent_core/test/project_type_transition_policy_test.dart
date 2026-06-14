import 'package:novel_agent_core/src/project/project_storage_strategy.dart';
import 'package:novel_agent_core/src/project/project_type_transition_blocker.dart';
import 'package:novel_agent_core/src/project/project_type_transition_policy.dart';
import 'package:novel_agent_core/src/project/project_type_transition_request.dart';
import 'package:test/test.dart';

void main() {
  const policy = ProjectTypeTransitionPolicy();

  test(
    'first phase graph only exposes novel and long_novel as transition targets',
    () {
      // 中文注释: 这里先锁定静态转换图，避免后续 GUI 或 controller 自己脑补更多边。
      expect(policy.availableTargetProjectTypeIds('novel'), <String>[
        'long_novel',
      ]);
      expect(policy.availableTargetProjectTypeIds('long_novel'), <String>[
        'novel',
      ]);
      expect(policy.availableTargetProjectTypeIds('knowledge_base'), isEmpty);
    },
  );

  test(
    'novel to long_novel needs runtime baseline selection before it can transition',
    () {
      // 中文注释: 普通小说切到长篇长任务时，必须先补齐运行基准，否则计划只能给出可读的阻断原因。
      final plan = policy.plan(
        const ProjectTypeTransitionRequest(
          sourceProjectTypeId: 'novel',
          targetProjectTypeId: 'long_novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        ),
      );

      expect(plan.canTransition, isFalse);
      expect(plan.requiresRuntimeBaselineSelection, isTrue);
      expect(plan.targetRuntimeBaselineId, isEmpty);
      expect(
        plan.blockers.map((item) => item.code),
        contains(ProjectTypeTransitionBlockerCodes.missingRuntimeBaseline),
      );
    },
  );

  test(
    'novel to long_novel keeps the same storage strategy once runtime baseline exists',
    () {
      // 中文注释: 当运行基准已经选定后，第一阶段的类型转换应当保留原存储策略，不顺手做迁移。
      final plan = policy.plan(
        const ProjectTypeTransitionRequest(
          sourceProjectTypeId: 'novel',
          targetProjectTypeId: 'long_novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          currentRuntimeBaselineId: 'continuous_autonomous',
        ),
      );

      expect(plan.canTransition, isTrue);
      expect(plan.preservesStorageStrategy, isTrue);
      expect(
        plan.targetStorageStrategy,
        ProjectStorageStrategy.sqliteProjectStore,
      );
      expect(plan.targetRuntimeBaselineId, 'continuous_autonomous');
      expect(plan.blockers, isEmpty);
    },
  );

  test(
    'long_novel to novel is blocked while an active long task is still running',
    () {
      // 中文注释: 回切普通小说前，活跃长任务必须先归档，否则类型切换会和运行现场直接打架。
      final plan = policy.plan(
        const ProjectTypeTransitionRequest(
          sourceProjectTypeId: 'long_novel',
          targetProjectTypeId: 'novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
          hasActiveLongTaskRun: true,
        ),
      );

      expect(plan.canTransition, isFalse);
      expect(plan.requiresLongTaskArchiveCheck, isTrue);
      expect(
        plan.blockers.map((item) => item.code),
        contains(ProjectTypeTransitionBlockerCodes.activeLongTaskNotArchived),
      );
    },
  );

  test('knowledge base stays outside the first phase transition graph', () {
    // 中文注释: 知识库在第一阶段只做 sqlite-only 项目，不参与写作壳互转。
    final plan = policy.plan(
      const ProjectTypeTransitionRequest(
        sourceProjectTypeId: 'novel',
        targetProjectTypeId: 'knowledge_base',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      ),
    );

    expect(plan.canTransition, isFalse);
    expect(
      plan.blockers.map((item) => item.code),
      contains(ProjectTypeTransitionBlockerCodes.transitionNotInFirstPhase),
    );
  });
}
