import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'mode_guidance_answer.dart';

class ModeGuidanceState {
  const ModeGuidanceState({
    required this.modeId,
    required this.projectStrategyId,
    required this.workflowStrategyId,
    required this.status,
    required this.currentStageId,
    required this.answers,
    required this.completedStageIds,
    required this.createdAt,
    required this.updatedAt,
  });

  static const String statusCollecting = 'collecting';
  static const String statusReady = 'ready';

  final String modeId;
  final String projectStrategyId;
  final String workflowStrategyId;
  final String status;
  final String currentStageId;
  final List<ModeGuidanceAnswer> answers;
  final List<String> completedStageIds;
  final String createdAt;
  final String updatedAt;

  bool get isReady => status == statusReady;

  ModeGuidanceState copyWith({
    String? modeId,
    String? projectStrategyId,
    String? workflowStrategyId,
    String? status,
    String? currentStageId,
    List<ModeGuidanceAnswer>? answers,
    List<String>? completedStageIds,
    String? createdAt,
    String? updatedAt,
  }) {
    // 中文注释: 引导状态在 core 内始终以不可变快照流转，保证 GUI/CLI 与仓储恢复过程统一。
    return ModeGuidanceState(
      modeId: modeId ?? this.modeId,
      projectStrategyId: projectStrategyId ?? this.projectStrategyId,
      workflowStrategyId: workflowStrategyId ?? this.workflowStrategyId,
      status: status ?? this.status,
      currentStageId: currentStageId ?? this.currentStageId,
      answers: answers ?? this.answers,
      completedStageIds: completedStageIds ?? this.completedStageIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  JsonMap toJsonMap() {
    return <String, Object?>{
      'mode_id': modeId,
      'project_strategy_id': projectStrategyId,
      'workflow_strategy_id': workflowStrategyId,
      'status': status,
      'current_stage_id': currentStageId,
      'completed_stage_ids': completedStageIds,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'answers': answers
          .map((entry) => entry.toJsonMap())
          .toList(growable: false),
    };
  }

  static ModeGuidanceState fromJsonMap(JsonMap document) {
    return ModeGuidanceState(
      modeId: ValueReaders.stringValue(document['mode_id']),
      projectStrategyId: ValueReaders.stringValue(
        document['project_strategy_id'],
      ),
      workflowStrategyId: ValueReaders.stringValue(
        document['workflow_strategy_id'],
      ),
      status: ValueReaders.stringValue(document['status'], statusCollecting),
      currentStageId: ValueReaders.stringValue(document['current_stage_id']),
      completedStageIds: ValueReaders.stringList(
        document['completed_stage_ids'],
      ),
      createdAt: ValueReaders.stringValue(document['created_at']),
      updatedAt: ValueReaders.stringValue(document['updated_at']),
      answers: ValueReaders.mapList(
        document['answers'],
      ).map(ModeGuidanceAnswer.fromJsonMap).toList(growable: false),
    );
  }
}
