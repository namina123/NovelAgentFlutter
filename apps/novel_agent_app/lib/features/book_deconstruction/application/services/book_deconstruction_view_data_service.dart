import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/book_deconstruction_continuity_view_data.dart';
import '../../presentation/models/book_deconstruction_followup_group_view_data.dart';
import '../../presentation/models/book_deconstruction_followup_option_view_data.dart';
import '../../presentation/models/book_deconstruction_plan_group_view_data.dart';
import '../../presentation/models/book_deconstruction_plan_item_view_data.dart';
import '../../presentation/models/book_deconstruction_preview_item_view_data.dart';
import '../../presentation/models/book_deconstruction_preview_section_view_data.dart';
import '../../presentation/models/book_deconstruction_step_view_data.dart';
import '../../presentation/models/book_deconstruction_view_data.dart';
import '../models/book_deconstruction_operation_kind.dart';
import '../models/book_deconstruction_snapshot.dart';
import '../models/book_deconstruction_step_id.dart';

class BookDeconstructionViewDataService {
  const BookDeconstructionViewDataService();

  BookDeconstructionViewData build({
    required String projectTitle,
    required BookDeconstructionSnapshot snapshot,
    required String status,
    bool canCreateDerivedProject = true,
  }) {
    final buildResult = snapshot.buildResult;
    final previewSections = buildResult == null
        ? const <BookDeconstructionPreviewSectionViewData>[]
        : _previewSectionsOf(buildResult);
    final planGroups = buildResult == null
        ? const <BookDeconstructionPlanGroupViewData>[]
        : _planGroupsOf(buildResult.applicationPlan, snapshot.selectedItemIds);
    final continuity = buildResult == null
        ? null
        : _continuityOf(
            buildResult.extractionResult,
            buildResult.followupMenu,
            snapshot.selectedFollowupOptionId,
          );
    final totalItemCount = buildResult?.applicationPlan.items.length ?? 0;
    return BookDeconstructionViewData(
      projectTitle: projectTitle,
      status: status,
      isLoading: snapshot.isLoading,
      operationKind: snapshot.operationKind,
      activeStepId: snapshot.activeStepId,
      steps: _stepsOf(snapshot),
      sourceAbsolutePath: snapshot.sourceAbsolutePath,
      sourceTitle: snapshot.sourceTitle,
      sourceContent: snapshot.sourceContent,
      operatorNotes: snapshot.operatorNotes,
      styleSummary: snapshot.styleSummary,
      worldRulesText: snapshot.worldRulesText,
      characterLinesText: snapshot.characterLinesText,
      organizationLinesText: snapshot.organizationLinesText,
      previewSections: previewSections,
      planGroups: planGroups,
      selectedItemCount: snapshot.selectedItemIds.length,
      totalItemCount: totalItemCount,
      selectedFollowupOptionId: snapshot.selectedFollowupOptionId,
      confirmedPreviewPath: snapshot.confirmedPreviewPath,
      canBuildPreview:
          !snapshot.isLoading && snapshot.sourceContent.trim().isNotEmpty,
      canConfirmSelection:
          !snapshot.isLoading &&
          buildResult != null &&
          snapshot.selectedItemIds.isNotEmpty &&
          snapshot.selectedFollowupOptionId.trim().isNotEmpty,
      canCreateDerivedProject:
          !snapshot.isLoading &&
          buildResult != null &&
          snapshot.selectedItemIds.isNotEmpty &&
          snapshot.selectedFollowupOptionId.trim().isNotEmpty &&
          canCreateDerivedProject,
      importActionLabel: _importActionLabel(snapshot.operationKind),
      buildPreviewActionLabel: _buildPreviewActionLabel(snapshot.operationKind),
      continuity: continuity,
    );
  }

  String _importActionLabel(String operationKind) {
    switch (operationKind) {
      case BookDeconstructionOperationKind.importingSource:
        return '正在导入';
      default:
        return '导入文件';
    }
  }

  String _buildPreviewActionLabel(String operationKind) {
    switch (operationKind) {
      case BookDeconstructionOperationKind.buildingPreview:
        return '正在拆书';
      default:
        return '生成结构化预览';
    }
  }

