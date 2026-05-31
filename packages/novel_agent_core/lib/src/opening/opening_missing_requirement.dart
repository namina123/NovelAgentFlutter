import '../common/json_types.dart';
import '../common/value_readers.dart';

class OpeningMissingRequirement {
  const OpeningMissingRequirement({
    required this.id,
    required this.title,
    required this.description,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String description;
  final JsonMap metadata;

  JsonMap toJsonMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
