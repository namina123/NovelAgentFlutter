import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_subtitle_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'renders a human-readable subtitle for every registered project type',
    () {
      final service = ProjectSubtitleViewDataService();
      const expectedLabels = <String, String>{
        'novel': '普通小说项目',
        'long_novel': '长篇项目',
        'knowledge_base': '资料知识库',
        'short_collection': '短篇集项目',
        'book_deconstruction': '拆书项目',
      };

      for (final entry in expectedLabels.entries) {
        final subtitle = service.build(
          ProjectDescriptor(
            id: entry.key,
            name: entry.key,
            rootPath: 'D:/Projects/${entry.key}',
            projectType: entry.key,
          ),
        );

        expect(subtitle, startsWith(entry.value));
        expect(subtitle, isNot(contains(entry.key)));
      }
    },
  );
}
