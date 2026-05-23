import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'review_type_catalog_service.dart';

class ReviewPromptVariableService {
  ReviewPromptVariableService({ReviewTypeCatalogService? typeCatalogService})
    : _typeCatalogService = typeCatalogService ?? ReviewTypeCatalogService();

  final ReviewTypeCatalogService _typeCatalogService;

  JsonMap promptVariables(
    String reviewType,
    String scope, {
    List<Object?> sourcePaths = const <Object?>[],
  }) {
    // 中文注释: 审稿模板变量统一在这里生成，避免任务层和提示层重复拼同样的字段。
    final normalizedType = _typeCatalogService.normalizeReviewType(reviewType);
    final cleanPaths = ValueReaders.stringList(sourcePaths);
    return <String, Object?>{
      'review_goal': _typeCatalogService.reviewGoal(normalizedType),
      'scope': scope,
      'source_paths': cleanPaths.isEmpty ? '无' : cleanPaths.join('、'),
      'review_type': normalizedType,
    };
  }
}
