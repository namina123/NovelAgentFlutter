import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'package:novel_agent_app/features/project_creation/application/services/project_creation_expression_constraint_defaults_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ProjectCreationExpressionConstraintDefaultsService', () {
    test(
      'seeds built-in default expression constraint when project is fresh',
      () async {
        final savedBindings = <ProjectExpressionConstraintBinding>[];
        final service = ProjectCreationExpressionConstraintDefaultsService(
          workspaceService: ProjectExpressionConstraintWorkspaceService(
            loadProfiles: (_) async => const <ExpressionConstraintProfile>[
              ExpressionConstraintProfile(
                id: 'de_ai',
                displayName: '去 AI 风',
                summary: 'summary',
                recommendedScope: ExpressionConstraintScope(
                  projectTypeIds: <String>['novel'],
                ),
              ),
            ],
            loadBindings: (_) async =>
                const <ProjectExpressionConstraintBinding>[],
            saveBindings: (_, bindings) async {
              savedBindings
                ..clear()
                ..addAll(bindings);
            },
          ),
        );

        await service.applyDefaults(
          const ProjectDescriptor(
            id: 'project_1',
            name: 'Test',
            rootPath: '/tmp/project_1',
            projectType: 'novel',
          ),
          const AppSettings(
            defaultProviderId: '',
            defaultAgentId: '',
            defaultModelId: '',
            defaultProjectPath: '',
            autoSaveDrafts: true,
            providers: <ProviderEndpointSettings>[],
          ),
        );

        expect(savedBindings, hasLength(1));
        expect(savedBindings.first.profileId, 'de_ai');
        expect(savedBindings.first.defaultForProject, isTrue);
      },
    );

    test('respects explicit app-level empty default list', () async {
      var saveCount = 0;
      final service = ProjectCreationExpressionConstraintDefaultsService(
        workspaceService: ProjectExpressionConstraintWorkspaceService(
          loadProfiles: (_) async => const <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: 'summary',
            ),
          ],
          loadBindings: (_) async =>
              const <ProjectExpressionConstraintBinding>[],
          saveBindings: (_, _) async {
            saveCount += 1;
          },
        ),
      );

      await service.applyDefaults(
        const ProjectDescriptor(
          id: 'project_2',
          name: 'Test 2',
          rootPath: '/tmp/project_2',
          projectType: 'novel',
        ),
        const AppSettings(
          defaultProviderId: '',
          defaultAgentId: '',
          defaultModelId: '',
          defaultProjectPath: '',
          autoSaveDrafts: true,
          providers: <ProviderEndpointSettings>[],
          extraSettings: <String, Object?>{
            'project_creation_defaults': <String, Object?>{
              'expression_constraint_profile_ids': <Object?>[],
            },
          },
        ),
      );

      expect(saveCount, 0);
    });
  });
}
