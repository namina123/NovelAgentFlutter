import 'book_deconstruction_application_item.dart';
import 'book_deconstruction_application_plan.dart';
import 'book_deconstruction_asset_mapping_service.dart';
import 'book_deconstruction_extraction_result.dart';
import 'book_deconstruction_input.dart';
import '../project/project_storage_strategy.dart';

class BookDeconstructionApplicationPlanBuilderService {
  const BookDeconstructionApplicationPlanBuilderService({
    BookDeconstructionAssetMappingService? assetMappingService,
  }) : _assetMappingService =
           assetMappingService ?? const BookDeconstructionAssetMappingService();

  final BookDeconstructionAssetMappingService _assetMappingService;

  BookDeconstructionApplicationPlan build({
    required BookDeconstructionInput input,
    required BookDeconstructionExtractionResult extractionResult,
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 应用计划构建只收束元信息和条目列表，不处理真实写盘、副作用或覆盖冲突。
    final items = _assetMappingService.map(
      extractionResult,
      storageStrategy: storageStrategy,
    );
    return BookDeconstructionApplicationPlan(
      planId: 'plan_${extractionResult.extractionId}',
      extractionId: extractionResult.extractionId,
      targetProjectTypeId: input.targetProjectTypeId,
      targetProjectStrategyId: input.projectStrategyId,
      modeId: extractionResult.modeId,
      items: List<BookDeconstructionApplicationItem>.unmodifiable(items),
    );
  }
}
