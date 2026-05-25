import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('RuntimeBaselineCatalogService', () {
    test('returns long novel baselines and keeps project mapping aligned', () {
      // 中文注释: 这里验证运行基线已经成为独立 runtime 合同，同时项目创建侧仍能复用同一份基线目录。
      const runtimeCatalog = RuntimeBaselineCatalogService();
      final projectCatalog = ProjectRuntimeBaselineCatalogService(
        runtimeBaselineCatalogService: runtimeCatalog,
      );

      final runtimeBaselines = runtimeCatalog.forProjectType('long_novel');
      final projectBaselines = projectCatalog.definitionsForProjectType(
        'long_novel',
      );

      expect(runtimeBaselines, hasLength(2));
      expect(projectBaselines, hasLength(2));
      expect(runtimeBaselines.first.id, 'continuous_autonomous');
      expect(projectBaselines.first.id, runtimeBaselines.first.id);
      expect(runtimeCatalog.byId('chapter_collaboration_autorun'), isNotNull);
    });
  });
}
