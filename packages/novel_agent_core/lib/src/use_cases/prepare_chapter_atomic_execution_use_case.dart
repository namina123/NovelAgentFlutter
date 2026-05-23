import '../common/json_types.dart';
import '../workflow/chapter_atomic_execution_builder_service.dart';

class PrepareChapterAtomicExecutionUseCase {
  PrepareChapterAtomicExecutionUseCase({
    required ChapterAtomicExecutionBuilderService executionBuilderService,
  }) : _executionBuilderService = executionBuilderService;

  final ChapterAtomicExecutionBuilderService _executionBuilderService;

  JsonMap execute(JsonMap input) {
    // 中文注释: 这个用例给 GUI 和 CLI 一个统一入口来生成章节原子执行包。
    return _executionBuilderService.prepareExecution(input);
  }
}
