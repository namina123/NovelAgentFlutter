import '../common/json_types.dart';
import '../common/value_readers.dart';

class ModeGuidanceAnswer {
  const ModeGuidanceAnswer({
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

  ModeGuidanceAnswer copyWith({
    String? stageId,
    String? fieldKey,
    String? value,
    String? label,
    String? source,
    String? updatedAt,
  }) {
    // 中文注释: 阶段答案对象保持不可变，避免状态推进时就地改写引发多宿主行为差异。
    return ModeGuidanceAnswer(
      stageId: stageId ?? this.stageId,
      fieldKey: fieldKey ?? this.fieldKey,
      value: value ?? this.value,
      label: label ?? this.label,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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

  static ModeGuidanceAnswer fromJsonMap(JsonMap document) {
    return ModeGuidanceAnswer(
      stageId: ValueReaders.stringValue(document['stage_id']),
      fieldKey: ValueReaders.stringValue(document['field_key']),
      value: ValueReaders.stringValue(document['value']),
      label: ValueReaders.stringValue(document['label']),
      source: ValueReaders.stringValue(document['source'], 'free_text'),
      updatedAt: ValueReaders.stringValue(document['updated_at']),
    );
  }
}
