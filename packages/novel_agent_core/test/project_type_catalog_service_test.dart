import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'enabledDefinitions hides short collection from default creation list',
    () {
      const catalog = ProjectTypeCatalogService();

      final enabledIds = catalog
          .enabledDefinitions()
          .map((item) => item.id)
          .toList(growable: false);

      expect(enabledIds, isNot(contains('short_collection')));
      expect(catalog.definitionOf('short_collection').id, 'short_collection');
    },
  );

  test('knowledge base is restricted to sqlite storage strategy', () {
    // 中文注释: 这里直接锁定目录矩阵，避免后续只在 UI 层隐藏而 core 目录定义仍然双开。
    const catalog = ProjectTypeCatalogService();

    final knowledgeBaseDefinition = catalog.definitionOf('knowledge_base');
    final supportedIds = knowledgeBaseDefinition.supportedStorageStrategies
        .map((item) => item.id)
        .toList(growable: false);

    expect(supportedIds, <String>['sqlite_project_store']);
    expect(
      catalog.definitionOf('novel').supportedStorageStrategies,
      contains(ProjectStorageStrategy.markdownProjectStore),
    );
  });
}
