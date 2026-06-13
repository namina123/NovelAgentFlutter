import '../common/json_types.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'reference_package_models.dart';
import 'reference_substrate_constants.dart';
import 'reference_substrate_validation_codes.dart';

const _referenceBundleValidatorService = OpenJsonStructureValidatorService();

class ReferenceBundleManifest {
  const ReferenceBundleManifest({
    required this.bundleId,
    required this.packageId,
    required this.packageVersionId,
    required this.displayName,
    required this.packageKind,
    required this.createdAt,
    this.sourceLanguage = '',
    this.targetLanguage = '',
    this.bundleSchemaVersion = ReferenceBundleConstants.bundleSchemaVersion,
    this.createdBy = '',
    this.sourceSummary = '',
    this.licenseSummary = '',
    this.dependencySummary = '',
    this.integrityHashes = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final String bundleId;
  final String packageId;
  final String packageVersionId;
  final String bundleSchemaVersion;
  final String displayName;
  final String packageKind;
  final String createdAt;
  final String sourceLanguage;
  final String targetLanguage;
  final String createdBy;
  final String sourceSummary;
  final String licenseSummary;
  final String dependencySummary;
  final JsonMap integrityHashes;
  final JsonMap metadata;

  factory ReferenceBundleManifest.fromJson(JsonMap json) {
    return ReferenceBundleManifest(
      bundleId: ValueReaders.stringValue(json['bundle_id']).trim(),
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      packageVersionId: ValueReaders.stringValue(
        json['package_version_id'],
      ).trim(),
      bundleSchemaVersion: ValueReaders.stringValue(
        json['bundle_schema_version'],
        ReferenceBundleConstants.bundleSchemaVersion,
      ).trim(),
      displayName: ValueReaders.stringValue(json['display_name']).trim(),
      packageKind: ValueReaders.stringValue(json['package_kind']).trim(),
      createdAt: ValueReaders.stringValue(json['created_at']).trim(),
      sourceLanguage: ValueReaders.stringValue(json['source_language']).trim(),
      targetLanguage: ValueReaders.stringValue(json['target_language']).trim(),
      createdBy: ValueReaders.stringValue(json['created_by']).trim(),
      sourceSummary: ValueReaders.stringValue(json['source_summary']).trim(),
      licenseSummary: ValueReaders.stringValue(json['license_summary']).trim(),
      dependencySummary: ValueReaders.stringValue(
        json['dependency_summary'],
      ).trim(),
      integrityHashes: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['integrity_hashes']),
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'bundle_id': bundleId,
      'package_id': packageId,
      'package_version_id': packageVersionId,
      'bundle_schema_version': bundleSchemaVersion,
      'display_name': displayName,
      'package_kind': packageKind,
      'created_at': createdAt,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'created_by': createdBy,
      'source_summary': sourceSummary,
      'license_summary': licenseSummary,
      'dependency_summary': dependencySummary,
      'integrity_hashes': ValueReaders.deepCopyMap(integrityHashes),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _referenceBundleValidatorService.requireNonBlankString(
        bundleId,
        ReferenceSubstrateValidationCodes.missingReferenceBundleId,
      ),
    );
    result.addAll(
      _referenceBundleValidatorService.requireNonBlankString(
        packageId,
        ReferenceSubstrateValidationCodes.missingReferencePackageId,
      ),
    );
    result.addAll(
      _referenceBundleValidatorService.requireNonBlankString(
        packageVersionId,
        ReferenceSubstrateValidationCodes.missingReferencePackageVersionId,
      ),
    );
    result.addAll(
      _referenceBundleValidatorService.requireNonBlankString(
        bundleSchemaVersion,
        ReferenceSubstrateValidationCodes.missingReferenceBundleSchemaVersion,
      ),
    );
    result.addAll(
      _referenceBundleValidatorService.requireNonBlankString(
        createdAt,
        ReferenceSubstrateValidationCodes.missingReferenceBundleCreatedAt,
      ),
    );
    return result;
  }
}

class ReferenceBundleDocument {
  const ReferenceBundleDocument({
    required this.manifest,
    required this.snapshot,
    this.projections = const <String, String>{},
    this.integrity = const <String, Object?>{},
  });

  final ReferenceBundleManifest manifest;
  final ReferencePackageSnapshot snapshot;
  final Map<String, String> projections;
  final JsonMap integrity;
}

class ReferenceBundleExportRequest {
  const ReferenceBundleExportRequest({
    required this.packageId,
    required this.packageVersionId,
    required this.bundleId,
    required this.createdAt,
    this.createdBy = '',
  });

  final String packageId;
  final String packageVersionId;
  final String bundleId;
  final String createdAt;
  final String createdBy;
}

class ReferenceBundleImportResult {
  const ReferenceBundleImportResult({
    required this.packageId,
    required this.packageVersionId,
    this.importedEntryIds = const <String>[],
    this.warnings = const <String>[],
  });

  final String packageId;
  final String packageVersionId;
  final List<String> importedEntryIds;
  final List<String> warnings;
}
