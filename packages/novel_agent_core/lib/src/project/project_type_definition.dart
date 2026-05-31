import 'project_storage_strategy.dart';
import 'project_trait.dart';

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
    this.defaultTraits = const <ProjectTrait>[],
    this.requiresRuntimeBaselineSelection = false,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String description;
  final String defaultTitle;
  final List<ProjectStorageStrategy> supportedStorageStrategies;
  final List<ProjectTrait> defaultTraits;
  final bool requiresRuntimeBaselineSelection;
  final bool enabled;
}
