import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'tool_exposure_level.dart';

class ToolCapabilityExposurePolicy {
  const ToolCapabilityExposurePolicy({
    required this.familyId,
    required this.exposureLevel,
    this.rationale = '',
    this.metadata = const <String, Object?>{},
  });

  final String familyId;
  final String exposureLevel;
  final String rationale;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'family_id': familyId,
      'exposure_level': exposureLevel,
      'rationale': rationale,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ToolCapabilityExposurePolicy fromJson(JsonMap json) {
    // 中文注释: 暴露策略条目保持独立合同，后续 agent group/profile/runtime 都能复用，而不是在各入口各自拼接权限语义。
    return ToolCapabilityExposurePolicy(
      familyId: ValueReaders.stringValue(json['family_id']).trim(),
      exposureLevel: ValueReaders.stringValue(json['exposure_level']).trim(),
      rationale: ValueReaders.stringValue(json['rationale']).trim(),
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
    if (!ToolExposureLevels.contains(exposureLevel)) {
      result.add('invalid_tool_exposure_level');
    }
    return result;
  }
}
