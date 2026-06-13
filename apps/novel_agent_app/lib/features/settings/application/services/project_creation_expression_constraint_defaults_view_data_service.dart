import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../project_creation/application/services/project_creation_expression_constraint_defaults_settings_service.dart';
import '../../presentation/models/project_creation_expression_constraint_defaults_view_data.dart';

class ProjectCreationExpressionConstraintDefaultsViewDataService {
  ProjectCreationExpressionConstraintDefaultsViewDataService({
    BuiltinExpressionConstraintProfileRegistrationService?
    builtinRegistrationService,
    ProjectCreationExpressionConstraintDefaultsSettingsService?
    settingsService,
  }) : _builtinRegistrationService =
           builtinRegistrationService ??
           BuiltinExpressionConstraintProfileRegistrationService(),
       _settingsService =
           settingsService ??
           const ProjectCreationExpressionConstraintDefaultsSettingsService();

  final BuiltinExpressionConstraintProfileRegistrationService
  _builtinRegistrationService;
  final ProjectCreationExpressionConstraintDefaultsSettingsService
  _settingsService;

  ProjectCreationExpressionConstraintDefaultsViewData build(
    AppSettings settings,
  ) {
    final selection = _settingsService.resolveSelection(settings);
    final builtins = _builtinRegistrationService.registeredProfiles();
    final selectedIds = switch (selection.mode) {
      ProjectCreationExpressionConstraintDefaultsMode.builtinFallback =>
        ProjectCreationExpressionConstraintDefaultsSettingsService
            .builtinFallbackProfileIds,
      ProjectCreationExpressionConstraintDefaultsMode.custom =>
        selection.profileIds,
      ProjectCreationExpressionConstraintDefaultsMode.disabled =>
        const <String>[],
    };
    final options = <ProjectCreationExpressionConstraintOptionViewData>[
      for (final profile in builtins)
        ProjectCreationExpressionConstraintOptionViewData(
          id: profile.id,
          label: profile.displayName,
          summary: profile.summary,
          isSelected: selectedIds.contains(profile.id),
        ),
    ];
    for (final profileId in selectedIds) {
      final alreadyPresent = options.any((entry) => entry.id == profileId);
      if (alreadyPresent) {
        continue;
      }
      options.add(
        ProjectCreationExpressionConstraintOptionViewData(
          id: profileId,
          label: profileId,
          summary: '当前设置引用了未解析的 profile。保存时会保留它，除非你手动取消勾选。',
          isSelected: true,
          isMissing: true,
        ),
      );
    }
    final fallbackSummary = _fallbackSummary(builtins);
    return ProjectCreationExpressionConstraintDefaultsViewData(
      mode: selection.mode,
      fallbackSummary: fallbackSummary,
      options: List<ProjectCreationExpressionConstraintOptionViewData>.unmodifiable(
        options,
      ),
    );
  }

  String _fallbackSummary(List<ExpressionConstraintProfile> builtins) {
    final labels = <String>[];
    for (final profileId
        in ProjectCreationExpressionConstraintDefaultsSettingsService
            .builtinFallbackProfileIds) {
      final matched = builtins
          .where((profile) => profile.id == profileId)
          .map((profile) => profile.displayName)
          .toList(growable: false);
      if (matched.isNotEmpty) {
        labels.add(matched.first);
        continue;
      }
      labels.add(profileId);
    }
    return labels.join('、');
  }
}
