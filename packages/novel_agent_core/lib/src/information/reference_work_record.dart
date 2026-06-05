import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'information_source_ref.dart';
import 'information_validation_codes.dart';

const _referenceWorkRecordCodecService = OpenJsonContractCodecService();
const _referenceWorkRecordValidatorService =
    OpenJsonStructureValidatorService();
const _referenceWorkRecordKnownFields = <String>{
  'reference_work_id',
  'title',
  'creator',
  'version',
  'source_refs',
  'relationship_to_project',
  'declared_usage_intent',
  'allowed_usage_summary',
  'risk_notes',
  'requires_confirmation',
  'schema_version',
  'metadata',
};

class ReferenceWorkRecord {
  const ReferenceWorkRecord({
    required this.referenceWorkId,
    required this.title,
    required this.sourceRefs,
    required this.relationshipToProject,
    required this.declaredUsageIntent,
    this.creator = '',
    this.version = '',
    this.allowedUsageSummary = '',
    this.riskNotes = const <Object?>[],
    this.requiresConfirmation = false,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String referenceWorkId;
  final String title;
  final String creator;
  final String version;
  final List<InformationSourceRef> sourceRefs;
  final String relationshipToProject;
  final String declaredUsageIntent;
  final String allowedUsageSummary;
  final List<Object?> riskNotes;
  final bool requiresConfirmation;
  final String schemaVersion;
  final JsonMap metadata;

  ReferenceWorkRecord copyWith({
    String? referenceWorkId,
    String? title,
    String? creator,
    String? version,
    List<InformationSourceRef>? sourceRefs,
    String? relationshipToProject,
    String? declaredUsageIntent,
    String? allowedUsageSummary,
    List<Object?>? riskNotes,
    bool? requiresConfirmation,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 引用作品记录会在用户确认、边界调整和后续投影阶段被局部修补，这里统一提供稳定 copy 入口。
    return ReferenceWorkRecord(
      referenceWorkId: referenceWorkId ?? this.referenceWorkId,
      title: title ?? this.title,
      creator: creator ?? this.creator,
      version: version ?? this.version,
      sourceRefs: sourceRefs ?? this.sourceRefs,
      relationshipToProject:
          relationshipToProject ?? this.relationshipToProject,
      declaredUsageIntent: declaredUsageIntent ?? this.declaredUsageIntent,
      allowedUsageSummary: allowedUsageSummary ?? this.allowedUsageSummary,
      riskNotes: riskNotes ?? this.riskNotes,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ReferenceWorkRecord.fromJson(JsonMap json) {
    // 中文注释: relationship_to_project 保持开放字符串，避免提前把穿书、同人或跨作品边界锁进固定枚举表。
    return ReferenceWorkRecord(
      referenceWorkId: ValueReaders.stringValue(
        json['reference_work_id'],
      ).trim(),
      title: ValueReaders.stringValue(json['title']).trim(),
      creator: ValueReaders.stringValue(json['creator']).trim(),
      version: ValueReaders.stringValue(json['version']).trim(),
      sourceRefs: ValueReaders.mapList(
        json['source_refs'],
      ).map(InformationSourceRef.fromJson).toList(growable: false),
      relationshipToProject: ValueReaders.stringValue(
        json['relationship_to_project'],
      ).trim(),
      declaredUsageIntent: ValueReaders.stringValue(
        json['declared_usage_intent'],
      ).trim(),
      allowedUsageSummary: ValueReaders.stringValue(
        json['allowed_usage_summary'],
      ).trim(),
      riskNotes: ValueReaders.deepCopyList(
        ValueReaders.objectList(json['risk_notes']),
      ),
      requiresConfirmation: ValueReaders.boolValue(
        json['requires_confirmation'],
      ),
      schemaVersion: _referenceWorkRecordCodecService.readSchemaVersion(json),
      metadata: _referenceWorkRecordCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _referenceWorkRecordKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 输出时固定作品边界壳层，但 risk notes 与未知字段继续保持开放结构。
    return _referenceWorkRecordCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'reference_work_id': referenceWorkId,
          'title': title,
          'creator': creator,
          'version': version,
          'source_refs': sourceRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'relationship_to_project': relationshipToProject,
          'declared_usage_intent': declaredUsageIntent,
          'allowed_usage_summary': allowedUsageSummary,
          'risk_notes': ValueReaders.deepCopyList(riskNotes),
          'requires_confirmation': requiresConfirmation,
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    // 中文注释: 这里只校验引用作品记录的最小边界合同，不在这里实现版权判断、联网研究或同人写作能力。
    final result = <String>[];
    result.addAll(
      _referenceWorkRecordValidatorService.requireNonBlankString(
        referenceWorkId,
        InformationValidationCodes.missingReferenceWorkId,
      ),
    );
    result.addAll(
      _referenceWorkRecordValidatorService.requireNonBlankString(
        title,
        InformationValidationCodes.missingReferenceWorkTitle,
      ),
    );
    result.addAll(
      _referenceWorkRecordValidatorService.requireNonEmptyCollection(
        sourceRefs,
        InformationValidationCodes.missingReferenceWorkSourceRef,
      ),
    );
    result.addAll(
      _referenceWorkRecordValidatorService.requireNonBlankString(
        relationshipToProject,
        InformationValidationCodes.missingReferenceWorkRelationshipToProject,
      ),
    );
    result.addAll(
      _referenceWorkRecordValidatorService.requireNonBlankString(
        declaredUsageIntent,
        InformationValidationCodes.missingReferenceWorkDeclaredUsageIntent,
      ),
    );
    return result;
  }
}
