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
        : '当前默认使用 ${selectedOption.displayName}；提取前可以切换策略。';
    return ProjectReferenceExtractionStrategyPickerViewData(
      selectedProfileId: selectedOption.profileId,
      summary: summary,
      options: options,
    );
  }

  String normalizeSelectedProfileId(String profileId) {
    return _catalogService.normalizeProfileId(profileId);
  }
}
