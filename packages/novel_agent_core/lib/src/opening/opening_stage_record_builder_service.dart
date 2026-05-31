import '../strategy/strategy_catalog_service.dart';
import 'opening_readiness_assessment.dart';
import 'opening_session_state.dart';
import 'opening_stage_record.dart';

class OpeningStageRecordBuilderService {
  OpeningStageRecordBuilderService({
    StrategyCatalogService? strategyCatalogService,
  }) : _strategyCatalogService =
           strategyCatalogService ?? const StrategyCatalogService();

  final StrategyCatalogService _strategyCatalogService;

  List<OpeningStageRecord> build(
    OpeningSessionState state, {
    required OpeningReadinessAssessment readiness,
  }) {
    // 中文注释: stage record 只把 opening 过程投影成稳定步骤列表，不参与 readiness 判定本身。
    switch (state.projectTypeId.trim()) {
      case 'long_novel':
        return _buildLongTaskRecords(state, readiness: readiness);
      case 'novel':
      default:
        return _buildInteractiveRecords(state, readiness: readiness);
    }
  }

  List<OpeningStageRecord> _buildLongTaskRecords(
    OpeningSessionState state, {
    required OpeningReadinessAssessment readiness,
  }) {
    final records = <OpeningStageRecord>[
      OpeningStageRecord(
        id: 'agent_group_selection',
        title: '智能体组',
        description: '确认当前项目要用哪一个可用智能体组进入开局。',
        status: state.intent.hasResolvedAgentGroup
            ? OpeningStageRecord.statusCompleted
            : OpeningStageRecord.statusCurrent,
      ),
      OpeningStageRecord(
        id: 'runtime_baseline',
        title: '运行基准',
        description: '确认长任务使用哪种运行基准。',
        status: state.intent.runtimeBaselineId.trim().isNotEmpty
            ? OpeningStageRecord.statusCompleted
            : _pendingOrCurrent(state.intent.hasResolvedAgentGroup),
      ),
      OpeningStageRecord(
        id: 'mode_selection',
        title: '长任务模式',
        description: '确认当前长任务项目以哪种模式收束开局信息。',
        status: readiness.effectiveModeId.trim().isNotEmpty
            ? OpeningStageRecord.statusCompleted
            : _pendingOrCurrent(
                state.intent.runtimeBaselineId.trim().isNotEmpty,
              ),
      ),
    ];
    final modeId = readiness.effectiveModeId.trim();
    if (modeId.isNotEmpty) {
      final definition = _strategyCatalogService.modeDefinitionById(modeId);
      final completedIds =
          state.modeGuidanceState?.completedStageIds ?? const <String>[];
      final currentStageId = state.modeGuidanceState?.currentStageId ?? '';
      final modeReady = state.modeGuidanceState?.isReady ?? false;
      for (final stage in definition.stages) {
        final isCompleted = completedIds.contains(stage.id);
        final isCurrent = !modeReady && currentStageId == stage.id;
        records.add(
          OpeningStageRecord(
            id: 'mode_stage.${stage.id}',
            title: stage.title,
            description: stage.description,
            status: isCompleted
                ? OpeningStageRecord.statusCompleted
                : isCurrent
                ? OpeningStageRecord.statusCurrent
                : OpeningStageRecord.statusPending,
            metadata: <String, Object?>{
              'mode_id': modeId,
              'field_key': stage.fieldKey,
            },
          ),
        );
      }
    }
    records.add(
      OpeningStageRecord(
        id: 'launch_long_task',
        title: '启动长任务',
        description: '当前信息足够时，可以进入正式长任务运行链。',
        status: readiness.canStartLongTask
            ? OpeningStageRecord.statusReady
            : OpeningStageRecord.statusPending,
      ),
    );
    return List<OpeningStageRecord>.unmodifiable(records);
  }

  List<OpeningStageRecord> _buildInteractiveRecords(
    OpeningSessionState state, {
    required OpeningReadinessAssessment readiness,
  }) {
    return List<OpeningStageRecord>.unmodifiable(<OpeningStageRecord>[
      OpeningStageRecord(
        id: 'agent_group_selection',
        title: '智能体组',
        description: '确认当前项目要用哪一个智能体组进入对话。',
        status: state.intent.hasResolvedAgentGroup
            ? OpeningStageRecord.statusCompleted
            : OpeningStageRecord.statusCurrent,
      ),
      OpeningStageRecord(
        id: 'session_goal',
        title: '会话目标',
        description: '选择一个当前会话目标，或者直接通过自由输入说明要做什么。',
        status: state.intent.hasConversationGoal
            ? OpeningStageRecord.statusCompleted
            : state.intent.hasFreeTextIntent
            ? OpeningStageRecord.statusCompleted
            : _pendingOrCurrent(state.intent.hasResolvedAgentGroup),
      ),
      OpeningStageRecord(
        id: 'opening_context',
        title: '开局说明',
        description: '用一句目标或一段自由输入，告诉智能体你当前想推进什么。',
        status:
            state.intent.hasConversationGoal || state.intent.hasFreeTextIntent
            ? OpeningStageRecord.statusCompleted
            : OpeningStageRecord.statusPending,
      ),
      OpeningStageRecord(
        id: 'start_interactive_session',
        title: '开始协作',
        description: '当前信息足够时，可以进入普通创作会话。',
        status: readiness.canStartInteractiveSession
            ? OpeningStageRecord.statusReady
            : OpeningStageRecord.statusPending,
      ),
    ]);
  }

  String _pendingOrCurrent(bool previousCompleted) {
    return previousCompleted
        ? OpeningStageRecord.statusCurrent
        : OpeningStageRecord.statusPending;
  }
}
