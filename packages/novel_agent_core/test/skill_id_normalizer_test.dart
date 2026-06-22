import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SkillIdNormalizer', () {
    test('unifies snake_case and kebab-case to the same canonical id', () {
      // 中文注释: 这是整条技能调度链最关键的回归点：文档/路由用 snake_case，包用 kebab-case，
      // 归一化后两端必须落到同一个 id，否则技能会被静默判成 unavailable。
      const normalizer = SkillIdNormalizer();
      expect(normalizer.normalize('generate_outline'), 'generate-outline');
      expect(normalizer.normalize('generate-outline'), 'generate-outline');
      expect(
        normalizer.normalize('chapter_drafting_method'),
        'chapter-drafting-method',
      );
      expect(
        normalizer.normalize('chapter-drafting-method'),
        'chapter-drafting-method',
      );
      expect(normalizer.normalize('Ask_Opening_Questions'), 'ask-opening-questions');
    });

    test('keeps already canonical ids stable and trims noise', () {
      const normalizer = SkillIdNormalizer();
      expect(normalizer.normalize('novel-control-station'), 'novel-control-station');
      expect(normalizer.normalize('  novel_control_station  '), 'novel-control-station');
      expect(normalizer.normalize('skill--creator__cn'), 'skill-creator-cn');
      expect(normalizer.normalize(''), '');
    });
  });
}
