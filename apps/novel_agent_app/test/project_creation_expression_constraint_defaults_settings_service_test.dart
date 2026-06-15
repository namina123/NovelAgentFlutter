import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_creation/application/services/project_creation_expression_constraint_defaults_settings_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  const service = ProjectCreationExpressionConstraintDefaultsSettingsService();

  group('ProjectCreationExpressionConstraintDefaultsSettingsService', () {
    test(
      'uses builtin fallback when app settings do not configure defaults',
      () {
        final selection = service.resolveSelection(
          const AppSettings(
            defaultProviderId: '',
            defaultAgentId: '',
            defaultModelId: '',
            defaultProjectPath: '',
            autoSaveDrafts: true,
            providers: <ProviderEndpointSettings>[],
          ),
        );

        expect(
          selection.mode,
          ProjectCreationExpressionConstraintDefaultsMode.builtinFallback,
        );
        expect(
          selection.profileIds,
          ProjectCreationExpressionConstraintDefaultsSettingsService
              .builtinFallbackProfileIds,
        );
        expect(selection.profileIds, <String>[
          'de_ai',
          'strict_pov_boundary',
          'low_jargon_narration',
        ]);
      },
    );

    test('treats explicit empty configuration as disabled', () {
      final selection = service.resolveSelection(
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

      expect(
        selection.mode,
        ProjectCreationExpressionConstraintDefaultsMode.disabled,
      );
      expect(selection.profileIds, isEmpty);
    });

    test('normalizes explicit custom profile ids', () {
      final selection = service.resolveSelection(
        const AppSettings(
          defaultProviderId: '',
          defaultAgentId: '',
          defaultModelId: '',
          defaultProjectPath: '',
          autoSaveDrafts: true,
          providers: <ProviderEndpointSettings>[],
          extraSettings: <String, Object?>{
            'project_creation_defaults': <String, Object?>{
              'expression_constraint_profile_ids': <Object?>[
                'de_ai',
                ' strict_pov_boundary ',
                'de_ai',
              ],
            },
          },
        ),
      );

      expect(
        selection.mode,
        ProjectCreationExpressionConstraintDefaultsMode.custom,
      );
      expect(selection.profileIds, ['de_ai', 'strict_pov_boundary']);
    });

    test('clears explicit config when saving builtin fallback mode', () {
      final extraSettings = service.mergedExtraSettingsForSelection(
        settings: const AppSettings(
          defaultProviderId: '',
          defaultAgentId: '',
          defaultModelId: '',
          defaultProjectPath: '',
          autoSaveDrafts: true,
          providers: <ProviderEndpointSettings>[],
          extraSettings: <String, Object?>{
            'project_creation_defaults': <String, Object?>{
              'expression_constraint_profile_ids': <Object?>['de_ai'],
            },
            'expression_constraint_profile_ids': <Object?>['legacy'],
            'other_setting': 'keep',
          },
        ),
        selection: const ProjectCreationExpressionConstraintDefaultsSelection(
          mode: ProjectCreationExpressionConstraintDefaultsMode.builtinFallback,
          profileIds: <String>['de_ai'],
        ),
      );

      expect(extraSettings['project_creation_defaults'], isNull);
      expect(extraSettings['expression_constraint_profile_ids'], isNull);
      expect(extraSettings['other_setting'], 'keep');
    });
  });
}
