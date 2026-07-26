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

    test(
      'decode normalizes a legacy knowledge base markdown manifest to sqlite',
      () {
        // 中文注释: 旧项目或手工编辑的 manifest 也不能绕过 knowledge_base 的 SQLite-only 合同。
        final codec = ProjectManifestCodecService();
        final manifest = codec.parse('''
{
  "schema_version": 1,
  "title": "旧资料库",
  "project_type": "knowledge_base",
  "storage_strategy": "markdown_project_store"
}
''');

        expect(manifest.projectType, 'knowledge_base');
        expect(
          manifest.storageStrategy,
          ProjectStorageStrategy.sqliteProjectStore,
        );
      },
    );

    test(
      'encode normalizes a manually constructed knowledge base manifest',
      () {
        // 中文注释: 所有持久化出口都必须遵守 SQLite-only，不允许手工构造对象绕过 create/fromJson。
        final codec = ProjectManifestCodecService();
        const manifest = ProjectManifest(
          title: '手工构造资料库',
          projectType: 'knowledge_base',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        );

        final decoded = codec.parse(codec.encode(manifest));

        expect(decoded.projectType, 'knowledge_base');
        expect(
          decoded.storageStrategy,
          ProjectStorageStrategy.sqliteProjectStore,
        );
      },
    );

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

    test(
      'parse preserves descriptor fallback branch and traits after damage',
      () {
        // 中文注释: manifest 半写入时，调用方已加载的 descriptor 仍是当前项目合同；不能
        // 因重命名等元数据操作把知识库分支或复合拆书能力降级为空。
        final codec = ProjectManifestCodecService();

        final decoded = codec.parse(
          '{not-valid-json',
          fallbackTitle: '损坏资料库',
          fallbackProjectType: 'knowledge_base',
          fallbackStorageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          fallbackProjectBranchId:
              KnowledgeBaseBranchCatalogService.ragBranchId,
          fallbackAdditionalTraitIds: const <String>[
            'book_deconstruction',
            'custom_scope',
          ],
        );

        expect(decoded.projectType, 'knowledge_base');
        expect(
          decoded.storageStrategy,
          ProjectStorageStrategy.sqliteProjectStore,
        );
        expect(
          decoded.projectBranchId,
          KnowledgeBaseBranchCatalogService.ragBranchId,
        );
        expect(decoded.additionalTraitIds, <String>[
          'book_deconstruction',
          'custom_scope',
        ]);
      },
    );

    test(
      'parse keeps a loaded long-novel contract when valid JSON has invalid enum values',
      () {
        final codec = ProjectManifestCodecService();

        final decoded = codec.parse(
          '''
{
  "title": "被手工修改的项目",
  "project_type": "future_novel_type",
  "storage_strategy": "future_store",
  "runtime_baseline_id": "future_baseline",
  "additional_trait_ids": "not-a-list"
}
''',
          fallbackTitle: '原长篇项目',
          fallbackProjectType: 'long_novel',
          fallbackStorageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          fallbackRuntimeBaselineId: 'continuous_autonomous',
          fallbackAdditionalTraitIds: const <String>['book_deconstruction'],
        );

        expect(decoded.projectType, 'long_novel');
        expect(
          decoded.storageStrategy,
          ProjectStorageStrategy.sqliteProjectStore,
        );
        expect(decoded.runtimeBaselineId, 'continuous_autonomous');
        expect(decoded.additionalTraitIds, <String>['book_deconstruction']);
      },
    );

    test(
      'parse keeps a loaded knowledge-base branch when valid JSON has invalid contract fields',
      () {
        final codec = ProjectManifestCodecService();

        final decoded = codec.parse(
          '''
{
  "title": "被手工修改的语料库",
  "project_type": "knowledge_base",
  "storage_strategy": "future_store",
  "project_branch_id": "future_branch",
  "additional_trait_ids": "not-a-list"
}
''',
          fallbackTitle: '原语料库',
          fallbackProjectType: 'knowledge_base',
          fallbackStorageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          fallbackProjectBranchId:
              KnowledgeBaseBranchCatalogService.ragBranchId,
          fallbackAdditionalTraitIds: const <String>['book_deconstruction'],
        );

        expect(decoded.projectType, 'knowledge_base');
        expect(
          decoded.storageStrategy,
          ProjectStorageStrategy.sqliteProjectStore,
        );
        expect(
          decoded.projectBranchId,
          KnowledgeBaseBranchCatalogService.ragBranchId,
        );
        expect(decoded.additionalTraitIds, <String>['book_deconstruction']);
      },
    );

    test('strict parsing rejects malformed or unknown cold-open contracts', () {
      final codec = ProjectManifestCodecService();

      expect(codec.tryParseStrict('{not-json'), isNull);
      expect(
        codec.tryParseStrict('''
{
  "title": "未知项目",
  "project_type": "future_novel_type"
}
'''),
        isNull,
      );
      expect(
        codec.tryParseStrict('''
{
  "title": "损坏 trait 项目",
  "project_type": "novel",
  "additional_trait_ids": "book_deconstruction"
}
'''),
        isNull,
      );
    });

    test(
      'strict parsing rejects present malformed contract fields without losing legacy omissions',
      () {
        final codec = ProjectManifestCodecService();

        for (final source in <String>[
          '''
{
  "title": "空类型项目",
  "project_type": null,
  "storage_strategy": "sqlite_project_store"
}
''',
          '''
{
  "title": "空存储项目",
  "project_type": "long_novel",
  "storage_strategy": ""
}
''',
          '''
{
  "title": "坏运行基准项目",
  "project_type": "long_novel",
  "runtime_baseline_id": null
}
''',
          '''
{
  "title": "坏知识库分支",
  "project_type": "knowledge_base",
  "project_branch_id": null
}
''',
          '''
{
  "title": "普通项目带知识库分支",
  "project_type": "novel",
  "project_branch_id": "rag_corpus_library"
}
''',
          '''
{
  "title": "坏 trait 容器",
  "project_type": "novel",
  "additional_trait_ids": null
}
''',
          '''
{
  "title": "未知 schema",
  "project_type": "novel",
  "schema_version": 2
}
''',
        ]) {
          expect(codec.tryParseStrict(source), isNull);
        }

        // The legacy form genuinely omitted the contract extensions. It must
        // remain readable instead of being confused with a malformed value.
        final legacy = codec.tryParseStrict('''
{
  "title": "旧项目"
}
''');
        expect(legacy, isNotNull);
        expect(legacy!.projectType, 'novel');
        expect(
          legacy.storageStrategy,
          ProjectStorageStrategy.markdownProjectStore,
        );
      },
    );

    test(
      'encoding normalizes a manually constructed future schema version',
      () {
        final codec = ProjectManifestCodecService();
        const manifest = ProjectManifest(
          title: '手工 schema 项目',
          projectType: 'novel',
          schemaVersion: 999,
        );

        final encoded = codec.encode(manifest);

        expect(
          codec.toJson(manifest)['schema_version'],
          ProjectManifestCodecService.currentSchemaVersion,
        );
        expect(codec.tryParseStrict(encoded), isNotNull);
      },
    );

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

    test('canonicalizes additional trait IDs at every manifest boundary', () {
      // 中文注释: 能力 trait 的顺序和重复项不应因调用入口或手工 JSON 而漂移。
      final codec = ProjectManifestCodecService();
      final created = codec.create(
        title: '复合项目',
        projectType: 'novel',
        additionalTraitIds: const <String>[
          ' book_deconstruction ',
          '',
          'book_deconstruction',
          'custom_scope',
          'custom_scope',
        ],
      );
      expect(created.additionalTraitIds, <String>[
        'book_deconstruction',
        'custom_scope',
      ]);

      final parsed = codec.parse('''
{
  "title": "手工复合项目",
  "project_type": "novel",
  "additional_trait_ids": [" book_deconstruction ", "", null, "book_deconstruction", "custom_scope", "custom_scope"]
}
''');
      expect(parsed.additionalTraitIds, <String>[
        'book_deconstruction',
        'custom_scope',
      ]);

      const manuallyConstructed = ProjectManifest(
        title: '手工构造复合项目',
        projectType: 'novel',
        additionalTraitIds: <String>[
          ' book_deconstruction ',
          'book_deconstruction',
          'custom_scope',
          'custom_scope',
        ],
      );
      final roundTripped = codec.parse(codec.encode(manuallyConstructed));
      expect(roundTripped.additionalTraitIds, <String>[
        'book_deconstruction',
        'custom_scope',
      ]);
    });
  });
}
