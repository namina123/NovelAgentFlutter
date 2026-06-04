import '../../common/json_types.dart';
import '../../common/value_readers.dart';

class NarrativeSourceRef {
  const NarrativeSourceRef({
    required this.sourceType,
    this.sourceId = '',
    this.label = '',
    this.description = '',
    this.metadata = const <String, Object?>{},
  });

  final String sourceType;
  final String sourceId;
  final String label;
  final String description;
  final JsonMap metadata;

  NarrativeSourceRef copyWith({
    String? sourceType,
    String? sourceId,
    String? label,
    String? description,
    JsonMap? metadata,
  }) {
    // 中文注释: 引用合同在后续 claim/profile/review 间会被频繁浅改，这里先提供稳定 copy 入口。
    return NarrativeSourceRef(
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      label: label ?? this.label,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeSourceRef.fromJson(JsonMap json) {
    // 中文注释: sourceType 故意保留原始字符串，避免未来未知来源被枚举化后静默丢失。
    return NarrativeSourceRef(
      sourceType: ValueReaders.stringValue(json['source_type']).trim(),
      sourceId: ValueReaders.stringValue(json['source_id']).trim(),
      label: ValueReaders.stringValue(json['label']).trim(),
      description: ValueReaders.stringValue(json['description']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: JSON 输出保持开放字段结构，供后续 runtime、repository 与测试直接复用。
    return <String, Object?>{
      'source_type': sourceType,
      'source_id': sourceId,
      'label': label,
      'description': description,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
