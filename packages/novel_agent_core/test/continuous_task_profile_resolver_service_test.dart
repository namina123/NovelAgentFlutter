import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuousTaskProfileResolverService', () {
    const resolver = ContinuousTaskProfileResolverService();

    test('maps long task modes onto shared continuous task contract', () {
      // 中文注释: 长任务仍保留既有 mode id，但这里要证明它已经能落到统一的连续任务族合同，而不是只能走 LongTask* 私有语义。
      final profile = resolver.forLongTaskMode(
        TaskRuntimeConstants.modeSeedToFullNovel,
        workflowStrategyId: 'resumable_long_task',
      );

      expect(profile.familyId, ContinuousTaskFamilies.longFormWriting);
      expect(profile.runKind, ContinuousTaskRunKinds.chapterQueue);
      expect(profile.supportsLivenessControl, isTrue);
      expect(profile.workflowStrategyId, 'resumable_long_task');
      expect(profile.modeId, TaskRuntimeConstants.modeSeedToFullNovel);
    });

    test('maps goal mode onto same pause resume recovery semantics', () {
      // 中文注释: 目标模式没有章节队列，但必须共享 pause/resume/recover 这套连续任务基础语义。
      final profile = resolver.forGoalMode(
        metadata: const <String, Object?>{'objective_id': 'goal-1'},
      );

      expect(profile.familyId, ContinuousTaskFamilies.goalMode);
      expect(profile.runKind, ContinuousTaskRunKinds.conversationLoop);
      expect(profile.supportsPause, isTrue);
      expect(profile.supportsResume, isTrue);
      expect(profile.supportsRecovery, isTrue);
      expect(profile.metadata['objective_id'], 'goal-1');
    });

    test(
      'maps reference extraction onto shared contract without losing batch metadata',
      () {
        // 中文注释: 参考提取要成为连续任务正式对象，同时保留 execution discipline 这类提取专属元数据，不能被长任务合同吞掉。
        final profile = resolver.forReferenceExtraction(
          workflowStrategyId:
              ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
          executionDiscipline: const ReferenceExtractionExecutionDiscipline(
            concurrencyMode: ReferenceExtractionConcurrencyModes.single,
          ),
        );

        expect(profile.familyId, ContinuousTaskFamilies.referenceExtraction);
        expect(profile.runKind, ContinuousTaskRunKinds.batchPipeline);
        expect(profile.supportsLivenessControl, isTrue);
        expect(
          profile.workflowStrategyId,
          ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              profile.metadata['execution_discipline'],
            )['concurrency_mode'],
          ),
          ReferenceExtractionConcurrencyModes.single,
        );
      },
    );

    test('maps research consolidation onto shared contract', () {
      // 中文注释: 研究整编后续会进入 watchdog/supervisor 主链，这里先确认它已经有稳定 family 与 run kind 映射。
      final profile = resolver.forResearchConsolidation();

      expect(profile.familyId, ContinuousTaskFamilies.researchConsolidation);
      expect(profile.runKind, ContinuousTaskRunKinds.researchSweep);
      expect(profile.supportsRetry, isTrue);
      expect(profile.supportsRecovery, isTrue);
    });

    test('round-trips continuous task profile as stable json contract', () {
      // 中文注释: 连续任务合同后续会被 runtime/probe/GUI/CLI 共同消费，因此必须先证明 JSON 合同稳定可回放。
      final original = resolver.resolve(
        familyId: ContinuousTaskFamilies.goalMode,
        workflowStrategyId: 'goal_mode',
        metadata: const <String, Object?>{'objective_id': 'goal-2'},
      );

      final restored = ContinuousTaskProfile.fromJson(original.toJson());

      expect(restored.familyId, original.familyId);
      expect(restored.runKind, original.runKind);
      expect(restored.supportsLivenessControl, isTrue);
      expect(restored.metadata['objective_id'], 'goal-2');
    });
  });
}
