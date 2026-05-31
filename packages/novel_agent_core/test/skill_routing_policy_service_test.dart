import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SkillRoutingPolicyService', () {
    test('builds planning policy with preload and reference routing', () {
      // 中文注释: 这里验证规划阶段会同时给出摘要预加载和后续 reference 细读路径。
      const service = SkillRoutingPolicyService();

      final signal = service.buildActivationSignal(
        intent: 'workflow_task',
        projectType: 'novel',
        userPrompt: '请先整理总纲、卷纲和角色关系。',
        routeContext: const <String, Object?>{
          'task_type': 'planning',
          'mode': 'seed_to_full_novel',
        },
      );
      final policy = service.resolvePolicy(signal);
      final memory = SkillLoadMemory();
      final preloadCalls = service.buildPreloadToolCalls(policy, memory);
      final guidanceLines = service.buildGuidanceLines(policy);

      expect(policy.stageId, 'planning');
      expect(
        preloadCalls.map((call) => call['name']),
        everyElement('load_agent_skill'),
      );
      expect(
        preloadCalls.map(
          (call) => ValueReaders.mapValue(call['arguments'])['skill_id'],
        ),
        contains('novel-control-station'),
      );
      expect(
        guidanceLines.join('\n'),
        contains('references/interview-and-handoff-flow.md'),
      );
    });

    test('builds revision policy with authenticity reference when needed', () {
      // 中文注释: 这里验证修订阶段会把去 AI/自然化压力映射成 reference 细读候选。
      const service = SkillRoutingPolicyService();

      final signal = service.buildActivationSignal(
        intent: 'draft',
        projectType: 'novel',
        userPrompt: '请修订这一章并去掉明显 ai 味。',
        routeContext: const <String, Object?>{'task_type': 'revision'},
      );
      final policy = service.resolvePolicy(signal);
      final routedReferences = policy.presets
          .where((preset) => preset.skillId == 'novel-control-station')
          .expand((preset) => preset.referencePaths)
          .toList(growable: false);

      expect(policy.stageId, 'revision');
      expect(routedReferences, contains('references/authenticity-and-de-ai-pass.md'));
    });
  });
}
