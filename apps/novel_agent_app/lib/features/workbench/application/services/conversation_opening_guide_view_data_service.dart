import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_guide_view_data.dart';
import '../models/opening_session_projection.dart';
import '../models/project_opening_maturity_assessment.dart';
import '../models/project_opening_maturity_stage.dart';
import '../../presentation/models/primary_action_view_data.dart';
import 'conversation_opening_state_view_data_service.dart';

class ConversationOpeningGuideViewDataService {
  const ConversationOpeningGuideViewDataService({
    ConversationOpeningStateViewDataService? openingStateViewDataService,
  }) : _openingStateViewDataService =
           openingStateViewDataService ??
           const ConversationOpeningStateViewDataService();

  final ConversationOpeningStateViewDataService _openingStateViewDataService;

  ConversationGuideViewData buildLongTaskGuide(
    OpeningSessionProjection projection, {
    required bool isGenerating,
    required PrimaryActionViewData startAction,
    required ProjectOpeningMaturityAssessment maturity,
  }) {
    // 中文注释: 长任务默认界面只保留唯一启动动作，具体分支继续沿用 opening projection 链路。
    final orchestration = projection.orchestration;
    final readiness = orchestration.readiness;
    final currentGroupText = projection.currentGroupDisplayName.trim().isEmpty
        ? '当前还没有确定开局智能体组。'
        : '当前智能体组：${projection.currentGroupDisplayName}';
    final readinessText = readiness.canStartLongTask
        ? '当前开局信息已收束完成，可以直接启动长任务。'
        : orchestration.readiness.missingRequirements.isEmpty
        ? '当前仍需补充长任务开局信息。'
        : '仍需补充：${orchestration.readiness.missingRequirements.map((item) => item.title).join('、')}';
    return ConversationGuideViewData(
      workflowTitle: '长任务开局',
      workflowDescription: '$currentGroupText\n$readinessText',
      composerHint: isGenerating
          ? '生成中：可以继续补充长篇边界、节奏、角色和检查点约束。'
          : readiness.canStartLongTask
          ? '点击“启动长任务”即可；也可以直接补充更多开局约束。'
          : '先点“启动长任务”继续补齐缺口；也可以直接输入你希望这部长篇如何开局、推进和收束。',
      primaryActions: <PrimaryActionViewData>[startAction],
    ).copyWith(
      openingState: _openingStateViewDataService.build(
        projectType: projection.projectTypeId,
        maturity: maturity,
        primaryActions: <PrimaryActionViewData>[startAction],
        projection: projection,
        preferredNextAction: startAction,
        firstPromptOverride: readiness.canStartLongTask
            ? '可以直接启动长任务，也可以先补一句额外约束。'
            : '先补齐长任务开局缺口。',
        nextStepLabelOverride: startAction.title,
        preferSingleAction: true,
      ),
    );
  }

  ConversationGuideViewData decorateInteractiveGuide({
    required ConversationGuideViewData fallbackGuide,
    required OpeningSessionProjection projection,
    required ProjectOpeningMaturityAssessment maturity,
    required bool isGenerating,
  }) {
    // 中文注释: 普通协作项目先复用现有轻会话入口，只把当前智能体组与 opening 状态补进描述层。
    final orchestration = projection.orchestration;
    final missingTitles = orchestration.readiness.missingRequirements
        .where((item) => item.id.trim() != 'conversation_goal')
        .map((item) => item.title)
        .join('、');
    final summaryLines = <String>[
      if (projection.currentGroupDisplayName.trim().isNotEmpty)
        '当前智能体组：${projection.currentGroupDisplayName}',
      if (projection.derivedFromAgentBinding) '当前智能体组来自旧项目智能体绑定自动派生。',
      if (projection.currentGroupDisplayName.trim().isEmpty &&
          projection.groupSummaries.isEmpty)
        '当前项目还没有可直接使用的智能体组。',
      if (missingTitles.trim().isNotEmpty) '当前还缺：$missingTitles',
      if (orchestration.readiness.canStartInteractiveSession) '当前已可直接进入普通协作会话。',
    ];
    if (summaryLines.isEmpty) {
      return fallbackGuide;
    }
    return ConversationGuideViewData(
      workflowTitle: fallbackGuide.workflowTitle,
      workflowDescription:
          '${fallbackGuide.workflowDescription}\n\n${summaryLines.join('\n')}',
      composerHint: isGenerating
          ? fallbackGuide.composerHint
          : '可以先描述题材、主线、角色、世界观或想先整理的设定；等开局收束后，再继续正文或续写。',
      primaryActions: fallbackGuide.primaryActions,
    ).copyWith(
      openingState: _openingStateViewDataService.build(
        projectType: projection.projectTypeId,
        maturity: maturity,
        primaryActions: fallbackGuide.primaryActions,
        projection: projection,
        preferredNextAction: fallbackGuide.primaryActions.isEmpty
            ? null
            : fallbackGuide.primaryActions.first,
        firstPromptOverride: '先说这部作品想写什么、主角和冲突大概是什么，或者你想先整理哪部分设定。',
        nextStepLabelOverride: fallbackGuide.primaryActions.isEmpty
            ? ''
            : fallbackGuide.primaryActions.first.title,
        preferSingleAction: true,
      ),
    );
  }

