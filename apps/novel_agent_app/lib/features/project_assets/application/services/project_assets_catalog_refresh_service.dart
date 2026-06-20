import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_assets_catalog_refresh_result.dart';
import 'project_assets_loader_service.dart';
import 'project_assets_view_data_service.dart';

class ProjectAssetsCatalogRefreshService {
  ProjectAssetsCatalogRefreshService({
    required ProjectAssetsLoaderService loaderService,
    required ProjectAssetsViewDataService viewDataService,
    required List<JsonMap> Function() readAvailableProjectAgents,
  }) : _loaderService = loaderService,
       _viewDataService = viewDataService,
       _readAvailableProjectAgents = readAvailableProjectAgents;

  final ProjectAssetsLoaderService _loaderService;
  final ProjectAssetsViewDataService _viewDataService;
  final List<JsonMap> Function() _readAvailableProjectAgents;

  Future<ProjectAssetsCatalogRefreshResult> refresh(
    ProjectDescriptor project,
  ) async {
    final catalog = await _loaderService.load(project);
    return ProjectAssetsCatalogRefreshResult(
      catalog: catalog,
      availableAgentOptions: _viewDataService.buildExpressionConstraintAgentOptions(
        _readAvailableProjectAgents(),
      ),
      availableModeOptions:
          _viewDataService.buildExpressionConstraintModeOptions(),
      availableStageOptions:
          _viewDataService.buildExpressionConstraintStageOptions(),
      statusMessage:
          '已加载 ${catalog.styles.length} 个风格、${catalog.expressionConstraints.length} 个表达限制方案、${catalog.foreshadows.length} 个伏笔、${catalog.timelines.length} 条时间线、${catalog.relationships.length} 条关系。',
    );
  }
}
