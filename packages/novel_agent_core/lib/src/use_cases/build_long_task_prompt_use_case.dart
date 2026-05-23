import '../common/json_types.dart';
import '../workflow/long_task_task_prompt_renderer.dart';
import '../workflow/long_task_task_transaction_service.dart';

class BuildLongTaskPromptUseCase {
  BuildLongTaskPromptUseCase({
    required LongTaskTaskTransactionService transactionService,
    required LongTaskTaskPromptRenderer promptRenderer,
  }) : _transactionService = transactionService,
       _promptRenderer = promptRenderer;

  final LongTaskTaskTransactionService _transactionService;
  final LongTaskTaskPromptRenderer _promptRenderer;

  String execute(
    JsonMap task, {
    JsonMap runRecord = const <String, Object?>{},
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 这个用例把长任务事务构建和提示渲染串起来，宿主不再自己拼提示。
    final transaction = _transactionService.buildTaskTransaction(
      task,
      runRecord: runRecord,
      options: options,
    );
    return _promptRenderer.renderTaskPrompt(transaction);
  }
}
