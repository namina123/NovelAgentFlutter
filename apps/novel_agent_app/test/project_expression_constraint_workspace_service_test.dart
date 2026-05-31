import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class _FakeExpressionConstraintProfileRepository {
  Future<List<ExpressionConstraintProfile>> loadProfiles(
    ProjectDescriptor project, {
    bool includeBuiltins = true,
  }) async {
    return <ExpressionConstraintProfile>[
      const ExpressionConstraintProfile(
        id: 'de_ai',
        displayName: '去 AI 风',
        summary: '内置 preset',
        kind: ExpressionConstraintKind.naturalExpression,
      ),
      if (project.rootPath.endsWith('project-b'))
        const ExpressionConstraintProfile(
          id: 'custom_b',
          displayName: 'B 项目附加限制',
          summary: '仅项目 B 可见',
        ),
    ];
  }
}

class _FakeProjectExpressionConstraintBindingRepository {
  final Map<String, List<ProjectExpressionConstraintBinding>> storage =
      <String, List<ProjectExpressionConstraintBinding>>{};

  Future<List<ProjectExpressionConstraintBinding>> loadBindings(
    ProjectDescriptor project,
  ) async {
    return List<ProjectExpressionConstraintBinding>.from(
      storage[project.rootPath] ?? const <ProjectExpressionConstraintBinding>[],
    );
  }

  Future<void> saveBindings(
    ProjectDescriptor project,
    List<ProjectExpressionConstraintBinding> bindings,
  ) async {
    storage[project.rootPath] = List<ProjectExpressionConstraintBinding>.from(
      bindings,
    );
  }
}

void main() {
  group('ProjectExpressionConstraintWorkspaceService', () {
    late _FakeExpressionConstraintProfileRepository profileRepository;
    late _FakeProjectExpressionConstraintBindingRepository bindingRepository;
    late ProjectExpressionConstraintWorkspaceService service;
    late ProjectDescriptor projectA;
    late ProjectDescriptor projectB;

    setUp(() {
      profileRepository = _FakeExpressionConstraintProfileRepository();
      bindingRepository = _FakeProjectExpressionConstraintBindingRepository();
      service = ProjectExpressionConstraintWorkspaceService(
        loadProfiles: (project) => profileRepository.loadProfiles(project),
        loadBindings: bindingRepository.loadBindings,
        saveBindings: bindingRepository.saveBindings,
      );
      projectA = const ProjectDescriptor(
        id: 'project_a',
        name: 'Project A',
        rootPath: 'D:/projects/project-a',
        projectType: 'long_novel',
      );
      projectB = const ProjectDescriptor(
        id: 'project_b',
        name: 'Project B',
        rootPath: 'D:/projects/project-b',
        projectType: 'long_novel',
      );
    });

    test(
      'load exposes builtins and keeps bindings isolated per project',
      () async {
        await service
            .saveBindings(projectA, const <ProjectExpressionConstraintBinding>[
              ProjectExpressionConstraintBinding(
                profileId: 'de_ai',
                enabled: true,
                defaultForProject: true,
              ),
            ]);
        await service.saveBindings(
          projectB,
          const <ProjectExpressionConstraintBinding>[
            ProjectExpressionConstraintBinding(
              profileId: 'custom_b',
              enabled: true,
              targetModeIds: <String>['draft'],
            ),
          ],
        );

        final workspaceA = await service.load(projectA);
        final workspaceB = await service.load(projectB);

        expect(workspaceA.profiles.map((item) => item.id), contains('de_ai'));
        expect(
          workspaceB.profiles.map((item) => item.id),
          containsAll(<String>['de_ai', 'custom_b']),
        );
        expect(workspaceA.bindings.map((item) => item.profileId), <String>[
          'de_ai',
        ]);
        expect(workspaceB.bindings.map((item) => item.profileId), <String>[
          'custom_b',
        ]);
      },
    );
  });
}
