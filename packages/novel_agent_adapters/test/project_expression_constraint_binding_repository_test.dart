import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectExpressionConstraintBindingRepository', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectExpressionConstraintBindingRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-expression-constraint-bindings-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      repository = ProjectExpressionConstraintBindingRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('persists bindings inside current project only', () async {
      await repository.saveBindings(
        project,
        const <ProjectExpressionConstraintBinding>[
          ProjectExpressionConstraintBinding(
            id: 'draft-de-ai',
            profileId: 'de_ai',
            displayName: '正文去 AI 风',
            defaultForProject: true,
            targetAgentIds: <String>['default_generalist'],
            targetModeIds: <String>['draft'],
            targetStageIds: <String>['chapter_write'],
            weight: 120,
          ),
        ],
      );

      final loaded = await repository.loadBindings(project);

      expect(loaded, hasLength(1));
      expect(loaded.single.profileId, 'de_ai');
      expect(loaded.single.targetAgentIds, <String>['default_generalist']);
      expect(loaded.single.targetModeIds, <String>['draft']);
      expect(loaded.single.targetStageIds, <String>['chapter_write']);
      final bindingFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}settings${Platform.pathSeparator}expression_constraint_bindings.json',
      );
      expect(await bindingFile.exists(), isTrue);
    });
  });
}
