import '../common/json_types.dart';
import '../common/open_json_structure_validator_service.dart';
import '../continuity/narrative_state/narrative_evidence_ref.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'information_source_ref.dart';
import 'information_validation_codes.dart';
import 'project_knowledge_card.dart';

class ProjectKnowledgeCardValidator {
  const ProjectKnowledgeCardValidator({
    OpenJsonStructureValidatorService? structureValidatorService,
  }) : _structureValidatorService =
           structureValidatorService ??
           const OpenJsonStructureValidatorService();

  final OpenJsonStructureValidatorService _structureValidatorService;

  List<String> validateJson(JsonMap json) {
    return validate(ProjectKnowledgeCard.fromJson(json));
  }

  List<String> validate(ProjectKnowledgeCard card) {
    final result = <String>[];
    result.addAll(card.validateBasics());
    result.addAll(
      card.sourceRefs.expand(
        (ref) => _validateSourceRef(
          ref,
          InformationValidationCodes.invalidKnowledgeCardSourceRef,
        ),
      ),
    );
    result.addAll(
      card.evidenceRefs.expand(
        (ref) => _validateEvidenceRef(
          ref,
          InformationValidationCodes.invalidKnowledgeCardEvidenceRef,
        ),
      ),
    );
    result.addAll(
      card.scopeRefs.expand(
        (ref) => _validateScopeRef(
          ref,
          InformationValidationCodes.invalidKnowledgeCardScopeRef,
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
        _validateScopeRef(ref.targetRef!, code).isNotEmpty) {
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

  List<String> _validateScopeRef(NarrativeRef ref, String code) {
    return _structureValidatorService.requireCondition(
      ref.refType.trim().isNotEmpty && ref.refId.trim().isNotEmpty,
      code,
    );
  }
}
