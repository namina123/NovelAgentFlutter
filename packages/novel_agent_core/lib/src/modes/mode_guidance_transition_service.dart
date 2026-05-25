import '../strategy/mode_definition.dart';
import '../strategy/mode_stage_definition.dart';
import '../strategy/strategy_catalog_service.dart';
import 'mode_guidance_answer.dart';
import 'mode_guidance_question.dart';
import 'mode_guidance_state.dart';

class ModeGuidanceTransitionService {
  ModeGuidanceTransitionService({
    StrategyCatalogService? strategyCatalogService,
  }) : _strategyCatalogService =
           strategyCatalogService ?? const StrategyCatalogService();

  final StrategyCatalogService _strategyCatalogService;

  ModeGuidanceState initialize(String modeId) {
    // 中文注释: 模式引导初始化只建立稳定的第一阶段快照，不夹带任何宿主侧默认值。
    final definition = _strategyCatalogService.modeDefinitionById(modeId);
    final now = DateTime.now().toIso8601String();
    return ModeGuidanceState(
      modeId: definition.id,
      projectStrategyId: definition.projectStrategyId,
      workflowStrategyId: definition.workflowStrategyId,
      status: ModeGuidanceState.statusCollecting,
      currentStageId: definition.stages.isEmpty ? '' : definition.stages.first.id,
      answers: const <ModeGuidanceAnswer>[],
      completedStageIds: const <String>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  ModeGuidanceQuestion buildQuestion(ModeGuidanceState state) {
    // 中文注释: 当前问题完全由共享状态机决定，避免 UI 各自拼接不同的阶段文案。
    final definition = _strategyCatalogService.modeDefinitionById(state.modeId);
    if (state.isReady) {
      return ModeGuidanceQuestion(
        modeId: state.modeId,
        stageId: state.currentStageId,
        fieldKey: '',
        title: '准备启动长任务',
        description: '当前模式信息已经收束完成，可以进入长任务计划生成。',
        helperText: '此时应该转到正式的长任务队列生成入口，而不是继续收集无关信息。',
        allowFreeText: false,
        progressText: '${definition.stages.length}/${definition.stages.length}',
        isReadyToLaunch: true,
      );
    }
    final currentStage = _currentStage(definition, state);
    if (currentStage == null) {
      return ModeGuidanceQuestion(
        modeId: state.modeId,
        stageId: state.currentStageId,
        fieldKey: '',
        title: '准备启动长任务',
        description: '当前模式信息已经收束完成，可以进入长任务计划生成。',
        helperText: '此时应该转到正式的长任务队列生成入口，而不是继续收集无关信息。',
        allowFreeText: false,
        progressText: '${definition.stages.length}/${definition.stages.length}',
        isReadyToLaunch: true,
      );
    }
    return ModeGuidanceQuestion(
      modeId: state.modeId,
      stageId: currentStage.id,
      fieldKey: currentStage.fieldKey,
      title: currentStage.title,
      description: currentStage.description,
      helperText: currentStage.helperText,
      allowFreeText: currentStage.allowFreeText,
      options: currentStage.options,
      progressText: '${state.completedStageIds.length}/${definition.stages.length}',
      isReadyToLaunch: false,
    );
  }

  ModeGuidanceState answer(
    ModeGuidanceState state, {
    required String stageId,
    required String fieldKey,
    required String value,
    String label = '',
    String source = 'free_text',
  }) {
    // 中文注释: 阶段应答采用覆盖式 upsert，同一字段后答覆盖先答，保证恢复与重试语义稳定。
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) {
      return state;
    }
    final now = DateTime.now().toIso8601String();
    final answers = state.answers
        .where(
          (item) => !(item.stageId == stageId && item.fieldKey == fieldKey),
        )
        .toList(growable: true)
      ..add(
        ModeGuidanceAnswer(
          stageId: stageId,
          fieldKey: fieldKey,
          value: cleanValue,
          label: label.trim(),
          source: source.trim().isEmpty ? 'free_text' : source.trim(),
          updatedAt: now,
        ),
      );
    final definition = _strategyCatalogService.modeDefinitionById(state.modeId);
    final completedStageIds = <String>[];
    for (final stage in definition.stages) {
      if (_hasAnswer(answers, stage)) {
        completedStageIds.add(stage.id);
      }
    }
    final nextStage = _nextIncompleteStage(definition, completedStageIds);
    return state.copyWith(
      answers: answers,
      completedStageIds: completedStageIds,
      currentStageId: nextStage?.id ?? state.currentStageId,
      status: nextStage == null
          ? ModeGuidanceState.statusReady
          : ModeGuidanceState.statusCollecting,
      updatedAt: now,
    );
  }

  bool hasAnyAnswer(ModeGuidanceState state) {
    return state.answers.isNotEmpty;
  }

  ModeStageDefinition? _currentStage(
    ModeDefinition definition,
    ModeGuidanceState state,
  ) {
    final nextIncomplete = _nextIncompleteStage(
      definition,
      state.completedStageIds,
    );
    if (nextIncomplete != null) {
      return nextIncomplete;
    }
    for (final stage in definition.stages) {
      if (stage.id == state.currentStageId) {
        return stage;
      }
    }
    return null;
  }

  ModeStageDefinition? _nextIncompleteStage(
    ModeDefinition definition,
    List<String> completedStageIds,
  ) {
    for (final stage in definition.stages) {
      if (!completedStageIds.contains(stage.id)) {
        return stage;
      }
    }
    return null;
  }

  bool _hasAnswer(List<ModeGuidanceAnswer> answers, ModeStageDefinition stage) {
    for (final answer in answers) {
      if (answer.stageId == stage.id &&
          answer.fieldKey == stage.fieldKey &&
          answer.value.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
