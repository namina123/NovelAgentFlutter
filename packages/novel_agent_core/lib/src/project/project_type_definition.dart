import 'project_storage_strategy.dart';

class ProjectTypeDefinition {
  const ProjectTypeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultTitle,
    this.supportedStorageStrategies = const <ProjectStorageStrategy>[
      ProjectStorageStrategy.markdownProjectStore,
      ProjectStorageStrategy.sqliteProjectStore,
    ],
    this.requiresRuntimeBaselineSelection = false,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String description;
  final String defaultTitle;
  final List<ProjectStorageStrategy> supportedStorageStrategies;
  final bool requiresRuntimeBaselineSelection;
  final bool enabled;
}
