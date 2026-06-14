import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteVisibilityPolicy', () {
    const policy = SqliteVisibilityPolicy();

    test('freezes the default SQLite main semantic tree group order', () {
      // 中文注释: 这条断言锁住 SQLite 主语义树的固定分区顺序，避免后续 UI 或 adapter 自行改名重排。
      expect(
        policy.defaultMainTreeGroups().map((kind) => kind.label),
        orderedEquals(const <String>[
          '项目概览',
          '正文与章节',
          '大纲与设定',
          '项目资料',
          '参考资产挂载',
          '导入源',
          '提取与审核',
          '导出与投影',
        ]),
      );
      expect(
        policy.defaultMainTreeGroupNodes(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        ),
        hasLength(8),
      );
    });

    test(
      'hides SQLite diagnostics and legacy compatibility paths from the default tree',
      () {
        // 中文注释: 默认树只承载主语义分区，内部状态和兼容根要折叠到诊断/投影层。
        expect(
          policy.shouldHideFromDefaultTree(
            '.novel_agent/sqlite/novel_agent.db',
            storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          ),
          isTrue,
        );
        expect(
          policy.shouldHideFromDefaultTree(
            'knowledge/cards/card_01.md',
            storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          ),
          isTrue,
        );
        expect(
          policy.isDiagnosticLayerPath('.novel_agent/sqlite/novel_agent.db'),
          isTrue,
        );
      },
    );

    test(
      'classifies semantic paths into stable projection groups and source identities',
      () {
        // 中文注释: 语义分组和来源身份需要可预测，后续 adapter 只需消费，不再自己猜路径语义。
        final chapterNode = policy.buildNode(
          relativePath: 'chapters/chapter_01.md',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          title: '第一章',
        );
        final knowledgeNode = policy.buildNode(
          relativePath: 'knowledge/card_01.md',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          title: '知识卡',
        );
        final referenceNode = policy.buildNode(
          relativePath: 'references/reference_pack.md',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          title: '参考资产包',
        );
        final importNode = policy.buildNode(
          relativePath: 'imports/source_01.md',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          title: '导入源',
        );
        final reviewNode = policy.buildNode(
          relativePath: 'tracking/review_report.md',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          title: '审核记录',
        );
        final exportNode = policy.buildNode(
          relativePath: 'exports/projection.md',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          title: '投影导出',
        );

        expect(
          chapterNode.groupKind,
          SqliteProjectionGroupKind.bodyAndChapters,
        );
        expect(chapterNode.kind, SqliteProjectionNodeKind.projection);
        expect(chapterNode.sourceIdentity.label, contains('SQLite'));
        expect(chapterNode.sourceIdentity.surfaceRole, 'sqlite_projection');
        expect(chapterNode.isReadOnlyProjection, isTrue);

        expect(
          knowledgeNode.groupKind,
          SqliteProjectionGroupKind.projectMaterials,
        );
        expect(knowledgeNode.sourceIdentity.truthLabel, 'sqlite_project_store');

        expect(
          referenceNode.groupKind,
          SqliteProjectionGroupKind.referenceMounts,
        );
        expect(referenceNode.sourceIdentity.truthLabel, '参考资产库');
        expect(referenceNode.kind, SqliteProjectionNodeKind.attachment);

        expect(importNode.groupKind, SqliteProjectionGroupKind.importSources);
        expect(
          importNode.sourceIdentity.surfaceRole,
          'import_source_projection',
        );
        expect(importNode.kind, SqliteProjectionNodeKind.source);

        expect(
          reviewNode.groupKind,
          SqliteProjectionGroupKind.extractionAndReview,
        );
        expect(reviewNode.kind, SqliteProjectionNodeKind.record);

        expect(
          exportNode.groupKind,
          SqliteProjectionGroupKind.exportAndProjection,
        );
        expect(exportNode.kind, SqliteProjectionNodeKind.projection);
      },
    );
  });
}
