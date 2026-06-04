import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectDraftExecutionConstraintRuntimeService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late ExpressionConstraintProfileRepository profileRepository;
    late ProjectExpressionConstraintBindingRepository bindingRepository;
    late LocalConstraintBindingRepository constraintBindingRepository;
    late ProjectDraftExecutionConstraintRuntimeService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_execution_constraint_runtime_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'constraint_runtime',
        name: '约束运行时测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      profileRepository = ExpressionConstraintProfileRepository(
        workspacePort: workspacePort,
      );
      bindingRepository = ProjectExpressionConstraintBindingRepository(
        workspacePort: workspacePort,
      );
      constraintBindingRepository = LocalConstraintBindingRepository(
        workspacePort: workspacePort,
      );
      service = ProjectDraftExecutionConstraintRuntimeService(
        expressionConstraintProfileRepository: profileRepository,
        projectExpressionConstraintBindingRepository: bindingRepository,
        constraintBindingRepository: constraintBindingRepository,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'loads legacy expression settings and narrative bindings into runtime payload',
      () async {
      await profileRepository.saveProjectProfiles(project, <ExpressionConstraintProfile>[
        const ExpressionConstraintProfile(
          id: 'project_natural_expression',
          displayName: '项目自然表达',
          summary: '项目级自然表达约束。',
          kind: ExpressionConstraintKind.naturalExpression,
          rules: <String>['压低解释腔。'],
        ),
      ]);
      await bindingRepository.saveBindings(
        project,
        const <ProjectExpressionConstraintBinding>[
          ProjectExpressionConstraintBinding(
            id: 'project_binding_1',
            profileId: 'project_natural_expression',
            defaultForProject: true,
          ),
        ],
      );
      await constraintBindingRepository.appendBinding(
        project,
        NarrativeConstraintBindingProposal(
          bindingId: 'binding_length_1',
          constraintType: 'chapter_length',
          scope: const ConstraintBindingScope(
            appliesTo: <String>[ConstraintBindingAppliesTo.writing],
            stageIds: <String>['draft'],
          ),
          policy: const ConstraintBindingPolicy(autoAccept: true),
          source: const NarrativeSourceRef(sourceType: 'user'),
          constraintPayload: const <String, Object?>{
            'target_word_count': 2400,
            'preferred_min': 2100,
            'preferred_max': 2700,
          },
        ),
      );

      final resolved = await service.resolve(
        project,
        appliesTo: ConstraintBindingAppliesTo.writing,
        stageId: 'draft',
      );

      expect(
        ValueReaders.intValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(
              resolved['chapter_length_metadata'],
            )['chapter_length_profile'],
          )['target_length'],
        ),
        2400,
      );
      expect(
        ValueReaders.objectList(resolved['expression_constraint_profiles']),
        isNotEmpty,
      );
      expect(
        ValueReaders.objectList(
          resolved['project_expression_constraint_bindings'],
        ),
        isNotEmpty,
      );
      expect(
        ValueReaders.stringValue(resolved['session_context_markdown']),
        contains('字数约束'),
      );
      },
    );
  });
}
