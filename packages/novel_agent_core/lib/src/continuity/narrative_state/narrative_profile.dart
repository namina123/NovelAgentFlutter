import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_profile_lifecycle_status.dart';
import 'narrative_source_ref.dart';
import 'narrative_profile_validation_codes.dart';

const _narrativeProfileCodecService = OpenJsonContractCodecService();
const _narrativeProfileValidatorService = OpenJsonStructureValidatorService();

class NarrativeProfile {
  const NarrativeProfile({
    required this.profileId,
    required this.profileNamespace,
    required this.lifecycleStatus,
    required this.source,
    this.profileLabel = '',
    this.profilePayload = const <String, Object?>{},
    this.profileExtensions = const <String, Object?>{},
    this.confidence = 0,
    this.reason = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String profileId;
  final String profileNamespace;
  final String profileLabel;
  final NarrativeProfileLifecycleStatus lifecycleStatus;
  final JsonMap profilePayload;
  final JsonMap profileExtensions;
  final NarrativeSourceRef source;
  final double confidence;
  final String reason;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeProfile copyWith({
    String? profileId,
    String? profileNamespace,
    String? profileLabel,
    NarrativeProfileLifecycleStatus? lifecycleStatus,
    JsonMap? profilePayload,
    JsonMap? profileExtensions,
    NarrativeSourceRef? source,
    double? confidence,
    String? reason,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: profile 在后续 proposal、interpreter 和 repository 场景中会被局部修补，这里先给稳定 copy 入口。
    return NarrativeProfile(
      profileId: profileId ?? this.profileId,
      profileNamespace: profileNamespace ?? this.profileNamespace,
      profileLabel: profileLabel ?? this.profileLabel,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      profilePayload: profilePayload ?? this.profilePayload,
      profileExtensions: profileExtensions ?? this.profileExtensions,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeProfile.fromJson(JsonMap json) {
    // 中文注释: payload 和 extensions 都保持开放 JSON，避免把旧 continuity profile 逼回固定题材结构。
    return NarrativeProfile(
      profileId: ValueReaders.stringValue(json['profile_id']).trim(),
      profileNamespace: ValueReaders.stringValue(
        json['profile_namespace'],
      ).trim(),
      profileLabel: ValueReaders.stringValue(json['profile_label']).trim(),
      lifecycleStatus: NarrativeProfileLifecycleStatus.fromId(
        ValueReaders.stringValue(json['lifecycle_status']),
      ),
      profilePayload: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['profile_payload']),
      ),
      profileExtensions: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['profile_extensions']),
      ),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      confidence: ValueReaders.doubleValue(json['confidence']),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      schemaVersion: _narrativeProfileCodecService.readSchemaVersion(json),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: profile 的输出结构固定在这里，后续持久化和提案合同都直接复用这一份键名。
    return <String, Object?>{
      'profile_id': profileId,
      'profile_namespace': profileNamespace,
      'profile_label': profileLabel,
      'lifecycle_status': lifecycleStatus.id,
      'profile_payload': ValueReaders.deepCopyMap(profilePayload),
      'profile_extensions': ValueReaders.deepCopyMap(profileExtensions),
      'source': source.toJson(),
      'confidence': confidence,
      'reason': reason,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 这里只做 profile 合同的最小结构校验，不在本轮引入生命周期流转规则。
    final result = <String>[];
    result.addAll(
      _narrativeProfileValidatorService.requireNonBlankString(
        profileId,
        NarrativeProfileValidationCodes.missingProfileId,
      ),
    );
    result.addAll(
      _narrativeProfileValidatorService.requireNonBlankString(
        profileNamespace,
        NarrativeProfileValidationCodes.missingProfileNamespace,
      ),
    );
    result.addAll(
      _narrativeProfileValidatorService.requireNonBlankString(
        source.sourceType,
        NarrativeProfileValidationCodes.missingSourceType,
      ),
    );
    result.addAll(
      _narrativeProfileValidatorService.validateConfidence(
        confidence,
        NarrativeProfileValidationCodes.invalidConfidence,
      ),
    );
    return result;
  }
}
