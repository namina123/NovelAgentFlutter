import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_entry_view_data.dart';
import '../../presentation/models/project_launcher_view_data.dart';
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
    String selectedProjectTypeId = 'novel',
    bool canDismiss = true,
    bool allowOpenExisting = true,
  }) {
    // 中文注释: 项目启动面板的数据投影统一收口在这里，避免控制器直接理解核心层返回的动态字典。
    final options = _projectTypeCatalogService
        .enabledDefinitions()
        .map(
          (definition) => ProjectTypeOptionViewData(
            id: definition.id,
            title: definition.name,
            description: definition.description,
            defaultTitle: definition.defaultTitle,
          ),
        )
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
      projectTypeOptions: options,
      selectedProjectTypeId: _projectTypeCatalogService.normalize(
        selectedProjectTypeId,
      ),
      canDismiss: canDismiss,
      allowOpenExisting: allowOpenExisting,
    );
  }
}
