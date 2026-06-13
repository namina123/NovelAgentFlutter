import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../output/output_contract_models.dart';

abstract final class ReferenceExtractionDeliveryStatuses {
  static const String publishable = 'publishable';
  static const String stagingOnly = 'staging_only';
}

class ReferenceExtractionDeliveryDecision {
  const ReferenceExtractionDeliveryDecision({
    this.deliveryStatus = ReferenceExtractionDeliveryStatuses.publishable,
    this.outputCompletionStatus = OutputCompletionStatuses.completed,
    this.rationale = '',
    this.metadata = const <String, Object?>{},
  });

  final String deliveryStatus;
  final String outputCompletionStatus;
  final String rationale;
  final JsonMap metadata;

  bool get isPublishable =>
      deliveryStatus == ReferenceExtractionDeliveryStatuses.publishable;

  bool get requiresStagingOnly =>
      deliveryStatus == ReferenceExtractionDeliveryStatuses.stagingOnly;

  JsonMap toJson() {
    return <String, Object?>{
      'delivery_status': deliveryStatus,
      'output_completion_status': outputCompletionStatus,
      'rationale': rationale,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ReferenceExtractionDeliveryDecision fromJson(JsonMap json) {
    return ReferenceExtractionDeliveryDecision(
      deliveryStatus: ValueReaders.stringValue(
        json['delivery_status'],
        ReferenceExtractionDeliveryStatuses.publishable,
      ).trim(),
      outputCompletionStatus: ValueReaders.stringValue(
        json['output_completion_status'],
        OutputCompletionStatuses.completed,
      ).trim(),
      rationale: ValueReaders.stringValue(json['rationale']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}
