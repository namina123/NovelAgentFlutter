import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_guide_view_data.dart';
import '../../presentation/models/primary_action_view_data.dart';

class ConversationGuideViewDataService {
  ConversationGuideViewDataService({
    SessionGuideProfileService? sessionGuideProfileService,
    LongTaskWritingModeCatalogService? longTaskWritingModeCatalogService,
    ModeGuidanceTransitionService? modeGuidanceTransitionService,
  }) : _sessionGuideProfileService =
           sessionGuideProfileService ?? const SessionGuideProfileService(),
       _longTaskWritingModeCatalogService =
           longTaskWritingModeCatalogService ??
           const LongTaskWritingModeCatalogService(),
       _modeGuidanceTransitionService =
           modeGuidanceTransitionService ?? ModeGuidanceTransitionService();

  final SessionGuideProfileService _sessionGuideProfileService;
  final LongTaskWritingModeCatalogService _longTaskWritingModeCatalogService;
  final ModeGuidanceTransitionService _modeGuidanceTransitionService;

  ConversationGuideViewData build({
    required String projectType,
    required bool needsGoalSelection,
    required bool isGenerating,
    String guideScope = '',
    ModeGuidanceState? modeGuidanceState,
  }) {
    // 中文注释: 会话引导到界面模型的投影收口在这里，避免控制器直接理解 core profile 结构。
    if (projectType.trim() == 'long_novel' &&
        guideScope.trim() == 'long_task_modes') {
      return _longTaskModesGuide();
    }
    if (projectType.trim() == 'long_novel' &&
        guideScope.trim() == 'mode_guidance' &&
        modeGuidanceState != null) {
      return _modeGuidanceGuide(modeGuidanceState);
    }
    final profile = _sessionGuideProfileService.resolve(
      projectType: projectType,
      needsGoalSelection: needsGoalSelection,
      isRunning: isGenerating,
    );
    return ConversationGuideViewData(
      workflowTitle: profile.title,
      workflowDescription: profile.statusHint.trim().isEmpty
          ? profile.description
          : '${profile.description}\n\n${profile.statusHint}',
      composerHint: profile.composerHint,
      primaryActions: profile.primaryActions
          .map(
            (action) => PrimaryActionViewData(
              id: action.id,
              title: action.title,
              description: action.description,
              commandId: action.commandId,
              payload: action.payload,
            ),
          )
          .toList(growable: false),
    );
  }

  ConversationGuideViewData _longTaskModesGuide() {
    // 中文注释: 长任务模式细分页独立生成，避免把模式定义和普通入口按钮揉在一起。
    final actions = <PrimaryActionViewData>[
      const PrimaryActionViewData(
        id: 'guide.back.default',
        title: '返回长篇工作台',
        description: '回到长篇项目的默认入口列表。',
        commandId: 'guide.back.default',
      ),
      ..._longTaskWritingModeCatalogService.modes().map(
        (mode) {
          final modeId = ValueReaders.stringValue(mode['id']);
          final commandId =
              modeId == 'seed_autopilot_novel' ||
                  modeId == 'full_outline_consensus'
              ? 'guide.open_mode_guidance'
              : 'long_task.create_queue';
          return PrimaryActionViewData(
            id: 'long_task.mode.$modeId',
            title: ValueReaders.stringValue(mode['title']),
            description: [
              ValueReaders.stringValue(mode['description']),
              if (ValueReaders.stringValue(mode['best_for']).trim().isNotEmpty)
                '适合：${ValueReaders.stringValue(mode['best_for'])}',
              if (ValueReaders.stringValue(mode['human_involvement'])
                  .trim()
                  .isNotEmpty)
                '协作强度：${ValueReaders.stringValue(mode['human_involvement'])}',
            ].join('\n'),
            commandId: commandId,
            payload: <String, Object?>{'mode': modeId},
          );
        },
      ),
    ];
    return ConversationGuideViewData(
      workflowTitle: '选择长任务写作模式',
      workflowDescription:
          '先明确长篇协作模式，再让智能体生成可恢复任务链。这里的选择会影响前期讨论深度、检查点密度和后续自动推进方式。',
      composerHint: '也可以直接输入你希望采用的长篇协作方式、边界和检查点要求。',
      primaryActions: actions,
    );
  }

  ConversationGuideViewData _modeGuidanceGuide(ModeGuidanceState state) {
    final question = _modeGuidanceTransitionService.buildQuestion(state);
    final actions = <PrimaryActionViewData>[
      const PrimaryActionViewData(
        id: 'guide.back.default',
        title: '返回长篇工作台',
        description: '回到长篇项目的默认入口列表。',
        commandId: 'guide.back.default',
      ),
      ...question.options.map(
        (option) => PrimaryActionViewData(
          id: 'guide.answer.${state.modeId}.${question.stageId}.${option.id}',
          title: option.label,
          description: option.description.isEmpty
              ? option.value
              : '${option.value}\n\n${option.description}',
          commandId: 'guide.answer_mode_guidance',
          payload: <String, Object?>{
            'mode': state.modeId,
            'stage_id': question.stageId,
            'field_key': option.fieldKey,
            'value': option.value,
            'label': option.label,
            'source': 'option',
          },
        ),
      ),
      if (question.isReadyToLaunch)
        PrimaryActionViewData(
          id: 'guide.launch.${state.modeId}',
          title: '生成长任务队列',
          description: '当前阶段信息已经收束完成，开始生成可恢复长任务链。',
          commandId: 'guide.create_workflow_from_mode_guidance',
          payload: <String, Object?>{'mode': state.modeId},
        ),
    ];
    final composerHint = question.isReadyToLaunch
        ? '可以直接开始生成长任务队列，也可以先补充更多约束。'
        : question.allowFreeText
        ? '也可以直接输入这一阶段的补充内容，不一定非要点按钮。'
        : '这一阶段请先从下面的选项里选一个。';
    return ConversationGuideViewData(
      workflowTitle: question.title,
      workflowDescription:
          '${question.description}\n\n进度：${question.progressText}\n\n${question.helperText}',
      composerHint: composerHint,
      primaryActions: actions,
    );
  }
}
