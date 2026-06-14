import 'package:novel_agent_core/src/project/project_content_storage_disposition.dart';
import 'package:novel_agent_core/src/project/project_storage_aware_workspace_policy.dart';
import 'package:novel_agent_core/src/project/project_storage_strategy.dart';
import 'package:test/test.dart';

void main() {
  const policy = ProjectStorageAwareWorkspacePolicy();

  test('markdown project keeps workspace files as primary facts', () {
    // 中文注释: Markdown 项目里的章节文件依然是主事实源，工作区策略不应偷偷降级成投影。
    expect(
      policy.dispositionOfWorkspacePath(
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        relativePath: 'chapters/001.md',
      ),
      ProjectContentStorageDisposition.filesystemPrimaryFactSource,
    );
    expect(
      policy.isPrimaryFactSourcePath(
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        relativePath: 'chapters/001.md',
      ),
      isTrue,
    );
  });

  test('sqlite project turns workspace files into projections or metadata', () {
    // 中文注释: SQLite 项目里同样的文件树条目只是投影或元数据，不再是默认主事实源。
    expect(
      policy.dispositionOfWorkspacePath(
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        relativePath: 'chapters/001.md',
      ),
      ProjectContentStorageDisposition.filesystemProjection,
    );
    expect(
      policy.isProjectionPath(
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        relativePath: 'chapters/001.md',
      ),
      isTrue,
    );
    expect(
      policy.dispositionOfWorkspacePath(
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        relativePath: '.novel_agent/project_manifest.json',
      ),
      ProjectContentStorageDisposition.workspaceMetadata,
    );
    expect(
      policy.isMetadataPath(
        relativePath: '.novel_agent/settings/runtime_profile.json',
      ),
      isTrue,
    );
  });

  test(
    'sqlite project treats database files as compatibility mirrors rather than primary workspace entries',
    () {
      // 中文注释: `.db` / `.sqlite` 仍然是兼容镜像，不应该在 core 合同里被说成普通工作台主入口。
      expect(
        policy.dispositionOfWorkspacePath(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          relativePath: 'novel_agent.db',
        ),
        ProjectContentStorageDisposition.filesystemCompatibilityMirror,
      );
    },
  );
}
