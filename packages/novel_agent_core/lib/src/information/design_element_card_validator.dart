import '../common/json_types.dart';
import '../common/open_json_structure_validator_service.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'design_element_card.dart';
import 'information_source_ref.dart';
import 'information_validation_codes.dart';

class DesignElementCardValidator {
  const DesignElementCardValidator({
    OpenJsonStructureValidatorService? structureValidatorService,
  }) : _structureValidatorService =
           structureValidatorService ??
           const OpenJsonStructureValidatorService();

  final OpenJsonStructureValidatorService _structureValidatorService;

  List<String> validateJson(JsonMap json) {
    return validate(DesignElementCard.fromJson(json));
  }

  List<String> validate(DesignElementCard card) {
    final result = <String>[];
    result.addAll(card.validateBasics());
    result.addAll(
      card.sourceRefs.expand(
        (ref) => _validateSourceRef(
          ref,
          InformationValidationCodes.invalidDesignElementSourceRef,
        ),
      ),
    );
    result.addAll(
      card.evidenceRefs.expand(
        (ref) => _validateEvidenceRef(
          ref,
          InformationValidationCodes.invalidDesignElementEvidenceRef,
        ),
      ),
    );
    result.addAll(
      card.scopeRefs.expand(
        (ref) => _validateRef(
          ref,
          InformationValidationCodes.invalidDesignElementScopeRef,
        ),
      ),
    );
    result.addAll(
      card.linkedRefs.expand(
        (ref) => _validateRef(
          ref,
          InformationValidationCodes.invalidDesignElementLinkedRef,
        ),
      ),
    );
    return result;
  }

  List<String> _validateSourceRef(InformationSourceRef ref, String code) {
    if (ref.validateBasics().isNotEmpty) {
      return <String>[code];
    }
    return const <String>[];
  }

  List<String> _validateEvidenceRef(NarrativeEvidenceRef ref, String code) {
    if (ref.evidenceType.trim().isEmpty || ref.evidenceId.trim().isEmpty) {
      return <String>[code];
    }
    if (ref.targetRef != null &&
        _validateRef(ref.targetRef!, code).isNotEmpty) {
      return <String>[code];
    }
    if (ref.textSpan != null && ref.textSpan!.targetRef.refId.trim().isEmpty) {
      return <String>[code];
    }
    if (ref.sourceRef != null && ref.sourceRef!.sourceType.trim().isEmpty) {
      return <String>[code];
    }
    return const <String>[];
  }

  List<String> _validateRef(NarrativeRef ref, String code) {
    return _structureValidatorService.requireCondition(
      ref.refType.trim().isNotEmpty && ref.refId.trim().isNotEmpty,
      code,
    );
  }
}
