import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_source_ref.dart';
import 'narrative_profile_validation_codes.dart';

const _narrativeProfilePatchCodecService = OpenJsonContractCodecService();
const _narrativeProfilePatchValidatorService =
    OpenJsonStructureValidatorService();

class NarrativeProfilePatch {
  const NarrativeProfilePatch({
    required this.patchId,
    required this.source,
    this.patchLabel = '',
    this.patchPayload = const <String, Object?>{},
    this.patchExtensions = const <String, Object?>{},
    this.confidence = 0,
    this.reason = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String patchId;
  final String patchLabel;
  final JsonMap patchPayload;
  final JsonMap patchExtensions;
  final NarrativeSourceRef source;
  final double confidence;
  final String reason;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeProfilePatch copyWith({
    String? patchId,
    String? patchLabel,
    JsonMap? patchPayload,
    JsonMap? patchExtensions,
    NarrativeSourceRef? source,
    double? confidence,
    String? reason,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: patch 是开放提案载荷，后续需要允许 profile architect 在不改模型的前提下迭代内容。
    return NarrativeProfilePatch(
      patchId: patchId ?? this.patchId,
      patchLabel: patchLabel ?? this.patchLabel,
      patchPayload: patchPayload ?? this.patchPayload,
      patchExtensions: patchExtensions ?? this.patchExtensions,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeProfilePatch.fromJson(JsonMap json) {
    // 中文注释: patch payload 保持开放 JSON，不把未知项目规则强制压成固定字段。
    return NarrativeProfilePatch(
      patchId: ValueReaders.stringValue(json['patch_id']).trim(),
      patchLabel: ValueReaders.stringValue(json['patch_label']).trim(),
      patchPayload: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['patch_payload']),
      ),
      patchExtensions: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['patch_extensions']),
      ),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      confidence: ValueReaders.doubleValue(json['confidence']),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      schemaVersion: _narrativeProfilePatchCodecService.readSchemaVersion(json),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: patch 单独编码，方便 proposal、validator 与未来 repository 复用同一个序列化结构。
    return <String, Object?>{
      'patch_id': patchId,
      'patch_label': patchLabel,
      'patch_payload': ValueReaders.deepCopyMap(patchPayload),
      'patch_extensions': ValueReaders.deepCopyMap(patchExtensions),
      'source': source.toJson(),
      'confidence': confidence,
      'reason': reason,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: patch 只校验最小身份和来源，不在这里提前做 profile 解释或权限决策。
    final result = <String>[];
    result.addAll(
      _narrativeProfilePatchValidatorService.requireNonBlankString(
        patchId,
        NarrativeProfileValidationCodes.missingPatchId,
      ),
    );
    result.addAll(
      _narrativeProfilePatchValidatorService.requireNonBlankString(
        source.sourceType,
        NarrativeProfileValidationCodes.missingSourceType,
      ),
    );
    result.addAll(
      _narrativeProfilePatchValidatorService.validateConfidence(
        confidence,
        NarrativeProfileValidationCodes.invalidConfidence,
      ),
    );
    return result;
  }
}
