import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_reference_extraction_strategy_picker_view_data.dart';

class ProjectReferenceExtractionStrategyPickerViewDataService {
  const ProjectReferenceExtractionStrategyPickerViewDataService({
    ReferenceExtractionStrategyProfileOptionService? optionService,
    ReferenceExtractionStrategyProfileCatalogService? catalogService,
  }) : _optionService =
           optionService ??
           const ReferenceExtractionStrategyProfileOptionService(),
       _catalogService =
           catalogService ??
           const ReferenceExtractionStrategyProfileCatalogService();

  final ReferenceExtractionStrategyProfileOptionService _optionService;
  final ReferenceExtractionStrategyProfileCatalogService _catalogService;

  ProjectReferenceExtractionStrategyPickerViewData build({
    String selectedProfileId = '',
    bool useDeconstructionProjection = false,
  }) {
    final normalizedSelectedProfileId = _catalogService.normalizeProfileId(
      selectedProfileId,
    );
    final options = _optionService
        .listOptions()
        .map(
          (option) => ProjectReferenceExtractionStrategyOptionViewData(
            profileId: option.profileId,
            displayName: option.displayName,
            summary: option.summary,
            proposalCountLabel: option.proposalCountLabel,
            entryKindsLabel: option.entryKindsLabel,
            reviewPolicyLabel: option.reviewPolicyLabel,
            badgeLabel: option.isBuiltin ? '内置' : '自定义',
          ),
        )
        .toList(growable: false);
    final selectedOption = options.firstWhere(
      (option) => option.profileId == normalizedSelectedProfileId,
      orElse: () => options.isEmpty
          ? const ProjectReferenceExtractionStrategyOptionViewData(
              profileId: '',
              displayName: '',
              summary: '',
              proposalCountLabel: '',
              entryKindsLabel: '',
              reviewPolicyLabel: '',
              badgeLabel: '',
            )
          : options.first,
    );
    final summary = selectedOption.profileId.isEmpty
        ? '当前没有可用的参考提取策略。'
        : '这是手动触发的知识提取流程。当前默认使用 ${selectedOption.displayName}；开始前可以切换策略。';
    return ProjectReferenceExtractionStrategyPickerViewData(
      selectedProfileId: selectedOption.profileId,
      summary: summary,
      sourceHint: useDeconstructionProjection
          ? '当前项目是拆书项目。本次不会重新要求你选择原始书稿，而会直接使用已确认的拆书产物作为提取源文。'
          : '当前项目会在开始后要求选择源资料文件；提取结果会沉淀为正式知识资产，而不是停留在临时摘要里。',
      confirmButtonLabel: useDeconstructionProjection ? '用拆书产物开始提取' : '选择资料并开始提取',
      options: options,
    );
  }

  String normalizeSelectedProfileId(String profileId) {
    return _catalogService.normalizeProfileId(profileId);
  }
}
