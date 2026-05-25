import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project agent binding services', () {
    test('normalizes project binding with nested model override', () {
      final normalizer = ProjectAgentBindingNormalizerService();

      final binding = normalizer.normalize(<String, Object?>{
        'agent_id': 'writer',
        'display_name': '正文作者',
        'selected_by_default': true,
        'modes': <String>['novel'],
        'stages': <String>['draft'],
        'style_binding_ids': <String>['main_style'],
        'model_override': <String, Object?>{
          'provider_profile': 'deepseek-main',
          'model_id': 'deepseek-v4-pro',
          'thinking_enabled': true,
          'temperature': 0.66,
          'advanced_model_overrides': <Object?>[
            <String, Object?>{'key': 'seed', 'type': 'integer', 'value': 7},
          ],
        },
      });

      expect(binding.agentId, 'writer');
      expect(binding.selectedByDefault, isTrue);
      expect(binding.modeIds, <String>['novel']);
      expect(binding.stageIds, <String>['draft']);
      expect(binding.styleBindingIds, <String>['main_style']);
      expect(binding.modelOverride, isNotNull);
      expect(binding.modelOverride!.modelId, 'deepseek-v4-pro');
      expect(binding.modelOverride!.thinkingEnabled, isTrue);
    });

    test('resolver keeps only active bindings in current scope', () {
      final resolver = ProjectAgentBindingResolverService();
      final active = resolver.resolveActiveBindings(
        <ProjectAgentBinding>[
          const ProjectAgentBinding(
            agentId: 'writer',
            selectedByDefault: true,
            modeIds: <String>['novel'],
            stageIds: <String>['draft'],
          ),
          const ProjectAgentBinding(
            agentId: 'reviewer',
            modeIds: <String>['review'],
          ),
          const ProjectAgentBinding(agentId: 'disabled', enabled: false),
        ],
        modeId: 'novel',
        stageId: 'draft',
      );

      expect(active.map((item) => item.agentId), <String>['writer']);
    });
  });
}
