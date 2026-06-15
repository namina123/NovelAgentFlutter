import '../continuity/continuity_build_spec.dart';
import '../project/project_type_catalog_service.dart';
import '../strategy/project_strategy.dart';
import '../strategy/strategy_catalog_service.dart';
import 'book_deconstruction_constants.dart';
import 'book_deconstruction_continuation_direction.dart';
import 'book_deconstruction_followup_group.dart';
import 'book_deconstruction_followup_menu.dart';
import 'book_deconstruction_followup_option.dart';
import 'book_deconstruction_source_inheritance_mode.dart';

class BookDeconstructionFollowupMenuBuilderService {
  const BookDeconstructionFollowupMenuBuilderService({
    ProjectTypeCatalogService? projectTypeCatalogService,
    StrategyCatalogService? strategyCatalogService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _strategyCatalogService =
           strategyCatalogService ?? const StrategyCatalogService();

  final ProjectTypeCatalogService _projectTypeCatalogService;
  final StrategyCatalogService _strategyCatalogService;

  BookDeconstructionFollowupMenu build({
    required BookDeconstructionContinuationDirection preferredDirection,
  }) {
    final groups = <BookDeconstructionFollowupGroup>[
      _continuationGroup(),
      _fanficGroup(),
      _futureExtensionsGroup(),
    ];
    final highlightedGroupId = _highlightedGroupId(preferredDirection);
    final highlightedOptionId = _highlightedOptionId(preferredDirection);
    return BookDeconstructionFollowupMenu(
      preferredDirection: preferredDirection,
      groups: groups,
      highlightedGroupId: highlightedGroupId,
      highlightedOptionId: highlightedOptionId,
      highlightedBuildTier: _highlightedBuildTier(preferredDirection),
      allowsMultipleDerivedProjects: true,
      notes:
          preferredDirection ==
              BookDeconstructionContinuationDirection.analysisFirst
          ? '当前默认导向先补齐 continuation / fanfic 基座，不预选最终执行项目路线。'
          : '',
      metadata: const <String, Object?>{
        'source_project_type_id': BookDeconstructionConstants.projectTypeId,
      },
    );
  }

  BookDeconstructionFollowupGroup _continuationGroup() {
    final generalStrategy = _strategyOf('general_novel');
    final targetType = _projectTypeCatalogService.definitionOf('novel');
    return BookDeconstructionFollowupGroup(
      id: 'continuation',
      title: 'continuation',
      description: '把原作章节接入连续正文链，适合继续原作剧情推进。',
      options: <BookDeconstructionFollowupOption>[
        BookDeconstructionFollowupOption(
          id: 'continuation_novel',
          title: generalStrategy.title,
          summary: '原作章节进入叙事连续体，后续写作会把它当作正文前情。',
          targetProjectTypeId: targetType.id,
          targetProjectStrategyId: generalStrategy.id,
          sourceInheritanceMode:
              BookDeconstructionSourceInheritanceMode.continuation,
          recommendedBuildTier: ContinuityBuildTier.quickBridge,
        ),
      ],
    );
  }

  BookDeconstructionFollowupGroup _fanficGroup() {
    final longTaskStrategy = _strategyOf(
      StrategyCatalogService.longTaskNovelStrategyId,
    );
    final targetType = _projectTypeCatalogService.definitionOf('long_novel');
    return BookDeconstructionFollowupGroup(
      id: 'fanfic',
      title: 'fanfic',
      description: '把原作保留在来源 / 参考层，派生出基于原作的全新创作路线。',
      options: longTaskStrategy.supportedModeIds
          .map(
            (modeId) => _optionForLongTaskMode(
              targetType.id,
              longTaskStrategy.id,
              modeId,
            ),
          )
          .toList(growable: false),
    );
  }

  BookDeconstructionFollowupGroup _futureExtensionsGroup() {
    return const BookDeconstructionFollowupGroup(
      id: 'future_extensions',
      title: '未来其他路线',
      description: '为后续新增的续写路线保留稳定分组，不把拆书后续菜单绑死在当前几种模式上。',
      options: <BookDeconstructionFollowupOption>[],
      metadata: <String, Object?>{'reserved': true},
    );
  }

  BookDeconstructionFollowupOption _optionForLongTaskMode(
    String targetProjectTypeId,
    String targetProjectStrategyId,
    String modeId,
  ) {
    final mode = _strategyCatalogService.modeDefinitionById(modeId);
    return BookDeconstructionFollowupOption(
      id: 'fanfic_${mode.id}',
      title: mode.title,
      summary: '原作内容停留在来源与参考层，${
          mode.description.trim()
        }',
      targetProjectTypeId: targetProjectTypeId,
      targetProjectStrategyId: targetProjectStrategyId,
      targetModeId: mode.id,
      sourceInheritanceMode: BookDeconstructionSourceInheritanceMode.fanfic,
      recommendedBuildTier: _recommendedBuildTierForMode(mode.id),
    );
  }

  ContinuityBuildTier _recommendedBuildTierForMode(String modeId) {
    switch (modeId) {
      case 'full_outline_consensus':
      case 'salvage_restructure_existing':
        return ContinuityBuildTier.deepReconstruction;
      case 'seed_autopilot_novel':
      case 'volume_checkpoint_handoff':
      case 'chapter_brief_supervised':
      default:
        return ContinuityBuildTier.standardFoundation;
    }
  }

  String _highlightedGroupId(
    BookDeconstructionContinuationDirection preferredDirection,
  ) {
    switch (preferredDirection) {
      case BookDeconstructionContinuationDirection.generalNovelPreferred:
        return 'continuation';
      case BookDeconstructionContinuationDirection.longTaskPreferred:
        return 'fanfic';
      case BookDeconstructionContinuationDirection.analysisFirst:
        return '';
    }
  }

  String _highlightedOptionId(
    BookDeconstructionContinuationDirection preferredDirection,
  ) {
    switch (preferredDirection) {
      case BookDeconstructionContinuationDirection.generalNovelPreferred:
        return 'continuation_novel';
      case BookDeconstructionContinuationDirection.longTaskPreferred:
        return 'fanfic_seed_autopilot_novel';
      case BookDeconstructionContinuationDirection.analysisFirst:
        return '';
    }
  }

  ContinuityBuildTier _highlightedBuildTier(
    BookDeconstructionContinuationDirection preferredDirection,
  ) {
    switch (preferredDirection) {
      case BookDeconstructionContinuationDirection.generalNovelPreferred:
        return ContinuityBuildTier.quickBridge;
      case BookDeconstructionContinuationDirection.longTaskPreferred:
        return ContinuityBuildTier.standardFoundation;
      case BookDeconstructionContinuationDirection.analysisFirst:
        return ContinuityBuildTier.standardFoundation;
    }
  }

  ProjectStrategy _strategyOf(String strategyId) {
    return _strategyCatalogService.projectStrategies().firstWhere(
      (item) => item.id == strategyId,
    );
  }
}
