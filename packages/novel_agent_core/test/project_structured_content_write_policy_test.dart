import 'package:novel_agent_core/src/project/project_content_storage_disposition.dart';
import 'package:novel_agent_core/src/project/project_storage_strategy.dart';
import 'package:novel_agent_core/src/project/project_structured_content_write_policy.dart';
import 'package:test/test.dart';

void main() {
  const policy = ProjectStructuredContentWritePolicy();

  test('markdown project keeps body text on filesystem primary source', () {
    // 中文注释: 普通 Markdown 项目仍然以文件系统作为主事实源，SQLite 不应被误当成默认正文承载面。
    expect(
      policy.dispositionOfBodyTextDocument(
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        documentKind: 'chapter',
      ),
      ProjectContentStorageDisposition.filesystemPrimaryFactSource,
    );
  });

  test(
    'sqlite project routes structured body text into sqlite primary source',
    () {
      // 中文注释: SQLite 项目里的章节、场景和设定等结构化正文必须进入 SQLite 主事实源。
      expect(
        policy.dispositionOfBodyTextDocument(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          documentKind: 'chapter',
        ),
        ProjectContentStorageDisposition.sqlitePrimaryFactSource,
      );
      expect(
        policy.shouldWriteToSqlitePrimarySource(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          documentKind: 'summary',
        ),
        isTrue,
      );
      expect(
        policy.shouldWriteToSqlitePrimarySource(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          documentKind: 'derived_continuation_narrative',
        ),
        isTrue,
      );
      expect(
        policy.shouldWriteToSqlitePrimarySource(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          documentKind: 'derived_fanfic_narrative',
        ),
        isTrue,
      );
    },
  );

  test(
    'sqlite project keeps unknown body text kinds as compatibility mirror',
    () {
      // 中文注释: 没有正式收束到结构化正文域的内容，仍然只能作为兼容镜像存在，不能冒充主事实源。
      expect(
        policy.dispositionOfBodyTextDocument(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          documentKind: 'scratch_pad',
        ),
        ProjectContentStorageDisposition.filesystemCompatibilityMirror,
      );
      expect(
        policy.shouldKeepFilesystemCompatibilityMirror(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          documentKind: 'scratch_pad',
        ),
        isTrue,
      );
    },
  );
}
