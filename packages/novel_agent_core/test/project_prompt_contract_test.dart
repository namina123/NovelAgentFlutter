import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPromptContract', () {
    test('sessionInfo does not expose absolute local project path to model prompt', () {
      final text = ProjectPromptContract().sessionInfo(
        const <String, Object?>{
          'title': '示例项目',
          'project_type': 'novel',
          'storage_strategy': 'markdown_project_store',
          'stage': 'draft',
          'path': 'D:/Projects/novel_project',
        },
        'draft',
      );

      expect(text, contains('项目工作区根目录'));
      expect(text, isNot(contains('D:/Projects/novel_project')));
    });

    test('sessionInfo keeps non-absolute path hints when caller provides them', () {
      final text = ProjectPromptContract().sessionInfo(
        const <String, Object?>{
          'title': '示例项目',
          'project_type': 'novel',
          'path_hint': 'workspace/projects/demo_project',
        },
        'draft',
      );

      expect(text, contains('workspace/projects/demo_project'));
    });
  });
}
