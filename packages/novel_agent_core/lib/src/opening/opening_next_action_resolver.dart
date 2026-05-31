import '../modes/mode_guidance_transition_service.dart';
import 'opening_readiness_assessment.dart';
import 'opening_session_state.dart';
import 'opening_suggested_action.dart';

class OpeningNextActionResolver {
  OpeningNextActionResolver({
    ModeGuidanceTransitionService? modeGuidanceTransitionService,
  }) : _modeGuidanceTransitionService =
           modeGuidanceTransitionService ?? ModeGuidanceTransitionService();

  final ModeGuidanceTransitionService _modeGuidanceTransitionService;

  List<OpeningSuggestedAction> resolve({
    required OpeningSessionState state,
    required OpeningReadinessAssessment readiness,
  }) {
    // 中文注释: 下一步动作只输出结构化建议，不直接决定页面摆放或工具栏呈现方式。
    switch (state.projectTypeId.trim()) {
      case 'long_novel':
        return _resolveLongTaskActions(state, readiness: readiness);
      case 'novel':
      default:
        return _resolveInteractiveActions(state, readiness: readiness);
    }
  }

  List<OpeningSuggestedAction> _resolveLongTaskActions(
    OpeningSessionState state, {
    required OpeningReadinessAssessment readiness,
  }) {
    if (!state.intent.hasResolvedAgentGroup) {
      return <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.choose_agent_group',
          commandId: 'opening.choose_agent_group',
          title: state.intent.availableAgentGroupIds.isEmpty
              ? '检查智能体组'
              : '确认智能体组',
          description: state.intent.availableAgentGroupIds.isEmpty
              ? '当前项目还没有可用智能体组，先检查 group 配置与适用范围。'
              : '先确认当前项目使用哪一个智能体组进入长任务开局。',
          payload: <String, Object?>{
            'available_group_ids': state.intent.availableAgentGroupIds,
          },
        ),
      ];
    }
    if (state.intent.runtimeBaselineId.trim().isEmpty) {
      return const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.choose_runtime_baseline',
          commandId: 'opening.choose_runtime_baseline',
          title: '确认运行基准',
          description: '先决定这个长任务项目用哪种运行基准推进。',
        ),
      ];
    }
    if (readiness.effectiveModeId.trim().isEmpty) {
      return const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.choose_long_task_mode',
          commandId: 'opening.choose_long_task_mode',
          title: '选择长任务模式',
          description: '先进入一种长任务模式，再收束需要的开局信息。',
        ),
      ];
    }
    if (state.modeGuidanceState == null) {
      return <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.open_mode_guidance',
          commandId: 'opening.open_mode_guidance',
          title: '开始模式引导',
          description: '当前模式还没有进入正式引导，先开始收束开局信息。',
          payload: <String, Object?>{'mode_id': readiness.effectiveModeId},
        ),
      ];
    }
    if (!state.modeGuidanceState!.isReady) {
      final question = _modeGuidanceTransitionService.buildQuestion(
        state.modeGuidanceState!,
      );
      return <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.continue_mode_guidance',
          commandId: 'opening.continue_mode_guidance',
          title: question.title,
          description: question.description,
          payload: <String, Object?>{
            'mode_id': state.modeGuidanceState!.modeId,
            'stage_id': question.stageId,
            'field_key': question.fieldKey,
            'allow_free_text': question.allowFreeText,
          },
        ),
      ];
    }
    if (readiness.canStartLongTask) {
      return <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.start_long_task_run',
          commandId: 'opening.start_long_task_run',
          title: '启动长任务',
          description: '当前开局信息已经收束完成，可以进入正式长任务运行链。',
          payload: <String, Object?>{
            'runtime_baseline_id': readiness.effectiveRuntimeBaselineId,
            'mode_id': readiness.effectiveModeId,
            'agent_group_id': state.intent.resolvedAgentGroupId,
          },
        ),
      ];
    }
    return const <OpeningSuggestedAction>[];
  }

  List<OpeningSuggestedAction> _resolveInteractiveActions(
    OpeningSessionState state, {
    required OpeningReadinessAssessment readiness,
  }) {
    if (!state.intent.hasResolvedAgentGroup) {
      return <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.choose_agent_group',
          commandId: 'opening.choose_agent_group',
          title: state.intent.availableAgentGroupIds.isEmpty
              ? '检查智能体组'
              : '确认智能体组',
          description: state.intent.availableAgentGroupIds.isEmpty
              ? '当前项目还没有可直接使用的智能体组。'
              : '先确认当前项目要用哪一个智能体组进入会话。',
          payload: <String, Object?>{
            'available_group_ids': state.intent.availableAgentGroupIds,
          },
        ),
      ];
    }
    if (!state.intent.hasConversationGoal && !state.intent.hasFreeTextIntent) {
      return const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.choose_session_goal',
          commandId: 'opening.choose_session_goal',
          title: '选择会话目标',
          description: '先从一个当前目标开局，或者直接用自由输入补一句说明。',
        ),
        OpeningSuggestedAction(
          id: 'opening.provide_free_text_intent',
          commandId: 'opening.provide_free_text_intent',
          title: '直接说明需求',
          description: '也可以直接输入一句你当前想让智能体做什么。',
        ),
      ];
    }
    if (readiness.canStartInteractiveSession) {
      return <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.start_interactive_session',
          commandId: 'opening.start_interactive_session',
          title: '开始会话',
          description: '当前信息足够，可以进入普通创作协作会话。',
          payload: <String, Object?>{
            'session_goal_mode_id': state.intent.sessionGoalModeId,
            'agent_group_id': state.intent.resolvedAgentGroupId,
          },
        ),
      ];
    }
    return const <OpeningSuggestedAction>[];
  }
}
