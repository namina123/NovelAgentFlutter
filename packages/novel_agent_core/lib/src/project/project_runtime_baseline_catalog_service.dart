import 'project_runtime_baseline_definition.dart';
import '../runtime/runtime_baseline_catalog_service.dart';

class ProjectRuntimeBaselineCatalogService {
  const ProjectRuntimeBaselineCatalogService({
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService();

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;

  List<ProjectRuntimeBaselineDefinition> definitionsForProjectType(
    String projectTypeId,
  ) {
    // 中文注释: 运行基准目录按项目类型过滤，避免普通小说或知识库项目被迫暴露长任务专属选择。
    return List<ProjectRuntimeBaselineDefinition>.unmodifiable(
      _runtimeBaselineCatalogService
          .forProjectType(projectTypeId)
          .map(
            (baseline) => ProjectRuntimeBaselineDefinition(
              id: baseline.id,
              title: baseline.title,
              description: baseline.description,
              enabled: baseline.enabled,
            ),
          ),
    );
  }

  bool requiresSelection(String projectTypeId) {
    // 中文注释: 当前只有返回了可选运行基准的项目类型，才进入第二阶段选择页。
    return definitionsForProjectType(projectTypeId).isNotEmpty;
  }

  String normalizeForProjectType(String projectTypeId, String baselineId) {
    // 中文注释: 运行基准只接受当前项目类型已登记的值，未知值统一回退为空，交给创建流程继续补选。
    return _runtimeBaselineCatalogService.normalizeForProjectType(
      projectTypeId,
      baselineId,
    );
  }

  bool containsForProjectType(String projectTypeId, String baselineId) {
    final cleanBaselineId = baselineId.trim();
    return cleanBaselineId.isNotEmpty &&
        normalizeForProjectType(projectTypeId, cleanBaselineId) ==
            cleanBaselineId;
  }
}
