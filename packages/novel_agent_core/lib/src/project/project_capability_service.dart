import 'project_trait.dart';
import 'project_trait_resolver_service.dart';

/// 项目能力判断的统一入口（复合项目类型核心）。
///
/// 拆书能力过去只靠 `projectType == 'book_deconstruction'` 字符串判断；引入复合项目类型后，
/// 一个项目可能已把 `projectType` 切到写作类型（novel/long_novel），但仍保留拆书能力——靠
/// manifest 持久化的 `additionalTraitIds`。本服务把"是否具备拆书能力"的两处来源统一收敛：
///
/// 1. manifest 持久化的 additionalTraitIds 含 book_deconstruction（复合项目）；
/// 2. projectType 本身仍是 'book_deconstruction'（旧项目退化识别）。
///
/// 项目能力必须来自可持久化的项目合同；临时运行 mode 只适合本轮任务路由，不能决定导航或
/// 资料工作区等长期设施是否可用。
class ProjectCapabilityService {
  const ProjectCapabilityService({
    ProjectTraitResolverService? traitResolverService,
  }) : _traitResolverService =
           traitResolverService ?? const ProjectTraitResolverService();

  final ProjectTraitResolverService _traitResolverService;

  /// 当前项目是否具备拆书能力。
  bool hasBookDeconstruction({
    required String projectTypeId,
    List<String> additionalTraitIds = const <String>[],
    String runtimeBaselineId = '',
  }) {
    final traits = _traitResolverService.resolve(
      projectTypeId: projectTypeId,
      runtimeBaselineId: runtimeBaselineId,
      additionalTraitIds: additionalTraitIds,
    );
    return traits.contains(ProjectTrait.bookDeconstruction);
  }
}
