import '../deconstruction/book_deconstruction_application_plan.dart';
import '../deconstruction/book_deconstruction_application_plan_builder_service.dart';
import '../deconstruction/book_deconstruction_extraction_result.dart';
import '../deconstruction/book_deconstruction_input.dart';
import '../project/project_storage_strategy.dart';

class BuildBookDeconstructionApplicationPlanUseCase {
  BuildBookDeconstructionApplicationPlanUseCase({
    BookDeconstructionApplicationPlanBuilderService? builderService,
  }) : _builderService =
           builderService ??
           const BookDeconstructionApplicationPlanBuilderService();

  final BookDeconstructionApplicationPlanBuilderService _builderService;

  BookDeconstructionApplicationPlan execute({
    required BookDeconstructionInput input,
    required BookDeconstructionExtractionResult extractionResult,
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 这里给 GUI/CLI 一个正式入口，用统一用例把拆书提取结果收束成可应用计划。
    return _builderService.build(
      input: input,
      extractionResult: extractionResult,
      storageStrategy: storageStrategy,
    );
  }
}
