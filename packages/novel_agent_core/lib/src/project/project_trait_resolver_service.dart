import 'project_type_catalog_service.dart';
import 'project_runtime_baseline_catalog_service.dart';
import 'project_trait.dart';
import 'project_trait_set.dart';

class ProjectTraitResolverService {
  const ProjectTraitResolverService({
    ProjectTypeCatalogService? projectTypeCatalogService,
    ProjectRuntimeBaselineCatalogService? projectRuntimeBaselineCatalogService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _projectRuntimeBaselineCatalogService =
           projectRuntimeBaselineCatalogService ??
           const ProjectRuntimeBaselineCatalogService();

  final ProjectTypeCatalogService _projectTypeCatalogService;
  final ProjectRuntimeBaselineCatalogService
  _projectRuntimeBaselineCatalogService;

  ProjectTraitSet resolve({
    required String projectTypeId,
    String runtimeBaselineId = '',
    String modeId = '',
    List<String> additionalTraitIds = const <String>[],
  }) {
    // 中文注释: 项目 traits 统一从项目类型、运行基线、模式线索和外部附加标签合成，避免上层各自硬编码。
    final definition = _projectTypeCatalogService.definitionOf(projectTypeId);
    final normalizedRuntimeBaselineId = _projectRuntimeBaselineCatalogService
        .normalizeForProjectType(definition.id, runtimeBaselineId);
    var traits = ProjectTraitSet(definition.defaultTraits);
    traits = traits.mergedWith(
      _traitsForRuntimeBaseline(normalizedRuntimeBaselineId),
    );
    traits = traits.mergedWith(_traitsForMode(modeId));
    return traits.mergedWithIds(additionalTraitIds);
  }

  List<ProjectTrait> _traitsForRuntimeBaseline(String runtimeBaselineId) {
    // 中文注释: 运行基线目前只补充最小必要语义，后续若新增质量优先或高审批密度基线，再继续扩这层。
    switch (runtimeBaselineId.trim()) {
      case 'continuous_autonomous':
        return const <ProjectTrait>[
          ProjectTrait.longTask,
          ProjectTrait.seedDriven,
        ];
      case 'chapter_collaboration_autorun':
        return const <ProjectTrait>[
          ProjectTrait.longTask,
          ProjectTrait.fullOutline,
        ];
      default:
        return const <ProjectTrait>[];
    }
  }

  List<ProjectTrait> _traitsForMode(String modeId) {
    // 中文注释: mode 只补充稳定的领域语义，不在这里承载具体 UI 阶段或运行细节。
    switch (modeId.trim()) {
      case 'seed_autopilot_novel':
        return const <ProjectTrait>[
          ProjectTrait.seedDriven,
          ProjectTrait.openingGuided,
        ];
      case 'full_outline_consensus':
        return const <ProjectTrait>[
          ProjectTrait.fullOutline,
          ProjectTrait.openingGuided,
        ];
      case 'book_asset_extraction':
        return const <ProjectTrait>[ProjectTrait.bookDeconstruction];
      default:
        return const <ProjectTrait>[];
    }
  }
}
