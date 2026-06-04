import '../common/json_types.dart';
import '../common/value_readers.dart';

class BookDeconstructionDerivedNarrativeInheritanceEntry {
  const BookDeconstructionDerivedNarrativeInheritanceEntry({
    required this.artifactType,
    required this.artifactId,
    required this.status,
    this.sourceType = '',
    this.namespace = '',
    this.promotionTarget = '',
    this.metadata = const <String, Object?>{},
  });

  final String artifactType;
  final String artifactId;
  final String status;
  final String sourceType;
  final String namespace;
  final String promotionTarget;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'artifact_type': artifactType,
      'artifact_id': artifactId,
      'status': status,
      'source_type': sourceType,
      'namespace': namespace,
      'promotion_target': promotionTarget,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
