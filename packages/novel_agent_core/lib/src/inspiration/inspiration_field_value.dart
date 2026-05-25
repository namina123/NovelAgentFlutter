import '../common/json_types.dart';
import '../common/value_readers.dart';

class InspirationFieldValue {
  const InspirationFieldValue({
    required this.stageId,
    required this.fieldKey,
    required this.value,
    this.label = '',
    this.source = 'free_text',
    this.updatedAt = '',
  });

  final String stageId;
  final String fieldKey;
  final String value;
  final String label;
  final String source;
  final String updatedAt;

  JsonMap toJsonMap() {
    return <String, Object?>{
      'stage_id': stageId,
      'field_key': fieldKey,
      'value': value,
      'label': label,
      'source': source,
      'updated_at': updatedAt,
    };
  }

  static InspirationFieldValue fromJsonMap(JsonMap document) {
    return InspirationFieldValue(
      stageId: ValueReaders.stringValue(document['stage_id']),
      fieldKey: ValueReaders.stringValue(document['field_key']),
      value: ValueReaders.stringValue(document['value']),
      label: ValueReaders.stringValue(document['label']),
      source: ValueReaders.stringValue(document['source'], 'free_text'),
      updatedAt: ValueReaders.stringValue(document['updated_at']),
    );
  }
}