  List<BookDeconstructionStepViewData> _stepsOf(
    BookDeconstructionSnapshot snapshot,
  ) {
    final hasPreview = snapshot.buildResult != null;
    final hasConfirmation = snapshot.confirmedPreviewPath.trim().isNotEmpty;
    return <BookDeconstructionStepViewData>[
      BookDeconstructionStepViewData(
        id: BookDeconstructionStepId.importSource,
        title: '导入源文稿',
        description: '导入文本文件或直接粘贴原文，再补充必要的拆书说明。',
        isActive:
            snapshot.activeStepId == BookDeconstructionStepId.importSource,
        isComplete: snapshot.sourceContent.trim().isNotEmpty,
      ),
      BookDeconstructionStepViewData(
        id: BookDeconstructionStepId.previewStructure,
        title: '结构化预览',
        description: '查看自动整理出的前提、章节、连续性关键信息与拟应用条目。',
        isActive:
            snapshot.activeStepId == BookDeconstructionStepId.previewStructure,
        isComplete: hasPreview,
      ),
      BookDeconstructionStepViewData(
        id: BookDeconstructionStepId.confirmSelection,
        title: '应用前确认',
        description: '确认当前勾选结果，并保留后续续写菜单与预演纪要。',
        isActive:
            snapshot.activeStepId == BookDeconstructionStepId.confirmSelection,
        isComplete: hasConfirmation,
      ),
    ];
  }

