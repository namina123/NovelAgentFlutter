import 'package:novel_agent_core/novel_agent_core.dart';

class ModelParameterEntryViewData {
  const ModelParameterEntryViewData({
    required this.keyName,
    required this.valueType,
    required this.value,
    this.description = '',
    this.exclusiveGroup = '',
    this.isBuiltIn = false,
  });

  final String keyName;
  final String valueType;
  final Object? value;
  final String description;
  final String exclusiveGroup;
  final bool isBuiltIn;

  factory ModelParameterEntryViewData.fromMap(Map<String, Object?> document) {
    return ModelParameterEntryViewData(
      keyName: ValueReaders.stringValue(document['key']).trim(),
      valueType: ValueReaders.stringValue(document['type'], 'string').trim(),
      value: document['value'],
      description: ValueReaders.stringValue(document['description']).trim(),
      exclusiveGroup: ValueReaders.stringValue(
        document['exclusive_group'],
      ).trim(),
      isBuiltIn: ValueReaders.boolValue(document['is_built_in']),
    );
  }

  String valueText() {
    final current = value;
    if (current == null) {
      return '';
    }
    if (current is String) {
      return current;
    }
    return current.toString();
  }

  ModelParameterEntryViewData copyWith({
    String? keyName,
    String? valueType,
    Object? value,
    bool clearValue = false,
    String? description,
    String? exclusiveGroup,
    bool? isBuiltIn,
  }) {
    return ModelParameterEntryViewData(
      keyName: keyName ?? this.keyName,
      valueType: valueType ?? this.valueType,
      value: clearValue ? null : (value ?? this.value),
      description: description ?? this.description,
      exclusiveGroup: exclusiveGroup ?? this.exclusiveGroup,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, Object?> toDocument() {
    return <String, Object?>{
      'key': keyName.trim(),
      'type': valueType.trim(),
      'value': value,
      if (description.trim().isNotEmpty) 'description': description.trim(),
      if (exclusiveGroup.trim().isNotEmpty)
        'exclusive_group': exclusiveGroup.trim(),
    };
  }
}
