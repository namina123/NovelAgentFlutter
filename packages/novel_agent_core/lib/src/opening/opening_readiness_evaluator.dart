import '../common/value_readers.dart';
import '../modes/mode_guidance_transition_service.dart';
import 'opening_missing_requirement.dart';
import 'opening_readiness_assessment.dart';
import 'opening_session_state.dart';

class OpeningReadinessEvaluator {
  OpeningReadinessEvaluator({
    ModeGuidanceTransitionService? modeGuidanceTransitionService,
  }) : _modeGuidanceTransitionService =
           modeGuidanceTransitionService ?? ModeGuidanceTransitionService();

  final ModeGuidanceTransitionService _modeGuidanceTransitionService;

  OpeningReadinessAssessment evaluate(OpeningSessionState state) {
    // 中文注释: readiness 只看当前 opening 事实是否足够推进，不负责生成具体 UI 文案或执行动作。
    switch (state.projectTypeId.trim()) {
      case 'long_novel':
        return _evaluateLongTask(state);
      case 'novel':
      default:
        return _evaluateInteractive(state);
    }
  }

  OpeningReadinessAssessment _evaluateLongTask(OpeningSessionState state) {
    final missing = <OpeningMissingRequirement>[];
    final effectiveModeId = _effectiveModeId(state);
    final effectiveRuntimeBaselineId = state.intent.runtimeBaselineId.trim();
    final hasGroup = state.intent.hasResolvedAgentGroup;
    if (!hasGroup) {
      missing.add(
        OpeningMissingRequirement(
          id: 'agent_group',
          title: '缺少智能体组',
          description: state.intent.availableAgentGroupIds.isEmpty
              ? '当前项目还没有可直接使用的开局智能体组。'
              : '需要先确认当前项目使用哪一个智能体组进入开局。',
          metadata: <String, Object?>{
            'available_group_ids': state.intent.availableAgentGroupIds,
          },
        ),
      );
    }
    if (effectiveRuntimeBaselineId.isEmpty) {
      missing.add(
        const OpeningMissingRequirement(
          id: 'runtime_baseline',
          title: '缺少运行基准',
          description: '长任务项目必须先确认运行基准，才能决定后续运行方式。',
        ),
      );
    }
    if (effectiveModeId.isEmpty) {
      missing.add(
        const OpeningMissingRequirement(
          id: 'mode_selection',
          title: '缺少长任务模式',
          description: '需要先选择长任务模式，才能确定该如何收束开局信息。',
        ),
      );
    }
    if (effectiveModeId.isNotEmpty) {
      if (state.modeGuidanceState == null) {
        missing.add(
          OpeningMissingRequirement(
            id: 'mode_guidance',
            title: '缺少模式引导状态',
            description: '当前模式还没有进入正式的引导收束过程。',
            metadata: <String, Object?>{'mode_id': effectiveModeId},
          ),
        );
      } else if (!state.modeGuidanceState!.isReady) {
        final question = _modeGuidanceTransitionService.buildQuestion(
          state.modeGuidanceState!,
        );
        missing.add(
          OpeningMissingRequirement(
            id: 'mode_guidance.${question.stageId}',
            title: question.title,
            description: question.description,
            metadata: <String, Object?>{
              'mode_id': state.modeGuidanceState!.modeId,
              'stage_id': question.stageId,
              'field_key': question.fieldKey,
            },
          ),
        );
      }
    }
    return OpeningReadinessAssessment(
      canStartLongTask: missing.isEmpty,
      canStartInteractiveSession: false,
      missingRequirements: List<OpeningMissingRequirement>.unmodifiable(
        missing,
      ),
      effectiveModeId: effectiveModeId,
      effectiveRuntimeBaselineId: effectiveRuntimeBaselineId,
    );
  }

  OpeningReadinessAssessment _evaluateInteractive(OpeningSessionState state) {
    final missing = <OpeningMissingRequirement>[];
    if (!state.intent.hasResolvedAgentGroup) {
      missing.add(
        OpeningMissingRequirement(
          id: 'agent_group',
          title: '缺少智能体组',
          description: state.intent.availableAgentGroupIds.isEmpty
              ? '当前项目还没有可直接使用的智能体组。'
              : '需要先确认当前项目使用哪一个智能体组进入会话。',
          metadata: <String, Object?>{
            'available_group_ids': state.intent.availableAgentGroupIds,
          },
        ),
      );
    }
    if (!state.intent.hasConversationGoal && !state.intent.hasFreeTextIntent) {
      missing.add(
        const OpeningMissingRequirement(
          id: 'conversation_goal',
          title: '缺少会话目标',
          description: '请选择一个当前会话目标，或者直接补充一句自由输入说明要做什么。',
        ),
      );
    }
    return OpeningReadinessAssessment(
      canStartLongTask: false,
      canStartInteractiveSession: missing.isEmpty,
      missingRequirements: List<OpeningMissingRequirement>.unmodifiable(
        missing,
      ),
      effectiveModeId: '',
      effectiveRuntimeBaselineId: '',
    );
  }

  String _effectiveModeId(OpeningSessionState state) {
    final intentModeId = state.intent.modeId.trim();
    if (intentModeId.isNotEmpty) {
      return intentModeId;
    }
    return ValueReaders.stringValue(state.modeGuidanceState?.modeId).trim();
  }
}
