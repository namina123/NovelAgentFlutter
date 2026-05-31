import '../common/json_types.dart';
import '../common/value_readers.dart';

class OpeningStageRecord {
  const OpeningStageRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.required = true,
    this.metadata = const <String, Object?>{},
  });

  static const String statusPending = 'pending';
  static const String statusCurrent = 'current';
  static const String statusCompleted = 'completed';
  static const String statusReady = 'ready';

  final String id;
  final String title;
  final String description;
  final String status;
  final bool required;
  final JsonMap metadata;

  JsonMap toJsonMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'required': required,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OpeningStageRecord fromJsonMap(JsonMap document) {
    return OpeningStageRecord(
      id: ValueReaders.stringValue(document['id']).trim(),
      title: ValueReaders.stringValue(document['title']).trim(),
      description: ValueReaders.stringValue(document['description']).trim(),
      status: ValueReaders.stringValue(
        document['status'],
        statusPending,
      ).trim(),
      required: ValueReaders.boolValue(document['required'], true),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['metadata']),
      ),
    );
  }
}
