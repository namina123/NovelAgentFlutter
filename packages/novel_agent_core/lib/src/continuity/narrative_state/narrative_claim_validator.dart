import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_ref.dart';
import 'narrative_state_claim.dart';
import 'narrative_state_claim_validation_codes.dart';

class NarrativeClaimValidator {
  const NarrativeClaimValidator({
    OpenJsonStructureValidatorService? structureValidatorService,
  }) : _structureValidatorService =
           structureValidatorService ??
           const OpenJsonStructureValidatorService();

  final OpenJsonStructureValidatorService _structureValidatorService;

  List<String> validateJson(JsonMap json) {
    return validate(NarrativeStateClaim.fromJson(json));
  }

  List<String> validate(NarrativeStateClaim claim) {
    final result = <String>[];
    result.addAll(claim.validateBasics());
    result.addAll(
      claim.affectedRefs.expand(
        (ref) => _validateRef(
          ref,
          NarrativeStateClaimValidationCodes.invalidAffectedRef,
        ),
      ),
    );
    result.addAll(
      claim.contextRefs.expand(
        (ref) => _validateRef(
          ref,
          NarrativeStateClaimValidationCodes.invalidContextRef,
        ),
      ),
    );
    result.addAll(
      claim.evidenceRefs.expand(
        (ref) => _validateEvidenceRef(
          ref,
          NarrativeStateClaimValidationCodes.invalidEvidenceRef,
        ),
      ),
    );
    return result;
  }

  List<String> _validateRef(NarrativeRef ref, String code) {
    return _structureValidatorService.requireCondition(
      ref.refType.trim().isNotEmpty && ref.refId.trim().isNotEmpty,
      code,
    );
  }

  List<String> _validateEvidenceRef(NarrativeEvidenceRef ref, String code) {
    if (ref.evidenceType.trim().isEmpty || ref.evidenceId.trim().isEmpty) {
      return <String>[code];
    }
    if (ref.targetRef != null) {
      final targetErrors = _validateRef(ref.targetRef!, code);
      if (targetErrors.isNotEmpty) {
        return targetErrors;
      }
    }
    if (ref.textSpan != null && ref.textSpan!.targetRef.refId.trim().isEmpty) {
      return <String>[code];
    }
    if (ref.sourceRef != null && ref.sourceRef!.sourceType.trim().isEmpty) {
      return <String>[code];
    }
    return const <String>[];
  }
}
