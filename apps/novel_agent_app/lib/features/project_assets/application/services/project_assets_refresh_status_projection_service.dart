import '../models/project_assets_catalog.dart';
import '../models/project_assets_refresh_scope.dart';
import '../../../../shared/services/user_facing_error_humanizer.dart';

class ProjectAssetsRefreshStatusProjectionService {
  const ProjectAssetsRefreshStatusProjectionService();

  String loadingMessage(ProjectAssetsRefreshScope scope, {String? status}) {
    final cleanStatus = status?.trim() ?? '';
    if (cleanStatus.isNotEmpty) {
      return cleanStatus;
    }
    switch (scope) {
      case ProjectAssetsRefreshScope.full:
        return '正在加载项目资产...';
      case ProjectAssetsRefreshScope.catalog:
        return '正在加载项目资产目录...';
      case ProjectAssetsRefreshScope.rag:
        return '正在加载语料状态...';
    }
  }

  String loadedMessage(
    ProjectAssetsRefreshScope scope,
    ProjectAssetsCatalog catalog, {
    String? status,
  }) {
    final cleanStatus = status?.trim() ?? '';
    if (cleanStatus.isNotEmpty) {
      return cleanStatus;
    }
    switch (scope) {
      case ProjectAssetsRefreshScope.full:
      case ProjectAssetsRefreshScope.catalog:
        return '已加载 ${catalog.styles.length} 个风格、${catalog.expressionConstraints.length} 个表达限制方案、${catalog.foreshadows.length} 个伏笔、${catalog.timelines.length} 条时间线、${catalog.relationships.length} 条关系。';
      case ProjectAssetsRefreshScope.rag:
        return '语料状态已同步。';
    }
  }

  String failureMessage(ProjectAssetsRefreshScope scope, Object error) {
    switch (scope) {
      case ProjectAssetsRefreshScope.full:
        return UserFacingErrorHumanizer.humanize(error, action: '加载项目资产');
      case ProjectAssetsRefreshScope.catalog:
        return UserFacingErrorHumanizer.humanize(error, action: '加载项目资产目录');
      case ProjectAssetsRefreshScope.rag:
        return UserFacingErrorHumanizer.humanize(error, action: '加载语料状态');
    }
  }
}
