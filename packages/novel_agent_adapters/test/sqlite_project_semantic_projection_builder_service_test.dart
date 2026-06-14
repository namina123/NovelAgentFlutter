import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteProjectSemanticProjectionBuilderService', () {
    test('builds a stable semantic tree and filters projection surfaces', () {
      // 中文注释: 这里验证 builder 只把主语义内容折叠成可读节点，避免投影面和数据库文件再次进入同一棵树。
      const builder = SqliteProjectSemanticProjectionBuilderService();
      final manifest = ProjectManifest(
        title: 'SQLite 项目',
        projectType: 'novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      final layout = const ProjectDirectoryLayoutService().layoutFor(
        ProjectStorageStrategy.sqliteProjectStore,
      );
      final projection = builder.build(
        rootPath: '/tmp/sqlite_project',
        manifest: manifest,
        layout: layout,
        workspaceEntries: <JsonMap>[
          <String, Object?>{
            'relative_path': 'chapters/chapter_01.md',
            'display_name': 'chapter_01.md',
            'is_dir': false,
          },
          <String, Object?>{
            'relative_path': 'research/note_01.md',
            'display_name': 'note_01.md',
            'is_dir': false,
          },
          <String, Object?>{
            'relative_path': 'premise/project_brief.md',
            'display_name': 'project_brief.md',
            'is_dir': false,
          },
          <String, Object?>{
            'relative_path': 'premise/sqlite_projection/index.md',
            'display_name': 'index.md',
            'is_dir': false,
          },
          <String, Object?>{
            'relative_path': '.novel_agent/sqlite/novel_agent.db',
            'display_name': 'novel_agent.db',
            'is_dir': false,
          },
        ],
      );

      expect(
        projection.entryNodes.map((node) => node.relativePath),
        containsAll(<String>[
          'chapters/chapter_01.md',
          'research/note_01.md',
        ]),
      );
      expect(
        projection.entryNodes.map((node) => node.relativePath),
        isNot(contains('premise/project_brief.md')),
      );
      expect(
        projection.entryNodes.map((node) => node.relativePath),
        isNot(contains('premise/sqlite_projection/index.md')),
      );
      expect(
        projection.entryNodes.map((node) => node.relativePath),
        isNot(contains('.novel_agent/sqlite/novel_agent.db')),
      );
      expect(
        projection.rootNode.childNodeIds,
        orderedEquals(
          projection.groupNodes.map((node) => node.nodeId).toList(
            growable: false,
          ),
        ),
      );
      expect(
        projection.entryNodes.firstWhere(
          (node) => node.relativePath == 'chapters/chapter_01.md',
        ).sourceIdentity.truthLabel,
        'sqlite_project_store',
      );
      expect(
        projection.documents.map((document) => document.relativePath),
        contains('premise/sqlite_projection/index.md'),
      );
      expect(
        projection.documents.map((document) => document.relativePath),
        contains('premise/sqlite_projection/body_and_chapters.md'),
      );
      expect(
        projection.documents.map((document) => document.relativePath),
        contains('premise/sqlite_projection/project_materials.md'),
      );
      expect(projection.documents, hasLength(9));
    });
  });
}
