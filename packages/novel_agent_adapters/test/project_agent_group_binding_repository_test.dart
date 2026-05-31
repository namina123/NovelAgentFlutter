import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectAgentGroupBindingRepository', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectAgentGroupBindingRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-project-group-binding-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      repository = ProjectAgentGroupBindingRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('persists selections inside current project only', () async {
      await repository.saveSelections(
        project,
        const <ProjectAgentGroupSelection>[
          ProjectAgentGroupSelection(
            groupId: 'starter_long_novel_generalist',
            displayName: '默认长任务开局',
            selectedByDefault: true,
            modeIds: <String>['chapter_collaboration_autorun'],
            stageIds: <String>['opening'],
          ),
        ],
      );

      final loaded = await repository.loadSelections(project);

      expect(loaded, hasLength(1));
      expect(loaded.single.groupId, 'starter_long_novel_generalist');
      expect(loaded.single.selectedByDefault, isTrue);
      expect(loaded.single.modeIds, <String>['chapter_collaboration_autorun']);
      expect(loaded.single.stageIds, <String>['opening']);
      final bindingFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}settings${Platform.pathSeparator}project_agent_groups.json',
      );
      expect(await bindingFile.exists(), isTrue);
    });
  });
}
