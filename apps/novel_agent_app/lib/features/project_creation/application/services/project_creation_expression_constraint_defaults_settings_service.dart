import 'package:novel_agent_core/novel_agent_core.dart';

enum ProjectCreationExpressionConstraintDefaultsMode {
  builtinFallback,
  custom,
  disabled,
}

class ProjectCreationExpressionConstraintDefaultsSelection {
  const ProjectCreationExpressionConstraintDefaultsSelection({
    required this.mode,
    required this.profileIds,
  });

  final ProjectCreationExpressionConstraintDefaultsMode mode;
  final List<String> profileIds;
}

class ProjectCreationExpressionConstraintDefaultsSettingsService {
  const ProjectCreationExpressionConstraintDefaultsSettingsService();

  static const String settingsRootKey = 'project_creation_defaults';
  static const String profileIdsKey = 'expression_constraint_profile_ids';
  static const List<String> builtinFallbackProfileIds = <String>[
    'de_ai',
    'strict_pov_boundary',
    'low_jargon_narration',
  ];

  ProjectCreationExpressionConstraintDefaultsSelection resolveSelection(
    AppSettings settings,
  ) {
    final extraSettings = ValueReaders.mapValue(settings.extraSettings);
    final root = ValueReaders.mapValue(extraSettings[settingsRootKey]);
    if (root.containsKey(profileIdsKey)) {
      return _selectionFromConfiguredValue(root[profileIdsKey]);
    }
    if (extraSettings.containsKey(profileIdsKey)) {
      return _selectionFromConfiguredValue(extraSettings[profileIdsKey]);
    }
    return const ProjectCreationExpressionConstraintDefaultsSelection(
      mode: ProjectCreationExpressionConstraintDefaultsMode.builtinFallback,
      profileIds: builtinFallbackProfileIds,
    );
  }

  List<String> resolveProfileIdsForProjectCreation(AppSettings settings) {
    final selection = resolveSelection(settings);
    return switch (selection.mode) {
      ProjectCreationExpressionConstraintDefaultsMode.builtinFallback =>
        builtinFallbackProfileIds,
      ProjectCreationExpressionConstraintDefaultsMode.custom =>
        selection.profileIds,
      ProjectCreationExpressionConstraintDefaultsMode.disabled =>
        const <String>[],
    };
  }

  Map<String, Object?> mergedExtraSettingsForSelection({
    required AppSettings settings,
    required ProjectCreationExpressionConstraintDefaultsSelection selection,
  }) {
    final nextExtraSettings = ValueReaders.deepCopyMap(settings.extraSettings);
    nextExtraSettings.remove(profileIdsKey);
    if (selection.mode ==
        ProjectCreationExpressionConstraintDefaultsMode.builtinFallback) {
      final root = ValueReaders.deepCopyMap(
        ValueReaders.mapValue(nextExtraSettings[settingsRootKey]),
      );
      root.remove(profileIdsKey);
      if (root.isEmpty) {
        nextExtraSettings.remove(settingsRootKey);
      } else {
        nextExtraSettings[settingsRootKey] = root;
      }
      return nextExtraSettings;
    }
    final root = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(nextExtraSettings[settingsRootKey]),
    );
    root[profileIdsKey] = switch (selection.mode) {
      ProjectCreationExpressionConstraintDefaultsMode.disabled =>
        const <Object?>[],
      ProjectCreationExpressionConstraintDefaultsMode.custom =>
        List<Object?>.from(selection.profileIds, growable: false),
      ProjectCreationExpressionConstraintDefaultsMode.builtinFallback =>
        const <Object?>[],
    };
    nextExtraSettings[settingsRootKey] = root;
    return nextExtraSettings;
  }

  ProjectCreationExpressionConstraintDefaultsSelection
  _selectionFromConfiguredValue(Object? value) {
    final profileIds = _normalizedProfileIds(value);
    if (profileIds.isEmpty) {
      return const ProjectCreationExpressionConstraintDefaultsSelection(
        mode: ProjectCreationExpressionConstraintDefaultsMode.disabled,
        profileIds: <String>[],
      );
    }
    return ProjectCreationExpressionConstraintDefaultsSelection(
      mode: ProjectCreationExpressionConstraintDefaultsMode.custom,
      profileIds: profileIds,
    );
  }

  List<String> _normalizedProfileIds(Object? value) {
    final result = <String>[];
    for (final rawId in ValueReaders.stringList(value)) {
      final cleanId = rawId.trim();
      if (cleanId.isEmpty || result.contains(cleanId)) {
        continue;
      }
      result.add(cleanId);
    }
    return List<String>.unmodifiable(result);
  }
}
