import 'reference_access_models.dart';
import 'reference_substrate_constants.dart';
import 'reference_substrate_validation_codes.dart';

class ProjectReferenceAccessPolicyService {
  const ProjectReferenceAccessPolicyService();

  ProjectReferenceAccessDecision decide({
    required ProjectReferenceAccessRequest request,
    required ProjectReferenceAttachment? attachment,
  }) {
    if (request.operation.trim().isEmpty) {
      return const ProjectReferenceAccessDecision(
        allowed: false,
        disposition: ReferenceAccessDispositions.denied,
        reasonCode:
            ReferenceSubstrateValidationCodes.missingReferenceAccessOperation,
      );
    }
    if (attachment == null) {
      return const ProjectReferenceAccessDecision(
        allowed: false,
        disposition: ReferenceAccessDispositions.hidden,
        reasonCode: 'attachment_missing',
      );
    }
    if (request.packageVersionId.trim().isNotEmpty &&
        request.packageVersionId.trim() != attachment.packageVersionId) {
      return _decision(
        attachment,
        allowed: false,
        disposition: ReferenceAccessDispositions.denied,
        reasonCode: 'package_version_not_attached',
      );
    }
    if (attachment.requiresConfirmation &&
        !request.explicitConfirmationGranted &&
        request.operation != ReferenceAccessOperations.discoverPackage) {
      return _decision(
        attachment,
        allowed: false,
        disposition: ReferenceAccessDispositions.confirmationRequired,
        reasonCode: 'explicit_confirmation_required',
      );
    }
    switch (request.operation) {
      case ReferenceAccessOperations.discoverPackage:
        return _decideDiscover(attachment);
      case ReferenceAccessOperations.readPackageSummary:
        return _allowIf(
          attachment,
          attachment.accessLevel != ReferenceAccessLevels.none,
          'summary_access_denied',
        );
      case ReferenceAccessOperations.readEntry:
        return _allowIf(
          attachment,
          attachment.accessLevel == ReferenceAccessLevels.readOnly ||
              attachment.accessLevel == ReferenceAccessLevels.projectable ||
              attachment.accessLevel == ReferenceAccessLevels.manager,
          'entry_read_denied',
        );
      case ReferenceAccessOperations.projectEntry:
        return _allowIf(
          attachment,
          attachment.allowsProjection &&
              (attachment.accessLevel == ReferenceAccessLevels.projectable ||
                  attachment.accessLevel == ReferenceAccessLevels.manager),
          'projection_denied',
        );
      case ReferenceAccessOperations.promoteProjectInformation:
        return _allowIf(
          attachment,
          attachment.allowsPromotion &&
              attachment.accessLevel == ReferenceAccessLevels.manager,
          'promotion_denied',
        );
      default:
        return _decision(
          attachment,
          allowed: false,
          disposition: ReferenceAccessDispositions.denied,
          reasonCode: 'unknown_operation',
        );
    }
  }

  ProjectReferenceAccessDecision _decideDiscover(
    ProjectReferenceAttachment attachment,
  ) {
    if (attachment.visibilityMode == ReferenceVisibilityModes.hidden ||
        attachment.accessLevel == ReferenceAccessLevels.none) {
      return _decision(
        attachment,
        allowed: false,
        disposition: ReferenceAccessDispositions.hidden,
        reasonCode: 'package_hidden',
      );
    }
    return _decision(
      attachment,
      allowed: true,
      disposition: ReferenceAccessDispositions.allowed,
    );
  }

  ProjectReferenceAccessDecision _allowIf(
    ProjectReferenceAttachment attachment,
    bool condition,
    String reasonCode,
  ) {
    return _decision(
      attachment,
      allowed: condition,
      disposition: condition
          ? ReferenceAccessDispositions.allowed
          : ReferenceAccessDispositions.denied,
      reasonCode: condition ? '' : reasonCode,
    );
  }

  ProjectReferenceAccessDecision _decision(
    ProjectReferenceAttachment attachment, {
    required bool allowed,
    required String disposition,
    String reasonCode = '',
  }) {
    return ProjectReferenceAccessDecision(
      allowed: allowed,
      disposition: disposition,
      reasonCode: reasonCode,
      attachmentId: attachment.attachmentId,
      visibilityMode: attachment.visibilityMode,
      accessLevel: attachment.accessLevel,
    );
  }
}
