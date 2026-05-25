import '../workflow/task_runtime_constants.dart';
import 'mode_guidance_plan_input.dart';
import 'mode_guidance_state.dart';
import 'mode_guidance_workspace_path_service.dart';
import 'mode_guidance_question.dart';
import 'mode_guidance_transition_service.dart';
import 'mode_guidance_projection_document_service.dart';

class ModeGuidancePlanInputBuilderService {
  ModeGuidancePlanInputBuilderService({
    ModeGuidanceTransitionService? transitionService,
    ModeGuidanceWorkspacePathService? workspacePathService,
    ModeGuidanceProjectionDocumentService? projectionDocumentService,
  }) : _transitionService =
           transitionService ?? ModeGuidanceTransitionService(),
       _workspacePathService =
           workspacePathService ?? const ModeGuidanceWorkspacePathService(),
       _projectionDocumentService =
           projectionDocumentService ??
           const ModeGuidanceProjectionDocumentService();

  final ModeGuidanceTransitionService _transitionService;
  final ModeGuidanceWorkspacePathService _workspacePathService;
  final ModeGuidanceProjectionDocumentService _projectionDocumentService;

  ModeGuidancePlanInput build(ModeGuidanceState state) {
    // 中文注释: 该服务把模式引导状态转成共享长任务计划输入，避免 GUI/CLI 各自手写模式到计划参数的映射。
    final question = _transitionService.buildQuestion(state);
    switch (state.modeId) {
      case 'seed_autopilot_novel':
        return _buildSeedAutopilot(state, question);
      case 'full_outline_consensus':
        return _buildFullOutlineConsensus(state, question);
      default:
        return ModeGuidancePlanInput(
          modeId: state.modeId,
          runtimeMode: TaskRuntimeConstants.modeHumanOutlineAiDraft,
          isReady: state.isReady,
          options: const <String, Object?>{},
          missingFields: question.isReadyToLaunch
              ? const <String>[]
              : <String>[question.stageId],
        );
    }
  }

  ModeGuidancePlanInput _buildSeedAutopilot(
    ModeGuidanceState state,
    ModeGuidanceQuestion question,
  ) {
    final values = _answerValues(state);
    final projected = _projectionDocumentService.buildDocuments(state);
    final seedPrompt = [
      '【模式】灵感托管式长篇',
      if (_value(values, 'seed_scope').isNotEmpty)
        '【当前材料】${_value(values, 'seed_scope')}',
      if (_value(values, 'core_promise').isNotEmpty)
        '【核心承诺】${_value(values, 'core_promise')}',
      if (_value(values, 'world_anchor').isNotEmpty)
        '【世界锚点】${_value(values, 'world_anchor')}',
      if (_value(values, 'protagonist_drive').isNotEmpty)
        '【主角驱动力】${_value(values, 'protagonist_drive')}',
      if (_value(values, 'style_target').isNotEmpty)
        '【风格目标】${_value(values, 'style_target')}',
      if (_value(values, 'autonomy_guardrails').isNotEmpty)
        '【托管边界】${_value(values, 'autonomy_guardrails')}',
    ].join('\n');
    return ModeGuidancePlanInput(
      modeId: state.modeId,
      runtimeMode: TaskRuntimeConstants.modeSeedToFullNovel,
      isReady: state.isReady,
      options: <String, Object?>{
        'seed_prompt': seedPrompt,
        'chapter_count': _chapterCountFromAutonomy(
          _value(values, 'autonomy_guardrails'),
        ),
        'checkpoint_interval': _checkpointFromAutonomy(
          _value(values, 'autonomy_guardrails'),
        ),
        'source_paths': <Object?>[
          _workspacePathService.summaryMarkdownPath(state.modeId),
          ...projected.keys,
          'specs/project_brief.md',
        ],
        'persistent_context_paths': <Object?>[
          _workspacePathService.summaryMarkdownPath(state.modeId),
          ...projected.keys,
        ],
      },
      missingFields: question.isReadyToLaunch
          ? const <String>[]
          : <String>[question.stageId],
    );
  }

  ModeGuidancePlanInput _buildFullOutlineConsensus(
    ModeGuidanceState state,
    ModeGuidanceQuestion question,
  ) {
    final values = _answerValues(state);
    final projected = _projectionDocumentService.buildDocuments(state);
    final outlineSeed = [
      '【模式】全书共拟式长篇',
      if (_value(values, 'book_premise').isNotEmpty)
        '【故事总前提】${_value(values, 'book_premise')}',
      if (_value(values, 'main_arc').isNotEmpty)
        '【主线与冲突】${_value(values, 'main_arc')}',
      if (_value(values, 'volume_map').isNotEmpty)
        '【分卷结构】${_value(values, 'volume_map')}',
      if (_value(values, 'ending_commitment').isNotEmpty)
        '【结局承诺】${_value(values, 'ending_commitment')}',
      if (_value(values, 'style_and_boundaries').isNotEmpty)
        '【风格与边界】${_value(values, 'style_and_boundaries')}',
    ].join('\n');
    return ModeGuidancePlanInput(
      modeId: state.modeId,
      runtimeMode: TaskRuntimeConstants.modeHumanOutlineAiDraft,
      isReady: state.isReady,
      options: <String, Object?>{
        'outline_text': outlineSeed,
        'chapter_count': 12,
        'checkpoint_interval': 1,
        'source_paths': <Object?>[
          _workspacePathService.summaryMarkdownPath(state.modeId),
          ...projected.keys,
          'specs/project_brief.md',
        ],
        'persistent_context_paths': <Object?>[
          _workspacePathService.summaryMarkdownPath(state.modeId),
          ...projected.keys,
        ],
      },
      missingFields: question.isReadyToLaunch
          ? const <String>[]
          : <String>[question.stageId],
    );
  }

  Map<String, String> _answerValues(ModeGuidanceState state) {
    final values = <String, String>{};
    for (final answer in state.answers) {
      values[answer.fieldKey] = answer.value.trim();
    }
    return values;
  }

  String _value(Map<String, String> values, String key) {
    return values[key] ?? '';
  }

  int _chapterCountFromAutonomy(String autonomyText) {
    if (autonomyText.contains('总纲') || autonomyText.contains('关键章纲')) {
      return 12;
    }
    if (autonomyText.contains('跨卷')) {
      return 16;
    }
    return 10;
  }

  int _checkpointFromAutonomy(String autonomyText) {
    if (autonomyText.contains('跨卷')) {
      return 4;
    }
    if (autonomyText.contains('总纲') || autonomyText.contains('关键章纲')) {
      return 2;
    }
    return 3;
  }
}
