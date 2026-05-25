import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ModeGuidanceAssetContextSectionService', () {
    test('builds style, world and entity memory sections from bundle', () {
      const service = ModeGuidanceAssetContextSectionService();

      final sections = service.build(
        const ModeGuidanceAssetBundle(
          modeId: 'seed_autopilot_novel',
          styleProfiles: <StyleProfile>[
            StyleProfile(
              id: 'style.main',
              displayName: '默认风格',
              summary: '干净利落，强钩子。',
              guardrails: <String>['每章必须推进情报。'],
            ),
          ],
          worldRuleSets: <WorldRuleSet>[
            WorldRuleSet(
              id: 'world.main',
              displayName: '帝国誓约',
              summary: '所有高位者都受誓约约束。',
              rules: <String>['誓约不能被主角直接修改。'],
              forbiddenAssumptions: <String>['不要临时加入万能神器。'],
            ),
          ],
          entityIdentities: <EntityIdentity>[
            EntityIdentity(
              id: 'entity.hero',
              kind: 'character',
              displayName: '主角',
              summary: '以复仇与翻案为长期目标。',
              aliases: <String>['林夜'],
            ),
          ],
          markdownPathsByAssetId: <String, String>{
            'style.main': 'styles/seed_autopilot_style.md',
            'world.main': 'world/seed_autopilot_world_anchor.md',
            'entity.hero': 'characters/seed_autopilot_protagonist.md',
          },
        ),
      );

      expect(sections, hasLength(3));
      expect(
        sections.any(
          (section) =>
              section['title'] == '风格锚点' &&
              '${section['content']}'.contains('每章必须推进情报'),
        ),
        isTrue,
      );
      expect(
        sections.any(
          (section) =>
              section['title'] == '世界硬约束' &&
              '${section['content']}'.contains('不要临时加入万能神器'),
        ),
        isTrue,
      );
      expect(
        sections.any(
          (section) =>
              section['title'] == '角色/身份锚点' &&
              '${section['source']}' ==
                  'characters/seed_autopilot_protagonist.md',
        ),
        isTrue,
      );
    });
  });
}
