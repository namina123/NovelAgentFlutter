import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/expression_constraint_review_projection.dart';
import '../creative/expression_constraint_review_projection_service.dart';
import 'review_type_catalog_service.dart';

class ReviewPromptVariableService {
  ReviewPromptVariableService({
    ReviewTypeCatalogService? typeCatalogService,
    ExpressionConstraintReviewProjectionService?
    expressionConstraintReviewProjectionService,
  }) : _typeCatalogService = typeCatalogService ?? ReviewTypeCatalogService(),
       _expressionConstraintReviewProjectionService =
           expressionConstraintReviewProjectionService ??
           const ExpressionConstraintReviewProjectionService();

  final ReviewTypeCatalogService _typeCatalogService;
  final ExpressionConstraintReviewProjectionService
  _expressionConstraintReviewProjectionService;

  JsonMap promptVariables(
    String reviewType,
    String scope, {
    List<Object?> sourcePaths = const <Object?>[],
    List<Object?> expressionConstraintProfiles = const <Object?>[],
    JsonMap expressionConstraintReview = const <String, Object?>{},
  }) {
    // 中文注释: 审稿模板变量统一在这里生成，避免任务层和提示层重复拼同样的字段。
    final normalizedType = _typeCatalogService.normalizeReviewType(reviewType);
    final cleanPaths = ValueReaders.stringList(sourcePaths);
    final projection = _projection(
      expressionConstraintProfiles: expressionConstraintProfiles,
      expressionConstraintReview: expressionConstraintReview,
    );
    final result = <String, Object?>{
      'review_goal': _typeCatalogService.reviewGoal(normalizedType),
      'scope': scope,
      'source_paths': cleanPaths.isEmpty ? '无' : cleanPaths.join('、'),
      'review_type': normalizedType,
    };
    if (!projection.isEmpty) {
      result['authenticity_pass_level'] = projection.authenticityPassLevel;
      result['review_focuses'] = projection.reviewFocuses.join('；');
      result['mini_recheck'] = projection.miniRecheckItems.join('；');
      result['voice_protection'] = projection.voiceProtectionNotes.join('；');
    }
    return result;
  }

  ExpressionConstraintReviewProjection _projection({
    required List<Object?> expressionConstraintProfiles,
    required JsonMap expressionConstraintReview,
  }) {
    if (expressionConstraintReview.isNotEmpty) {
      return ExpressionConstraintReviewProjection.fromJson(
        expressionConstraintReview,
      );
    }
    if (expressionConstraintProfiles.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    return _expressionConstraintReviewProjectionService
        .buildFromCreativeRuleStack(<String, Object?>{
          'expression_constraints': expressionConstraintProfiles,
        });
  }
}
