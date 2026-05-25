import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_entry_view_data.dart';
import '../../presentation/models/project_creation_phase.dart';
import '../../presentation/models/project_launcher_view_data.dart';
import '../../presentation/models/project_runtime_baseline_option_view_data.dart';
import '../../presentation/models/project_storage_strategy_option_view_data.dart';
import '../../presentation/models/project_type_option_view_data.dart';

class ProjectLauncherViewDataService {
  ProjectLauncherViewDataService({
    ProjectTypeCatalogService? projectTypeCatalogService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService();

  final ProjectTypeCatalogService _projectTypeCatalogService;

  ProjectLauncherViewData build({
    required ProjectLauncherMode mode,
    required String projectsRootPath,
    required List<JsonMap> projects,
    String status = '',
    String draftTitle = '',
    String selectedProjectTypeId = 'novel',
    ProjectStorageStrategy selectedStorageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    ProjectCreationPhase creationPhase = ProjectCreationPhase.basics,
    List<ProjectRuntimeBaselineDefinition> runtimeBaselineOptions =
        const <ProjectRuntimeBaselineDefinition>[],
    String selectedRuntimeBaselineId = '',
    bool canDismiss = true,
    bool allowOpenExisting = true,
  }) {
    // 中文注释: 项目启动面板的数据投影统一收口在这里，避免控制器直接理解核心层返回的动态字典。
    final normalizedProjectTypeId = _projectTypeCatalogService.normalize(
      selectedProjectTypeId,
    );
    final selectedProjectType = _projectTypeCatalogService.definitionOf(
      normalizedProjectTypeId,
    );
    final options = _projectTypeCatalogService
        .enabledDefinitions()
        .map(
          (definition) => ProjectTypeOptionViewData(
            id: definition.id,
            title: definition.name,
            description: definition.description,
            defaultTitle: definition.defaultTitle,
            requiresRuntimeBaselineSelection:
                definition.requiresRuntimeBaselineSelection,
          ),
        )
        .toList(growable: false);
    final storageStrategyOptions = selectedProjectType
        .supportedStorageStrategies
        .map(_storageOptionFrom)
        .toList(growable: false);
    return ProjectLauncherViewData(
      mode: mode,
      projectsRootPath: projectsRootPath,
      entries: projects
          .map(
            (project) => ProjectEntryViewData(
              id: project['id']?.toString() ?? '',
              title: project['title']?.toString() ?? '未命名项目',
              path: project['path']?.toString() ?? '',
            ),
          )
          .where((entry) => entry.path.trim().isNotEmpty)
          .toList(growable: false),
      status: status,
      draftTitle: draftTitle.trim().isEmpty
          ? selectedProjectType.defaultTitle
          : draftTitle,
      projectTypeOptions: options,
      selectedProjectTypeId: normalizedProjectTypeId,
      storageStrategyOptions: storageStrategyOptions,
      selectedStorageStrategyId: _resolveStorageStrategyId(
        selectedProjectType,
        selectedStorageStrategy,
      ),
      creationPhase: creationPhase,
      runtimeBaselineOptions: runtimeBaselineOptions
          .map(
            (definition) => ProjectRuntimeBaselineOptionViewData(
              id: definition.id,
              title: definition.title,
              description: definition.description,
            ),
          )
          .toList(growable: false),
      selectedRuntimeBaselineId: selectedRuntimeBaselineId.trim(),
      selectedProjectTypeRequiresRuntimeBaseline:
          selectedProjectType.requiresRuntimeBaselineSelection,
      canDismiss: canDismiss,
      allowOpenExisting: allowOpenExisting,
    );
  }

  ProjectStorageStrategyOptionViewData _storageOptionFrom(
    ProjectStorageStrategy strategy,
  ) {
    switch (strategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return const ProjectStorageStrategyOptionViewData(
          id: 'markdown_project_store',
          title: 'Markdown 项目',
          description: '主内容直接落到 Markdown / 普通文件，适合以文件树为主的创作方式。',
        );
      case ProjectStorageStrategy.sqliteProjectStore:
        return const ProjectStorageStrategyOptionViewData(
          id: 'sqlite_project_store',
          title: 'SQLite 项目',
          description: '主内容以结构化存储为主，Markdown 作为投影或导出层，适合后续结构化扩展。',
        );
    }
  }

  String _resolveStorageStrategyId(
    ProjectTypeDefinition definition,
    ProjectStorageStrategy selectedStorageStrategy,
  ) {
    // 中文注释: 视图层只保留当前项目类型支持的存储策略，避免显示一个实际无法提交的选项。
    for (final strategy in definition.supportedStorageStrategies) {
      if (strategy == selectedStorageStrategy) {
        return strategy.id;
      }
    }
    return definition.supportedStorageStrategies.isEmpty
        ? ProjectStorageStrategy.markdownProjectStore.id
        : definition.supportedStorageStrategies.first.id;
  }
}
