import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'project_creation_expression_constraint_defaults_settings_service.dart';

class ProjectCreationExpressionConstraintDefaultsService {
  const ProjectCreationExpressionConstraintDefaultsService({
    required ProjectExpressionConstraintWorkspaceService workspaceService,
    ProjectCreationExpressionConstraintDefaultsSettingsService?
    settingsService,
  }) : _workspaceService = workspaceService,
       _settingsService =
           settingsService ??
           const ProjectCreationExpressionConstraintDefaultsSettingsService();

  final ProjectExpressionConstraintWorkspaceService _workspaceService;
  final ProjectCreationExpressionConstraintDefaultsSettingsService
  _settingsService;

  Future<void> applyDefaults(
    ProjectDescriptor project,
    AppSettings settings,
  ) async {
    final workspace = await _workspaceService.load(project);
    if (workspace.bindings.isNotEmpty) {
      return;
    }
    final defaultProfileIds = _settingsService
        .resolveProfileIdsForProjectCreation(settings);
    if (defaultProfileIds.isEmpty) {
      return;
    }
    final profilesById = <String, ExpressionConstraintProfile>{
      for (final profile in workspace.profiles) profile.id.trim(): profile,
    };
    final bindings = <ProjectExpressionConstraintBinding>[];
    for (final profileId in defaultProfileIds) {
      final profile = profilesById[profileId];
      if (profile == null ||
          !_supportsProjectType(profile, project.projectType)) {
        continue;
      }
      bindings.add(
        ProjectExpressionConstraintBinding(
          id: 'default_$profileId',
          profileId: profileId,
          enabled: true,
          defaultForProject: true,
          metadata: <String, Object?>{
            'source': 'app_default',
            'profile_id': profileId,
          },
        ),
      );
    }
    if (bindings.isEmpty) {
      return;
    }
    await _workspaceService.saveBindings(project, bindings);
  }

  bool _supportsProjectType(
    ExpressionConstraintProfile profile,
    String projectType,
  ) {
    final supportedProjectTypes = profile.recommendedScope.projectTypeIds;
    if (supportedProjectTypes.isEmpty) {
      return true;
    }
    return supportedProjectTypes.contains(projectType.trim());
  }
}
