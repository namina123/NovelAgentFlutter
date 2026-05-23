import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_mode_service.dart';
import 'long_task_mode_strategy_service.dart';
import 'long_task_transaction_context_service.dart';
import 'long_task_transaction_contract_service.dart';

class LongTaskTaskTransactionService {
  LongTaskTaskTransactionService({
    required LongTaskModeService modeService,
    required LongTaskModeStrategyService strategyService,
    required LongTaskTransactionContextService contextService,
    required LongTaskTransactionContractService contractService,
  }) : _modeService = modeService,
       _strategyService = strategyService,
       _contextService = contextService,
       _contractService = contractService;

  final LongTaskModeService _modeService;
  final LongTaskModeStrategyService _strategyService;
  final LongTaskTransactionContextService _contextService;
  final LongTaskTransactionContractService _contractService;

  JsonMap buildTaskTransaction(
    JsonMap task, {
    JsonMap runRecord = const <String, Object?>{},
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 模型单步事务包把任务、模式策略和项目模板揉成纯数据合同，供 GUI/CLI 共用。
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(
        task['mode'],
        ValueReaders.stringValue(runRecord['mode']),
      ),
    );
    final metadata = ValueReaders.mapValue(task['metadata']);
    return <String, Object?>{
      'ok': true,
      'transaction_type': 'long_task_model_step',
      'phase': 'model_step',
      'mode': mode,
      'strategy': _strategyService.modeStrategy(mode),
      'agent_role': _contextService.roleForTask(task, runMode: mode),
      'task_type': taskType,
      'task_id': ValueReaders.stringValue(task['id']),
      'task_title': ValueReaders.stringValue(task['title'], '未命名任务'),
      'chapter': ValueReaders.stringValue(task['chapter']),
      'goal': ValueReaders.stringValue(task['goal']),
      'brief': ValueReaders.stringValue(task['brief']),
      'source_paths': ValueReaders.stringList(task['source_paths']),
      'output_paths': ValueReaders.stringList(task['output_paths']),
      'proposed_output_paths': ValueReaders.mapValue(
        task['proposed_output_paths'],
      ),
      'tool_hint': ValueReaders.stringValue(task['tool_hint']),
      'metadata': metadata,
      'context_needs': _contextService.commonContextNeeds(task),
      'tool_contracts': _contractService.toolContractsForTask(task),
      'instructions': _contractService.primaryInstructionsForTask(task),
      'postprocess_plan': _contractService.postprocessPlanForTask(task),
      'project_templates': ValueReaders.mapValue(options['project_templates']),
      'review_type': ValueReaders.stringValue(
        metadata['review_type'],
        'general',
      ),
      'single_step_boundary': _contractService.singleStepBoundary(
        task,
        runMode: mode,
      ),
      'allows_stream_guidance': ValueReaders.boolValue(
        options['allow_stream_guidance'],
        true,
      ),
      'run_id': ValueReaders.stringValue(runRecord['id']),
    };
  }
}
