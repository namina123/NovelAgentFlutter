import '../continuity/continuity_build_spec.dart';
import '../project/project_type_catalog_service.dart';
import '../strategy/project_strategy.dart';
import '../strategy/strategy_catalog_service.dart';
import 'book_deconstruction_constants.dart';
import 'book_deconstruction_continuation_direction.dart';
import 'book_deconstruction_followup_group.dart';
import 'book_deconstruction_followup_menu.dart';
import 'book_deconstruction_followup_option.dart';

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
      _generalWritingGroup(),
      _longTaskWritingGroup(),
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
          ? '当前默认导向先补齐续写基座，不预选最终执行项目路线。'
          : '',
      metadata: const <String, Object?>{
        'source_project_type_id': BookDeconstructionConstants.projectTypeId,
      },
    );
  }

  BookDeconstructionFollowupGroup _generalWritingGroup() {
    final generalStrategy = _strategyOf('general_novel');
    final targetType = _projectTypeCatalogService.definitionOf('novel');
    return BookDeconstructionFollowupGroup(
      id: 'general_writing',
      title: '一般续写',
      description: '适合普通对话式续写与常规章节推进。',
      options: <BookDeconstructionFollowupOption>[
        BookDeconstructionFollowupOption(
          id: 'general_novel',
          title: generalStrategy.title,
          summary: '沿用普通小说工作台，优先承接最近剧情并逐步扩充连续性资产。',
          targetProjectTypeId: targetType.id,
          targetProjectStrategyId: generalStrategy.id,
          recommendedBuildTier: ContinuityBuildTier.quickBridge,
        ),
      ],
    );
  }

  BookDeconstructionFollowupGroup _longTaskWritingGroup() {
    final longTaskStrategy = _strategyOf(
      StrategyCatalogService.longTaskNovelStrategyId,
    );
    final targetType = _projectTypeCatalogService.definitionOf('long_novel');
    return BookDeconstructionFollowupGroup(
      id: 'long_task_writing',
      title: '长任务续写',
      description: '适合可恢复队列、阶段检查点和长期上下文托管。',
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
      id: mode.id,
      title: mode.title,
      summary: mode.description,
      targetProjectTypeId: targetProjectTypeId,
      targetProjectStrategyId: targetProjectStrategyId,
      targetModeId: mode.id,
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
        return 'general_writing';
      case BookDeconstructionContinuationDirection.longTaskPreferred:
        return 'long_task_writing';
      case BookDeconstructionContinuationDirection.analysisFirst:
        return '';
    }
  }

  String _highlightedOptionId(
    BookDeconstructionContinuationDirection preferredDirection,
  ) {
    switch (preferredDirection) {
      case BookDeconstructionContinuationDirection.generalNovelPreferred:
        return 'general_novel';
      case BookDeconstructionContinuationDirection.longTaskPreferred:
        return 'seed_autopilot_novel';
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
