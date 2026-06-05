import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectContextFileSelectionService', () {
    test('skips information projection markdown that is injected separately', () {
      final service = ProjectContextFileSelectionService();

      final selected = service.select(const <JsonMap>[
        <String, Object?>{
          'relative_path': 'knowledge/项目知识摘要.md',
          'is_dir': false,
        },
        <String, Object?>{
          'relative_path': 'knowledge/设计元素摘要.md',
          'is_dir': false,
        },
        <String, Object?>{
          'relative_path': 'research/资料研究摘要.md',
          'is_dir': false,
        },
        <String, Object?>{
          'relative_path': 'references/引用作品边界.md',
          'is_dir': false,
        },
        <String, Object?>{
          'relative_path': 'knowledge/manual_notes.md',
          'is_dir': false,
        },
        <String, Object?>{
          'relative_path': 'world/rules.md',
          'is_dir': false,
        },
      ]);

      expect(selected, isNot(contains('knowledge/项目知识摘要.md')));
      expect(selected, isNot(contains('knowledge/设计元素摘要.md')));
      expect(selected, isNot(contains('research/资料研究摘要.md')));
      expect(selected, isNot(contains('references/引用作品边界.md')));
      expect(selected, contains('knowledge/manual_notes.md'));
      expect(selected, contains('world/rules.md'));
    });
  });
}
