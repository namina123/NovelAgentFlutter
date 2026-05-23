import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Prompt template services', () {
    final catalog = PromptTemplateCatalogService();
    final merge = PromptTemplateMergeService();
    final preview = PromptTemplatePreviewService();

    test('merges project template override and renders preview', () {
      // 中文注释: 这里验证项目模板会覆盖内置同 id 模板，并且变量渲染结果可直接预览。
      final templates = merge.listTemplates(<Object?>[
        <String, Object?>{
          'id': 'chapter_atomic',
          'name': '章节任务覆盖',
          'scope': 'task',
          'content': '目标：{{task_goal}}',
        },
      ]);
      final previewResult = preview.previewById(
        'chapter_atomic',
        templates,
        <String, Object?>{'task_goal': '推进冲突'},
      );

      expect(catalog.coreTemplateIds(), contains('review_report'));
      expect(
        templates.firstWhere((item) => item['id'] == 'chapter_atomic')['name'],
        '章节任务覆盖',
      );
      expect(previewResult['content'], '目标：推进冲突');
    });
  });
}
