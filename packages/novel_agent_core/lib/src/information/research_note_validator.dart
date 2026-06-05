import '../common/json_types.dart';
import '../common/open_json_structure_validator_service.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'information_validation_codes.dart';
import 'research_note.dart';

class ResearchNoteValidator {
  const ResearchNoteValidator({
    OpenJsonStructureValidatorService? structureValidatorService,
  }) : _structureValidatorService =
           structureValidatorService ??
           const OpenJsonStructureValidatorService();

  final OpenJsonStructureValidatorService _structureValidatorService;

  List<String> validateJson(JsonMap json) {
    return validate(ResearchNote.fromJson(json));
  }

  List<String> validate(ResearchNote note) {
    final result = <String>[];
    result.addAll(note.validateBasics());
    result.addAll(
      note.linkedCards.expand(
        (ref) => _validateLinkedCardRef(
          ref,
          InformationValidationCodes.invalidResearchNoteLinkedCardRef,
        ),
      ),
    );
    return result;
  }

  List<String> _validateLinkedCardRef(NarrativeRef ref, String code) {
    return _structureValidatorService.requireCondition(
      ref.refType.trim().isNotEmpty && ref.refId.trim().isNotEmpty,
      code,
    );
  }
}