  ConversationGuideViewData decorateGroundedGuide({
    required ConversationGuideViewData fallbackGuide,
    required OpeningSessionProjection projection,
    required ProjectOpeningMaturityAssessment maturity,
    required bool isGenerating,
  }) {
    final summaryLines = <String>[
      maturity.summary,
      if (projection.currentGroupDisplayName.trim().isNotEmpty)
        '当前智能体组：${projection.currentGroupDisplayName}',
      if (projection.derivedFromAgentBinding) '当前智能体组来自旧项目智能体绑定自动派生。',
    ];
    if (projection.projectTypeId == 'long_novel' &&
        projection.orchestration.readiness.canStartLongTask) {
      summaryLines.add('如需重新生成或继续推进任务链，也可以直接在会话里说明。');
    }
    return ConversationGuideViewData(
      workflowTitle: fallbackGuide.workflowTitle,
      workflowDescription:
          '${fallbackGuide.workflowDescription}\n\n${summaryLines.join('\n')}',
      composerHint: isGenerating
          ? fallbackGuide.composerHint
          : '直接描述当前要继续推进的章节、场景或设定即可。',
      primaryActions: fallbackGuide.primaryActions,
    ).copyWith(
      openingState: _openingStateViewDataService.build(
        projectType: projection.projectTypeId,
        maturity: maturity,
        primaryActions: fallbackGuide.primaryActions,
        projection: projection,
        preferredNextAction: fallbackGuide.primaryActions.isEmpty
            ? null
            : fallbackGuide.primaryActions.first,
        firstPromptOverride: '直接描述当前要继续推进的章节、场景或设定即可。',
        nextStepLabelOverride: fallbackGuide.primaryActions.isEmpty
            ? ''
            : fallbackGuide.primaryActions.first.title,
        preferSingleAction: true,
      ),
    );
  }

  ConversationGuideViewData buildGroupResolutionGuide(
    OpeningSessionProjection projection, {
    required bool isGenerating,
  }) {
    // 中文注释: 当 opening 卡在智能体组阶段时，先明确告诉用户当前组可用性，而不是继续显示误导性的普通入口。
    final supportedGroups = projection.supportedGroups;
    final unsupportedGroups = projection.unsupportedGroups;
    final supportedText = supportedGroups.isEmpty
        ? '当前没有可直接使用的智能体组。'
        : '可用组：${supportedGroups.map((group) => group.displayName).join('、')}';
    final unsupportedText = unsupportedGroups.isEmpty
        ? ''
        : '暂不可用：${unsupportedGroups.map((group) => group.displayName).join('、')}';
    final descriptionLines = <String>[
      supportedText,
      if (unsupportedText.trim().isNotEmpty) unsupportedText,
      '先确认一个适用于当前项目的智能体组，再进入正式会话。',
    ];
    final actions = projection.orchestration.suggestedActions
        .map(_toPrimaryAction)
        .toList(growable: false);
    return ConversationGuideViewData(
      workflowTitle: '确认开局智能体组',
      workflowDescription: descriptionLines.join('\n'),
      composerHint: isGenerating
          ? '运行中：你仍然可以补充本项目希望由哪类智能体负责开局。'
          : '暂时先不要急着开跑；先确认项目适用的智能体组，或直接描述你期望的协作风格。',
      primaryActions: actions,
    ).copyWith(
      openingState: _openingStateViewDataService.build(
        projectType: projection.projectTypeId,
        maturity: const ProjectOpeningMaturityAssessment(
          stage: ProjectOpeningMaturityStage.openingInProgress,
          summary: '',
          authoredFoundationFileCount: 0,
          narrativeFileCount: 0,
        ),
        primaryActions: actions,
        projection: projection,
        preferredNextAction: null,
        firstPromptOverride: '先确认一个适用于当前项目的智能体组。',
        nextStepLabelOverride: '确认项目智能体组',
        preferSingleAction: false,
      ),
    );
  }

  ConversationGuideViewData attachOpeningState({
    required ConversationGuideViewData guide,
    required String projectType,
    required ProjectOpeningMaturityAssessment maturity,
    OpeningSessionProjection? projection,
    bool preferSingleAction = false,
  }) {
    return guide.copyWith(
      openingState: _openingStateViewDataService.build(
        projectType: projectType,
        maturity: maturity,
        primaryActions: guide.primaryActions,
        projection: projection,
        preferredNextAction: guide.primaryActions.isEmpty
            ? null
            : guide.primaryActions.first,
        preferSingleAction: preferSingleAction,
      ),
    );
  }

  PrimaryActionViewData _toPrimaryAction(OpeningSuggestedAction action) {
    return PrimaryActionViewData(
      id: action.id,
      title: action.title,
      description: action.description,
      commandId: action.commandId,
      payload: action.payload,
    );
  }
}
