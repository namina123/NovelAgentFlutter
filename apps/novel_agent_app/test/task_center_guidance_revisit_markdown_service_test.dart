import 'package:flutter_test/flutter_test.dart';

import 'package:novel_agent_app/features/task_center/application/services/task_center_guidance_revisit_markdown_service.dart';

void main() {
  group('TaskCenterGuidanceRevisitMarkdownService', () {
    test('renders revisit package into detail-friendly markdown', () {
      // 中文注释: 这里验证长期约束回看包会被投影成详情区可直接展示的文本，而不是只剩裸 JSON。
      const service = TaskCenterGuidanceRevisitMarkdownService();

      final markdown = service.render(const <String, Object?>{
        'ok': true,
        'summary': '当前检查点建议优先回看风格锚点与世界规则。',
        'focus_domains': <Object?>['style', 'world'],
        'items': <Object?>[
          <String, Object?>{
            'title': '长期约束摘要',
            'path': 'tracking/modes/seed_autopilot_novel/guidance.md',
            'summary': '先重新确认创作承诺。',
            'highlights': <Object?>['高压权谋', '减少说明腔'],
            'content_preview': '灵感托管式长篇 引导摘要...',
          },
          <String, Object?>{
            'title': '默认世界锚点',
            'path': 'world/seed_autopilot_world_anchor.md',
            'summary': '誓约体系不可被真正伪造。',
            'highlights': <Object?>['违约会反噬'],
            'content_preview': '世界锚点...',
          },
        ],
      });

      expect(markdown, contains('## 长期约束回看'));
      expect(markdown, contains('聚焦域：风格、世界'));
      expect(
        markdown,
        contains('tracking/modes/seed_autopilot_novel/guidance.md'),
      );
      expect(markdown, contains('违约会反噬'));
    });
  });
}
