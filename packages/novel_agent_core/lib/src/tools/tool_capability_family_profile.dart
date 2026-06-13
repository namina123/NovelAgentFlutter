import '../common/json_types.dart';
import '../common/value_readers.dart';

class ToolCapabilityFamilyProfile {
  const ToolCapabilityFamilyProfile({
    required this.familyId,
    this.displayName = '',
    this.description = '',
    this.toolIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String familyId;
  final String displayName;
  final String description;
  final List<String> toolIds;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'family_id': familyId,
      'display_name': displayName,
      'description': description,
      'tool_ids': toolIds,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ToolCapabilityFamilyProfile fromJson(JsonMap json) {
    // 中文注释: 能力族合同需要独立回放，方便后续 agent group/runtime/GUI 共享同一词表，而不是各自硬编码工具簇。
    return ToolCapabilityFamilyProfile(
      familyId: ValueReaders.stringValue(json['family_id']).trim(),
      displayName: ValueReaders.stringValue(json['display_name']).trim(),
      description: ValueReaders.stringValue(json['description']).trim(),
      toolIds: ValueReaders.stringList(json['tool_ids']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (familyId.trim().isEmpty) {
      result.add('missing_tool_capability_family_id');
    }
    return result;
  }
}
