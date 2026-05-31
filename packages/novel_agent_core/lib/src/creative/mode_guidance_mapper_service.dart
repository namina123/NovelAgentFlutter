import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../modes/mode_guidance_state.dart';
import '../strategy/strategy_catalog_service.dart';
import 'mode_guidance.dart';

class ModeGuidanceMapperService {
  ModeGuidanceMapperService({
    StrategyCatalogService? strategyCatalogService,
  }) : _strategyCatalogService =
           strategyCatalogService ?? const StrategyCatalogService();

  final StrategyCatalogService _strategyCatalogService;

  ModeGuidance fromState(
    ModeGuidanceState state, {
    String sourcePath = '',
  }) {
    // 中文注释: 模式引导状态是运行态快照，这里负责把它压成给上下文和审稿共用的稳定指导对象。
    final definition = _strategyCatalogService.modeDefinitionById(state.modeId);
    final confirmedFacts = <String>[];
    final boundaries = <String>[];
    for (final answer in state.answers) {
      final text = answer.value.trim().isEmpty ? answer.label.trim() : answer.value.trim();
      if (text.isEmpty) {
        continue;
      }
      if (!confirmedFacts.contains(text)) {
        confirmedFacts.add(text);
      }
      final lowerKey = answer.fieldKey.toLowerCase();
      if ((lowerKey.contains('boundary') ||
              lowerKey.contains('guardrail') ||
              lowerKey.contains('style')) &&
          !boundaries.contains(text)) {
        boundaries.add(text);
      }
    }
    final summary = confirmedFacts.take(3).join('；');
    return ModeGuidance(
      modeId: state.modeId,
      title: definition.title,
      summary: summary.isEmpty ? '${definition.title}已进入${state.status}。' : summary,
      currentStageTitle: _stageTitle(state.modeId, state.currentStageId),
      confirmedFacts: confirmedFacts,
      boundaries: boundaries,
      sourcePath: sourcePath,
      metadata: <String, Object?>{
        'project_strategy_id': state.projectStrategyId,
        'workflow_strategy_id': state.workflowStrategyId,
        'status': state.status,
        'completed_stage_ids': state.completedStageIds,
      },
    );
  }

  JsonMap toDocument(ModeGuidance guidance) {
    return <String, Object?>{
      'mode_id': guidance.modeId,
      'title': guidance.title,
      'summary': guidance.summary,
      'current_stage_title': guidance.currentStageTitle,
      'confirmed_facts': guidance.confirmedFacts,
      'boundaries': guidance.boundaries,
      'source_path': guidance.sourcePath,
      'metadata': ValueReaders.deepCopyMap(guidance.metadata),
    };
  }

  String _stageTitle(String modeId, String stageId) {
    final definition = _strategyCatalogService.modeDefinitionById(modeId);
    for (final stage in definition.stages) {
      if (stage.id == stageId) {
        return stage.title;
      }
    }
    return stageId;
  }
}
