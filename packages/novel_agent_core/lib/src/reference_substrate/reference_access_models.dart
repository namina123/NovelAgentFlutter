import '../common/json_types.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'reference_substrate_validation_codes.dart';

const _referenceAccessValidatorService = OpenJsonStructureValidatorService();

class ProjectReferenceAttachment {
  const ProjectReferenceAttachment({
    required this.attachmentId,
    required this.projectId,
    required this.packageId,
    required this.packageVersionId,
    required this.visibilityMode,
    required this.accessLevel,
    this.displayLabel = '',
    this.allowsDiscoveryExpansion = false,
    this.allowsProjection = false,
    this.allowsPromotion = false,
    this.requiresConfirmation = false,
    this.attachedAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String attachmentId;
  final String projectId;
  final String packageId;
  final String packageVersionId;
  final String visibilityMode;
  final String accessLevel;
  final String displayLabel;
  final bool allowsDiscoveryExpansion;
  final bool allowsProjection;
  final bool allowsPromotion;
  final bool requiresConfirmation;
  final String attachedAt;
  final JsonMap metadata;

  factory ProjectReferenceAttachment.fromJson(JsonMap json) {
    return ProjectReferenceAttachment(
      attachmentId: ValueReaders.stringValue(json['attachment_id']).trim(),
      projectId: ValueReaders.stringValue(json['project_id']).trim(),
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      packageVersionId: ValueReaders.stringValue(
        json['package_version_id'],
      ).trim(),
      visibilityMode: ValueReaders.stringValue(json['visibility_mode']).trim(),
      accessLevel: ValueReaders.stringValue(json['access_level']).trim(),
      displayLabel: ValueReaders.stringValue(json['display_label']).trim(),
      allowsDiscoveryExpansion: ValueReaders.boolValue(
        json['allows_discovery_expansion'],
      ),
      allowsProjection: ValueReaders.boolValue(json['allows_projection']),
      allowsPromotion: ValueReaders.boolValue(json['allows_promotion']),
      requiresConfirmation: ValueReaders.boolValue(
        json['requires_confirmation'],
      ),
      attachedAt: ValueReaders.stringValue(json['attached_at']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'attachment_id': attachmentId,
      'project_id': projectId,
      'package_id': packageId,
      'package_version_id': packageVersionId,
      'visibility_mode': visibilityMode,
      'access_level': accessLevel,
      'display_label': displayLabel,
      'allows_discovery_expansion': allowsDiscoveryExpansion,
      'allows_projection': allowsProjection,
      'allows_promotion': allowsPromotion,
      'requires_confirmation': requiresConfirmation,
      'attached_at': attachedAt,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _referenceAccessValidatorService.requireNonBlankString(
        attachmentId,
        ReferenceSubstrateValidationCodes.missingReferenceAttachmentId,
      ),
    );
    result.addAll(
      _referenceAccessValidatorService.requireNonBlankString(
        projectId,
        ReferenceSubstrateValidationCodes.missingReferenceAttachmentProjectId,
      ),
    );
    result.addAll(
      _referenceAccessValidatorService.requireNonBlankString(
        packageId,
        ReferenceSubstrateValidationCodes.missingReferencePackageId,
      ),
    );
    result.addAll(
      _referenceAccessValidatorService.requireNonBlankString(
        packageVersionId,
        ReferenceSubstrateValidationCodes.missingReferencePackageVersionId,
      ),
    );
    result.addAll(
      _referenceAccessValidatorService.requireNonBlankString(
        visibilityMode,
        ReferenceSubstrateValidationCodes
            .missingReferenceAttachmentVisibilityMode,
      ),
    );
    result.addAll(
      _referenceAccessValidatorService.requireNonBlankString(
        accessLevel,
        ReferenceSubstrateValidationCodes.missingReferenceAttachmentAccessLevel,
      ),
    );
    return result;
  }
}

class ProjectReferenceAccessRequest {
  const ProjectReferenceAccessRequest({
    required this.projectId,
    required this.packageId,
    required this.operation,
    this.packageVersionId = '',
    this.explicitConfirmationGranted = false,
  });

  final String projectId;
  final String packageId;
  final String packageVersionId;
  final String operation;
  final bool explicitConfirmationGranted;
}

class ProjectReferenceAccessDecision {
  const ProjectReferenceAccessDecision({
    required this.allowed,
    required this.disposition,
    this.reasonCode = '',
    this.attachmentId = '',
    this.visibilityMode = '',
    this.accessLevel = '',
  });

  final bool allowed;
  final String disposition;
  final String reasonCode;
  final String attachmentId;
  final String visibilityMode;
  final String accessLevel;
}
