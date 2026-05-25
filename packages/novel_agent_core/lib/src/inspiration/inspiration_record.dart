import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'inspiration_field_value.dart';

class InspirationRecord {
  const InspirationRecord({
    required this.id,
    required this.title,
    this.sourceId = '',
    this.fieldValues = const <InspirationFieldValue>[],
    this.completedStageIds = const <String>[],
    this.createdAt = '',
    this.updatedAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String sourceId;
  final List<InspirationFieldValue> fieldValues;
  final List<String> completedStageIds;
  final String createdAt;
  final String updatedAt;
  final Map<String, Object?> metadata;

  JsonMap toJsonMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'source_id': sourceId,
      'completed_stage_ids': completedStageIds,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'metadata': metadata,
      'field_values': fieldValues
          .map((value) => value.toJsonMap())
          .toList(growable: false),
    };
  }

  static InspirationRecord fromJsonMap(JsonMap document) {
    return InspirationRecord(
      id: ValueReaders.stringValue(document['id']),
      title: ValueReaders.stringValue(document['title']),
      sourceId: ValueReaders.stringValue(document['source_id']),
      completedStageIds: ValueReaders.stringList(document['completed_stage_ids']),
      createdAt: ValueReaders.stringValue(document['created_at']),
      updatedAt: ValueReaders.stringValue(document['updated_at']),
      metadata: ValueReaders.mapValue(document['metadata']),
      fieldValues: ValueReaders.mapList(
        document['field_values'],
      ).map(InspirationFieldValue.fromJsonMap).toList(growable: false),
    );
  }
}
