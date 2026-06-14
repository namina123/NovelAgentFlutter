import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest storage strategy', () {
    test('create normalizes knowledge base to sqlite storage', () {
      // 中文注释: 这里验证新建知识库时即使调用方误传 Markdown，manifest 也会在 core 创建阶段收束为 SQLite。
      final codec = ProjectManifestCodecService();
      final manifest = codec.create(
        title: '资料知识库',
        projectType: 'knowledge_base',
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      );

      expect(
        manifest.storageStrategy,
        ProjectStorageStrategy.sqliteProjectStore,
      );
      expect(manifest.projectType, 'knowledge_base');
    });

    test('codec round trip preserves explicit storage strategy', () {
      // 中文注释: 这里验证 manifest 一旦声明 SQLite 主存储策略，编解码后不会悄悄回退成 Markdown。
      final codec = ProjectManifestCodecService();
      final manifest = codec.create(
        title: '策略测试项目',
        projectType: 'long_novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        runtimeBaselineId: 'continuous_autonomous',
      );

      final decoded = codec.parse(codec.encode(manifest));

      expect(
        decoded.storageStrategy,
        ProjectStorageStrategy.sqliteProjectStore,
      );
      expect(decoded.runtimeBaselineId, 'continuous_autonomous');
    });

    test('legacy manifest without storage strategy falls back to markdown', () {
      // 中文注释: 这里验证旧项目 manifest 没有 storage_strategy 字段时，仍能按 Markdown 项目兼容打开。
      final codec = ProjectManifestCodecService();
      final decoded = codec.parse('''
{
  "schema_version": 1,
  "title": "旧项目",
  "project_type": "novel"
}
''');

      expect(
        decoded.storageStrategy,
        ProjectStorageStrategy.markdownProjectStore,
      );
    });

    test('unknown strategy id falls back to markdown', () {
      // 中文注释: 这里验证坏数据或未来未识别策略值不会让当前版本直接失去打开项目的能力。
      expect(
        ProjectStorageStrategy.fromId('future_store'),
        ProjectStorageStrategy.markdownProjectStore,
      );
    });

    test('unsupported runtime baseline is cleared during decode', () {
      // 中文注释: 这里验证运行基准必须和项目类型相匹配，普通项目不会保留长任务专属基准。
      final codec = ProjectManifestCodecService();
      final decoded = codec.parse('''
{
  "schema_version": 1,
  "title": "普通项目",
  "project_type": "novel",
  "runtime_baseline_id": "continuous_autonomous"
}
''');

      expect(decoded.runtimeBaselineId, isEmpty);
    });
  });
}
