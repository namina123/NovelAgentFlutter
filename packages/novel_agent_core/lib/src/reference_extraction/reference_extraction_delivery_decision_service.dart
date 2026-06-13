import '../output/output_contract_models.dart';
import 'reference_extraction_delivery_decision.dart';
import 'reference_extraction_review_models.dart';

class ReferenceExtractionDeliveryDecisionService {
  const ReferenceExtractionDeliveryDecisionService();

  ReferenceExtractionDeliveryDecision resolve(
    ReferenceExtractionReviewOutcome reviewOutcome,
  ) {
    final outputCompletionStatus = reviewOutcome.outputCompletionStatus;
    if (outputCompletionStatus == OutputCompletionStatuses.completed) {
      return const ReferenceExtractionDeliveryDecision(
        deliveryStatus: ReferenceExtractionDeliveryStatuses.publishable,
        outputCompletionStatus: OutputCompletionStatuses.completed,
        rationale: '输出合同完成，可进入正式 finalized/export/project 消费链。',
      );
    }
    if (outputCompletionStatus ==
        OutputCompletionStatuses.continuationRecommended) {
      return const ReferenceExtractionDeliveryDecision(
        deliveryStatus: ReferenceExtractionDeliveryStatuses.stagingOnly,
        outputCompletionStatus:
            OutputCompletionStatuses.continuationRecommended,
        rationale: '当前结果明确请求续提，只保留 staging 语义，不进入正式消费链。',
      );
    }
    if (outputCompletionStatus ==
        OutputCompletionStatuses.coverageInsufficient) {
      return const ReferenceExtractionDeliveryDecision(
        deliveryStatus: ReferenceExtractionDeliveryStatuses.stagingOnly,
        outputCompletionStatus: OutputCompletionStatuses.coverageInsufficient,
        rationale: '当前结果覆盖不足，只保留 staging 语义，不进入正式消费链。',
      );
    }
    return const ReferenceExtractionDeliveryDecision(
      deliveryStatus: ReferenceExtractionDeliveryStatuses.stagingOnly,
      outputCompletionStatus: OutputCompletionStatuses.compressed,
      rationale: '当前结果存在压缩风险，只保留 staging 语义，不进入正式消费链。',
    );
  }
}