  List<BookDeconstructionPreviewSectionViewData> _previewSectionsOf(
    BookDeconstructionDraftBuildResult buildResult,
  ) {
    final extraction = buildResult.extractionResult;
    final sections = <BookDeconstructionPreviewSectionViewData>[];
    if (extraction.premises.isNotEmpty) {
      sections.add(
        BookDeconstructionPreviewSectionViewData(
          id: 'premises',
          title: '前提提取',
          description: '从源文稿中收束出的创作前提。',
          items: extraction.premises
              .map(
                (item) => BookDeconstructionPreviewItemViewData(
                  id: item.id,
                  title: item.displayName,
                  summary: item.summary,
                ),
              )
              .toList(growable: false),
        ),
      );
    }
    if (extraction.storyOutlineSummary.trim().isNotEmpty) {
      sections.add(
        BookDeconstructionPreviewSectionViewData(
          id: 'story_outline',
          title: '故事总纲',
          description: '整体结构与主线走向的压缩摘要。',
          items: <BookDeconstructionPreviewItemViewData>[
            BookDeconstructionPreviewItemViewData(
              id: 'story_outline',
              title: '结构摘要',
              summary: extraction.storyOutlineSummary.trim(),
            ),
          ],
        ),
      );
    }
    if (extraction.chapterOutlines.isNotEmpty) {
      sections.add(
        BookDeconstructionPreviewSectionViewData(
          id: 'chapter_outlines',
          title: '章节骨架',
          description: '已识别出的章节级结构片段。',
          items: extraction.chapterOutlines
              .map(
                (item) => BookDeconstructionPreviewItemViewData(
                  id: item.id,
                  title: item.title,
                  summary: item.summary,
                  caption: '章节 ${item.sequence}',
                ),
              )
              .toList(growable: false),
        ),
      );
    }
    _addAssetSection(
      sections,
      id: 'styles',
      title: '风格资产',
      description: '可复用的风格提要。',
      entries: extraction.styleProfiles
          .map(
            (item) => BookDeconstructionPreviewItemViewData(
              id: item.id,
              title: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addAssetSection(
      sections,
      id: 'world',
      title: '世界规则',
      description: '从源文稿或补充说明里收束出的世界约束。',
      entries: extraction.worldRuleSets
          .map(
            (item) => BookDeconstructionPreviewItemViewData(
              id: item.id,
              title: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addAssetSection(
      sections,
      id: 'characters',
      title: '角色资产',
      description: '拆书时显式标出的角色条目。',
      entries: extraction.characterProfiles
          .map(
            (item) => BookDeconstructionPreviewItemViewData(
              id: item.id,
              title: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addAssetSection(
      sections,
      id: 'organizations',
      title: '组织资产',
      description: '拆书时显式标出的组织/势力条目。',
      entries: extraction.organizationProfiles
          .map(
            (item) => BookDeconstructionPreviewItemViewData(
              id: item.id,
              title: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addAssetSection(
      sections,
      id: 'foreshadows',
      title: '伏笔资产',
      description: '从原文结构中识别出的潜在线索与未回收钩子。',
      entries: extraction.foreshadowRecords
          .map(
            (item) => BookDeconstructionPreviewItemViewData(
              id: item.id,
              title: item.title,
              summary: item.summary,
              caption: item.status,
            ),
          )
          .toList(growable: false),
    );
    _addAssetSection(
      sections,
      id: 'timeline',
      title: '时间线资产',
      description: '按章节演进收束出的阶段事件与时间推进骨架。',
      entries: extraction.timelineRecords
          .map(
            (item) => BookDeconstructionPreviewItemViewData(
              id: item.id,
              title: item.displayName,
              summary: item.summary,
              caption: item.phaseLabel,
            ),
          )
          .toList(growable: false),
    );
    _addAssetSection(
      sections,
      id: 'relationships',
      title: '关系资产',
      description: '角色共同出现与互动关系的初步结构。',
      entries: extraction.relationshipRecords
          .map(
            (item) => BookDeconstructionPreviewItemViewData(
              id: item.id,
              title: item.displayName,
              summary: item.summary,
              caption: item.relationshipType,
            ),
          )
          .toList(growable: false),
    );
    return sections;
  }

  void _addAssetSection(
    List<BookDeconstructionPreviewSectionViewData> sections, {
    required String id,
    required String title,
    required String description,
    required List<BookDeconstructionPreviewItemViewData> entries,
  }) {
    if (entries.isEmpty) {
      return;
    }
    sections.add(
      BookDeconstructionPreviewSectionViewData(
        id: id,
        title: title,
        description: description,
        items: entries,
      ),
    );
  }

  List<BookDeconstructionPlanGroupViewData> _planGroupsOf(
    BookDeconstructionApplicationPlan plan,
    Set<String> selectedItemIds,
  ) {
    final groupOrder = <String>[
      BookDeconstructionArtifactKind.premise,
      BookDeconstructionArtifactKind.storyOutline,
      BookDeconstructionArtifactKind.chapterOutline,
      BookDeconstructionArtifactKind.styleProfile,
      BookDeconstructionArtifactKind.worldRuleSet,
      BookDeconstructionArtifactKind.characterProfile,
      BookDeconstructionArtifactKind.organizationProfile,
      BookDeconstructionArtifactKind.foreshadowRecord,
      BookDeconstructionArtifactKind.timelineRecord,
      BookDeconstructionArtifactKind.relationshipRecord,
    ];
    final groups = <String, List<BookDeconstructionPlanItemViewData>>{};
    for (final item in plan.items) {
      groups
          .putIfAbsent(
            item.targetKind,
            () => <BookDeconstructionPlanItemViewData>[],
          )
          .add(
            BookDeconstructionPlanItemViewData(
              id: item.id,
              title: item.displayName,
              summary: item.summary,
              relativePathHint: item.relativePathHint,
              actionLabel: _actionLabel(item.action),
              isSelected: selectedItemIds.contains(item.id),
            ),
          );
    }
    return groupOrder
        .where(groups.containsKey)
        .map(
          (groupId) => BookDeconstructionPlanGroupViewData(
            id: groupId,
            title: _groupTitle(groupId),
            description: _groupDescription(groupId),
            items: groups[groupId]!,
          ),
        )
        .toList(growable: false);
  }

  String _groupTitle(String groupId) {
    switch (groupId) {
      case BookDeconstructionArtifactKind.premise:
        return '前提';
      case BookDeconstructionArtifactKind.storyOutline:
        return '故事总纲';
      case BookDeconstructionArtifactKind.chapterOutline:
        return '章纲';
      case BookDeconstructionArtifactKind.styleProfile:
        return '风格';
      case BookDeconstructionArtifactKind.worldRuleSet:
        return '世界规则';
      case BookDeconstructionArtifactKind.characterProfile:
        return '角色';
      case BookDeconstructionArtifactKind.organizationProfile:
        return '组织';
      case BookDeconstructionArtifactKind.foreshadowRecord:
        return '伏笔';
      case BookDeconstructionArtifactKind.timelineRecord:
        return '时间线';
      case BookDeconstructionArtifactKind.relationshipRecord:
        return '关系';
      default:
        return '其他';
    }
  }

  String _groupDescription(String groupId) {
    switch (groupId) {
      case BookDeconstructionArtifactKind.premise:
        return '写入 premise/，供后续写作与长任务复用。';
      case BookDeconstructionArtifactKind.storyOutline:
        return '写入 outlines/story/。';
      case BookDeconstructionArtifactKind.chapterOutline:
        return '写入 outlines/chapters/。';
      default:
        return '映射回现有共享资产目录。';
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case BookDeconstructionApplicationAction.createOrMergeAsset:
        return '创建/合并资产';
      case BookDeconstructionApplicationAction.createOrMergeDocument:
      default:
        return '创建/合并文档';
    }
  }

  BookDeconstructionContinuityViewData _continuityOf(
    BookDeconstructionExtractionResult extraction,
    BookDeconstructionFollowupMenu followupMenu,
    String selectedOptionId,
  ) {
    final continuityHints = extraction.continuityHints;
    return BookDeconstructionContinuityViewData(
      preferredDirectionLabel: _preferredDirectionLabel(
        followupMenu.preferredDirection,
      ),
      highlightedBuildTierLabel: _buildTierLabel(
        followupMenu.highlightedBuildTier,
      ),
      highlightedRouteTitle: _highlightedRouteTitle(followupMenu),
      selectedRouteOptionId: selectedOptionId,
      selectedRouteTitle: _selectedRouteTitle(followupMenu, selectedOptionId),
      scopeHintCount: continuityHints.scopeMap.scopes.length,
      identityMappingCount: continuityHints.identityMappings.length,
      mechanicHintCount: continuityHints.mechanicHints.length,
      followupGroups: followupMenu.groups
          .map(
            (group) => BookDeconstructionFollowupGroupViewData(
              id: group.id,
              title: _followupGroupTitle(group.id, group.title),
              description: group.description,
              isFutureExtensionGroup: ValueReaders.boolValue(
                group.metadata['reserved'],
              ),
              options: group.options
                  .map(
                    (option) => BookDeconstructionFollowupOptionViewData(
                      id: option.id,
                      title: option.title,
                      summary: option.summary,
                      buildTierLabel: _buildTierLabel(
                        option.recommendedBuildTier,
                      ),
                      isHighlighted:
                          option.id == followupMenu.highlightedOptionId,
                      isSelected: option.id == selectedOptionId,
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
      summary: _continuitySummary(
        followupMenu.preferredDirection,
        followupMenu,
        continuityHints,
      ),
    );
  }

  String _preferredDirectionLabel(
    BookDeconstructionContinuationDirection direction,
  ) {
    switch (direction) {
      case BookDeconstructionContinuationDirection.generalNovelPreferred:
        return '普通续写优先';
      case BookDeconstructionContinuationDirection.longTaskPreferred:
        return '长任务续写优先';
      case BookDeconstructionContinuationDirection.analysisFirst:
        return '先拆书分析';
    }
  }

  String _buildTierLabel(ContinuityBuildTier tier) {
    switch (tier) {
      case ContinuityBuildTier.quickBridge:
        return '快速承接';
      case ContinuityBuildTier.standardFoundation:
        return '标准基座';
      case ContinuityBuildTier.deepReconstruction:
        return '深度重构';
    }
  }

  String _highlightedRouteTitle(BookDeconstructionFollowupMenu menu) {
    if (menu.highlightedOptionId.trim().isEmpty) {
      return '暂不预选，确认后仍可多路派生';
    }
    for (final group in menu.groups) {
      for (final option in group.options) {
        if (option.id == menu.highlightedOptionId) {
          return option.title;
        }
      }
    }
    return '暂不预选，确认后仍可多路派生';
  }

  String _selectedRouteTitle(
    BookDeconstructionFollowupMenu menu,
    String selectedOptionId,
  ) {
    final cleanId = selectedOptionId.trim();
    if (cleanId.isEmpty) {
      return '尚未选择';
    }
    for (final group in menu.groups) {
      for (final option in group.options) {
        if (option.id == cleanId) {
          return option.title;
        }
      }
    }
    return '尚未选择';
  }

  String _continuitySummary(
    BookDeconstructionContinuationDirection direction,
    BookDeconstructionFollowupMenu menu,
    BookDeconstructionContinuityHints hints,
  ) {
    final hintParts = <String>[
      if (hints.scopeMap.scopes.isNotEmpty)
        '作用域提示 ${hints.scopeMap.scopes.length} 项',
      if (hints.identityMappings.isNotEmpty)
        '身份映射 ${hints.identityMappings.length} 项',
      if (hints.mechanicHints.isNotEmpty)
        '机制提示 ${hints.mechanicHints.length} 项',
    ];
    final base =
        direction == BookDeconstructionContinuationDirection.analysisFirst
        ? '当前默认先补齐 continuation 与 fanfic 基座，再决定最终执行方案。'
        : '当前预演确认后，可直接沿默认导向进入后续方案。';
    if (hintParts.isEmpty) {
      return '$base 目前仍以结构化资产与后续方案为主。';
    }
    return '$base 已识别：${hintParts.join('，')}。';
  }

  String _followupGroupTitle(String groupId, String fallbackTitle) {
    switch (groupId) {
      case 'continuation':
        return '续写';
      case 'fanfic':
        return '同人';
      case 'future_extensions':
        return '未来其他路线';
      default:
        return fallbackTitle;
    }
  }
}
