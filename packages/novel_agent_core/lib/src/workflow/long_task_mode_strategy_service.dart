import '../common/json_types.dart';
import 'long_task_mode_service.dart';
import 'task_runtime_constants.dart';

class LongTaskModeStrategyService {
  LongTaskModeStrategyService({LongTaskModeService? modeService})
    : _modeService = modeService ?? LongTaskModeService();

  final LongTaskModeService _modeService;

  JsonMap modeStrategy(String mode) {
    // 中文注释: 模式策略描述给运行中心、提示事务和调度器共用，不承担真实执行逻辑。
    final cleanMode = _modeService.normalizeMode(mode);
    if (cleanMode == TaskRuntimeConstants.modeSingleChapterAtomic) {
      return _base(
        cleanMode,
        name: '单章原子任务',
        transactionModel: 'one_task_one_model_step',
        agentThinking: '聚焦单章目标、上下文和目标路径，完成后等待用户确认。',
        checkpointPolicy: 'after_task',
      );
    }
    if (cleanMode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      return _base(
        cleanMode,
        name: '监督式章节队列',
        transactionModel: 'chapter_queue_with_user_checkpoints',
        agentThinking: '每次只推进少量章节，优先稳定、可回滚和用户确认。',
        checkpointPolicy: 'frequent_manual',
      );
    }
    if (cleanMode == TaskRuntimeConstants.modeSeedToFullNovel) {
      return _base(
        cleanMode,
        name: '种子到长篇',
        transactionModel: 'plan_then_sample_then_series',
        agentThinking: '先规划规格和总纲，再样章验证，随后按章节队列推进。',
        checkpointPolicy: 'outline_sample_major_nodes',
      );
    }
    return _base(
      cleanMode,
      name: '人定大纲 AI 写作',
      transactionModel: 'outline_locked_chapter_drafting',
      agentThinking: '以用户确认大纲为约束，按章写作并在设定或剧情不确定时暂停。',
      checkpointPolicy: 'interval_manual',
    );
  }

  JsonMap _base(
    String mode, {
    required String name,
    required String transactionModel,
    required String agentThinking,
    required String checkpointPolicy,
  }) {
    // 中文注释: 模式策略的公共字段集中在这里，减少各模式分支里的重复样板。
    return <String, Object?>{
      'mode': mode,
      'supports_pause_resume': true,
      'uses_sub_agents': true,
      'guidance_scope': 'main_agent',
      'name': name,
      'transaction_model': transactionModel,
      'agent_thinking': agentThinking,
      'checkpoint_policy': checkpointPolicy,
    };
  }
}
