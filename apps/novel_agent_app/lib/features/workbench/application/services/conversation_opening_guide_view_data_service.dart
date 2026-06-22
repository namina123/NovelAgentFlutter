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
        ? '还没有确定开局智能体组。'
        : '开局智能体组：${projection.currentGroupDisplayName}';
    final readinessText = readiness.canStartLongTask
        ? '可以直接开始了。'
        : orchestration.readiness.missingRequirements.isEmpty
        ? '还需要补充长任务开局信息。'
        : '还需：${orchestration.readiness.missingRequirements.map((item) => item.title).join('、')}';
    return ConversationGuideViewData(
      workflowTitle: '长任务开局',
      workflowDescription: '$currentGroupText\n$readinessText',
      composerHint: isGenerating
          ? '生成中：可以继续补充长篇边界、节奏、角色和检查点约束。'
          : readiness.canStartLongTask
          ? '描述你想写什么，或直接启动长任务。'
          : '描述你想写的故事，或启动长任务让智能体引导。',
      primaryActions: <PrimaryActionViewData>[startAction],
    ).copyWith(
      openingState: _openingStateViewDataService.build(
        projectType: projection.projectTypeId,
        maturity: maturity,
        primaryActions: <PrimaryActionViewData>[startAction],
        projection: projection,
        preferredNextAction: startAction,
        firstPromptOverride: readiness.canStartLongTask
            ? '让智能体接管当前开局。'
            : '让智能体判断还缺什么并引导你补齐。',
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
    if (projection.projectTypeId == 'book_deconstruction') {
      return decorateBookDeconstructionGuide(
        fallbackGuide: fallbackGuide,
        projection: projection,
        maturity: maturity,
        isGenerating: isGenerating,
      );
    }
    // 中文注释: 普通协作项目先复用现有轻会话入口，只把当前智能体组与 opening 状态补进描述层。
    final orchestration = projection.orchestration;
    final missingTitles = orchestration.readiness.missingRequirements
        .where((item) => item.id.trim() != 'conversation_goal')
        .map((item) => item.title)
        .join('、');
    final summaryLines = <String>[
      if (projection.currentGroupDisplayName.trim().isNotEmpty)
        '开局智能体组：${projection.currentGroupDisplayName}',
      if (projection.currentGroupDisplayName.trim().isEmpty &&
          projection.groupSummaries.isEmpty)
        '还没有确定智能体组。',
      if (missingTitles.trim().isNotEmpty) '还需：$missingTitles',
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
          : '描述你想写什么，智能体会引导你补齐开局。',
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
        firstPromptOverride: '说说你想写什么。',
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
    if (projection.projectTypeId == 'book_deconstruction') {
      return decorateBookDeconstructionGuide(
        fallbackGuide: fallbackGuide,
        projection: projection,
        maturity: maturity,
        isGenerating: isGenerating,
      );
    }
    final summaryLines = <String>[
      maturity.summary,
      if (projection.currentGroupDisplayName.trim().isNotEmpty)
        '开局智能体组：${projection.currentGroupDisplayName}',
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

  ConversationGuideViewData decorateBookDeconstructionGuide({
    required ConversationGuideViewData fallbackGuide,
    required OpeningSessionProjection projection,
    required ProjectOpeningMaturityAssessment maturity,
    required bool isGenerating,
  }) {
    final summaryLines = <String>[
      if (maturity.summary.trim().isNotEmpty) maturity.summary,
      '拆书导向：导入书籍 -> 分析数据 -> 开始创作',
      if (projection.currentGroupDisplayName.trim().isNotEmpty)
        '开局智能体组：${projection.currentGroupDisplayName}',
      if (maturity.isContinueReady || maturity.narrativeFileCount > 0)
        '当前项目已经具备继续分析或承接创作的基础。'
      else
        '导入后应优先进入正式分析入口，补齐结构化拆书资产，再进入正式创作。',
    ];
    final guide = ConversationGuideViewData(
      workflowTitle: fallbackGuide.workflowTitle,
      workflowDescription:
          '${fallbackGuide.workflowDescription}\n\n${summaryLines.join('\n')}',
      composerHint: isGenerating
          ? '整理中：可以继续补充角色、背景、风格、剧情线、道具或后续路线要求。'
          : '先导入书籍，或进入分析数据、开始创作。',
      primaryActions: fallbackGuide.primaryActions,
    );
    return guide.copyWith(
      openingState: _openingStateViewDataService.build(
        projectType: projection.projectTypeId,
        maturity: maturity,
        primaryActions: fallbackGuide.primaryActions,
        projection: projection,
        preferredNextAction: null,
        firstPromptOverride: '先确认这次是继续导入书籍、进入正式分析入口，还是开始承接创作。',
        nextStepLabelOverride: '导入书籍 / 分析数据 / 开始创作',
        preferSingleAction: false,
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
