import '../common/json_types.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../information/information_activation_policy.dart';
import '../information/information_source_ref.dart';
import '../information/information_usage_policy.dart';
import 'reference_attachment_pointer.dart';
import 'reference_substrate_validation_codes.dart';

const _referencePackageValidatorService = OpenJsonStructureValidatorService();

class ReferencePackageRecord {
  const ReferencePackageRecord({
    required this.packageId,
    required this.packageKind,
    required this.displayName,
    this.packageNamespace = '',
    this.sourceLanguage = '',
    this.targetLanguage = '',
    this.description = '',
    this.latestVersionId = '',
    this.lifecycleStatus = '',
    this.sourceSummary = '',
    this.licenseSummary = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String packageId;
  final String packageKind;
  final String displayName;
  final String packageNamespace;
  final String sourceLanguage;
  final String targetLanguage;
  final String description;
  final String latestVersionId;
  final String lifecycleStatus;
  final String sourceSummary;
  final String licenseSummary;
  final String createdAt;
  final String updatedAt;
  final JsonMap metadata;

  factory ReferencePackageRecord.fromJson(JsonMap json) {
    return ReferencePackageRecord(
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      packageKind: ValueReaders.stringValue(json['package_kind']).trim(),
      displayName: ValueReaders.stringValue(json['display_name']).trim(),
      packageNamespace: ValueReaders.stringValue(
        json['package_namespace'],
      ).trim(),
      sourceLanguage: ValueReaders.stringValue(json['source_language']).trim(),
      targetLanguage: ValueReaders.stringValue(json['target_language']).trim(),
      description: ValueReaders.stringValue(json['description']).trim(),
      latestVersionId: ValueReaders.stringValue(
        json['latest_version_id'],
      ).trim(),
      lifecycleStatus: ValueReaders.stringValue(
        json['lifecycle_status'],
      ).trim(),
      sourceSummary: ValueReaders.stringValue(json['source_summary']).trim(),
      licenseSummary: ValueReaders.stringValue(json['license_summary']).trim(),
      createdAt: ValueReaders.stringValue(json['created_at']).trim(),
      updatedAt: ValueReaders.stringValue(json['updated_at']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'package_id': packageId,
      'package_kind': packageKind,
      'display_name': displayName,
      'package_namespace': packageNamespace,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'description': description,
      'latest_version_id': latestVersionId,
      'lifecycle_status': lifecycleStatus,
      'source_summary': sourceSummary,
      'license_summary': licenseSummary,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        packageId,
        ReferenceSubstrateValidationCodes.missingReferencePackageId,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        packageKind,
        ReferenceSubstrateValidationCodes.missingReferencePackageKind,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        displayName,
        ReferenceSubstrateValidationCodes.missingReferencePackageDisplayName,
      ),
    );
    return result;
  }
}

class ReferencePackageVersionRecord {
  const ReferencePackageVersionRecord({
    required this.packageVersionId,
    required this.packageId,
    required this.versionLabel,
    this.createdAt = '',
    this.createdBy = '',
    this.sourceSummary = '',
    this.licenseSummary = '',
    this.dependencySummary = '',
    this.integrityHash = '',
    this.metadata = const <String, Object?>{},
  });

  final String packageVersionId;
  final String packageId;
  final String versionLabel;
  final String createdAt;
  final String createdBy;
  final String sourceSummary;
  final String licenseSummary;
  final String dependencySummary;
  final String integrityHash;
  final JsonMap metadata;

  factory ReferencePackageVersionRecord.fromJson(JsonMap json) {
    return ReferencePackageVersionRecord(
      packageVersionId: ValueReaders.stringValue(
        json['package_version_id'],
      ).trim(),
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      versionLabel: ValueReaders.stringValue(json['version_label']).trim(),
      createdAt: ValueReaders.stringValue(json['created_at']).trim(),
      createdBy: ValueReaders.stringValue(json['created_by']).trim(),
      sourceSummary: ValueReaders.stringValue(json['source_summary']).trim(),
      licenseSummary: ValueReaders.stringValue(json['license_summary']).trim(),
      dependencySummary: ValueReaders.stringValue(
        json['dependency_summary'],
      ).trim(),
      integrityHash: ValueReaders.stringValue(json['integrity_hash']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'package_version_id': packageVersionId,
      'package_id': packageId,
      'version_label': versionLabel,
      'created_at': createdAt,
      'created_by': createdBy,
      'source_summary': sourceSummary,
      'license_summary': licenseSummary,
      'dependency_summary': dependencySummary,
      'integrity_hash': integrityHash,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        packageVersionId,
        ReferenceSubstrateValidationCodes.missingReferencePackageVersionId,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        packageId,
        ReferenceSubstrateValidationCodes.missingReferencePackageId,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        versionLabel,
        ReferenceSubstrateValidationCodes.missingReferenceVersionLabel,
      ),
    );
    return result;
  }
}

class ReferenceEntryRecord {
  const ReferenceEntryRecord({
    required this.entryId,
    required this.packageId,
    required this.packageVersionId,
    required this.entryNamespace,
    required this.entryKind,
    required this.title,
    required this.activationPolicy,
    required this.usagePolicy,
    required this.lifecycleStatus,
    this.summary = '',
    this.payload = const <String, Object?>{},
    this.sourceRefs = const <InformationSourceRef>[],
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.tags = const <String>[],
    this.attachments = const <ReferenceAttachmentPointer>[],
    this.confidence = 0,
    this.metadata = const <String, Object?>{},
  });

  final String entryId;
  final String packageId;
  final String packageVersionId;
  final String entryNamespace;
  final String entryKind;
  final String title;
  final String summary;
  final JsonMap payload;
  final List<InformationSourceRef> sourceRefs;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final List<String> tags;
  final List<ReferenceAttachmentPointer> attachments;
  final InformationActivationPolicy activationPolicy;
  final InformationUsagePolicy usagePolicy;
  final double confidence;
  final String lifecycleStatus;
  final JsonMap metadata;

  factory ReferenceEntryRecord.fromJson(JsonMap json) {
    return ReferenceEntryRecord(
      entryId: ValueReaders.stringValue(json['entry_id']).trim(),
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      packageVersionId: ValueReaders.stringValue(
        json['package_version_id'],
      ).trim(),
      entryNamespace: ValueReaders.stringValue(json['entry_namespace']).trim(),
      entryKind: ValueReaders.stringValue(json['entry_kind']).trim(),
      title: ValueReaders.stringValue(json['title']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      payload: ValueReaders.deepCopyMap(ValueReaders.mapValue(json['payload'])),
      sourceRefs: ValueReaders.mapList(
        json['source_refs'],
      ).map(InformationSourceRef.fromJson).toList(growable: false),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      tags: ValueReaders.objectList(json['tags'])
          .map((entry) => ValueReaders.stringValue(entry).trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      attachments: ValueReaders.mapList(
        json['attachments'],
      ).map(ReferenceAttachmentPointer.fromJson).toList(growable: false),
      activationPolicy: InformationActivationPolicy.fromJson(
        ValueReaders.mapValue(json['activation_policy']),
      ),
      usagePolicy: InformationUsagePolicy.fromJson(
        ValueReaders.mapValue(json['usage_policy']),
      ),
      confidence: ValueReaders.doubleValue(json['confidence']),
      lifecycleStatus: ValueReaders.stringValue(
        json['lifecycle_status'],
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'entry_id': entryId,
      'package_id': packageId,
      'package_version_id': packageVersionId,
      'entry_namespace': entryNamespace,
      'entry_kind': entryKind,
      'title': title,
      'summary': summary,
      'payload': ValueReaders.deepCopyMap(payload),
      'source_refs': sourceRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'evidence_refs': evidenceRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'tags': tags.toList(growable: false),
      'attachments': attachments
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'activation_policy': activationPolicy.toJson(),
      'usage_policy': usagePolicy.toJson(),
      'confidence': confidence,
      'lifecycle_status': lifecycleStatus,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        entryId,
        ReferenceSubstrateValidationCodes.missingReferenceEntryId,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        packageId,
        ReferenceSubstrateValidationCodes.missingReferencePackageId,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        packageVersionId,
        ReferenceSubstrateValidationCodes.missingReferencePackageVersionId,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        entryNamespace,
        ReferenceSubstrateValidationCodes.missingReferenceEntryNamespace,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        entryKind,
        ReferenceSubstrateValidationCodes.missingReferenceEntryKind,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        title,
        ReferenceSubstrateValidationCodes.missingReferenceEntryTitle,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        lifecycleStatus,
        ReferenceSubstrateValidationCodes.missingReferenceEntryLifecycleStatus,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.validateConfidence(
        confidence,
        ReferenceSubstrateValidationCodes.invalidReferenceEntryConfidence,
      ),
    );
    result.addAll(activationPolicy.validateBasics());
    result.addAll(usagePolicy.validateBasics());
    return result;
  }
}

class ReferenceDependencyRecord {
  const ReferenceDependencyRecord({
    required this.packageVersionId,
    required this.dependencyPackageId,
    this.dependencyVersionId = '',
    this.relationshipKind = '',
    this.metadata = const <String, Object?>{},
  });

  final String packageVersionId;
  final String dependencyPackageId;
  final String dependencyVersionId;
  final String relationshipKind;
  final JsonMap metadata;

  factory ReferenceDependencyRecord.fromJson(JsonMap json) {
    return ReferenceDependencyRecord(
      packageVersionId: ValueReaders.stringValue(
        json['package_version_id'],
      ).trim(),
      dependencyPackageId: ValueReaders.stringValue(
        json['dependency_package_id'],
      ).trim(),
      dependencyVersionId: ValueReaders.stringValue(
        json['dependency_version_id'],
      ).trim(),
      relationshipKind: ValueReaders.stringValue(
        json['relationship_kind'],
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'package_version_id': packageVersionId,
      'dependency_package_id': dependencyPackageId,
      'dependency_version_id': dependencyVersionId,
      'relationship_kind': relationshipKind,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}

class ReferencePromotionRecord {
  const ReferencePromotionRecord({
    required this.promotionId,
    required this.sourceProjectId,
    required this.sourceArtifactKind,
    required this.sourceArtifactId,
    required this.targetPackageId,
    required this.targetPackageVersionId,
    required this.targetEntryId,
    required this.promotedAt,
    this.promotedBy = '',
    this.metadata = const <String, Object?>{},
  });

  final String promotionId;
  final String sourceProjectId;
  final String sourceArtifactKind;
  final String sourceArtifactId;
  final String targetPackageId;
  final String targetPackageVersionId;
  final String targetEntryId;
  final String promotedAt;
  final String promotedBy;
  final JsonMap metadata;

  factory ReferencePromotionRecord.fromJson(JsonMap json) {
    return ReferencePromotionRecord(
      promotionId: ValueReaders.stringValue(json['promotion_id']).trim(),
      sourceProjectId: ValueReaders.stringValue(
        json['source_project_id'],
      ).trim(),
      sourceArtifactKind: ValueReaders.stringValue(
        json['source_artifact_kind'],
      ).trim(),
      sourceArtifactId: ValueReaders.stringValue(
        json['source_artifact_id'],
      ).trim(),
      targetPackageId: ValueReaders.stringValue(
        json['target_package_id'],
      ).trim(),
      targetPackageVersionId: ValueReaders.stringValue(
        json['target_package_version_id'],
      ).trim(),
      targetEntryId: ValueReaders.stringValue(json['target_entry_id']).trim(),
      promotedAt: ValueReaders.stringValue(json['promoted_at']).trim(),
      promotedBy: ValueReaders.stringValue(json['promoted_by']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'promotion_id': promotionId,
      'source_project_id': sourceProjectId,
      'source_artifact_kind': sourceArtifactKind,
      'source_artifact_id': sourceArtifactId,
      'target_package_id': targetPackageId,
      'target_package_version_id': targetPackageVersionId,
      'target_entry_id': targetEntryId,
      'promoted_at': promotedAt,
      'promoted_by': promotedBy,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        promotionId,
        ReferenceSubstrateValidationCodes.missingReferencePromotionId,
      ),
    );
    result.addAll(
      _referencePackageValidatorService.requireNonBlankString(
        promotedAt,
        ReferenceSubstrateValidationCodes.missingReferenceBundleCreatedAt,
      ),
    );
    return result;
  }
}

class ReferencePackageSnapshot {
  const ReferencePackageSnapshot({
    required this.packageRecord,
    required this.packageVersionRecord,
    this.entries = const <ReferenceEntryRecord>[],
    this.dependencies = const <ReferenceDependencyRecord>[],
    this.promotionRecords = const <ReferencePromotionRecord>[],
  });

  final ReferencePackageRecord packageRecord;
  final ReferencePackageVersionRecord packageVersionRecord;
  final List<ReferenceEntryRecord> entries;
  final List<ReferenceDependencyRecord> dependencies;
  final List<ReferencePromotionRecord> promotionRecords;

  JsonMap toJson() {
    return <String, Object?>{
      'package_record': packageRecord.toJson(),
      'package_version_record': packageVersionRecord.toJson(),
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'dependencies': dependencies
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'promotion_records': promotionRecords
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}
