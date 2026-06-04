import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import 'narrative_profile_proposal.dart';
import 'narrative_profile_validation_codes.dart';

class NarrativeProfileProposalValidator {
  const NarrativeProfileProposalValidator({
    OpenJsonStructureValidatorService? structureValidatorService,
  }) : _structureValidatorService =
           structureValidatorService ??
           const OpenJsonStructureValidatorService();

  final OpenJsonStructureValidatorService _structureValidatorService;

  List<String> validateJson(JsonMap json) {
    return validate(NarrativeProfileProposal.fromJson(json));
  }

  List<String> validate(NarrativeProfileProposal proposal) {
    final result = <String>[];
    result.addAll(proposal.validateBasics());
    result.addAll(
      _structureValidatorService.requireCondition(
        proposal.profilePatch.patchPayload.isNotEmpty ||
            proposal.profilePatch.patchExtensions.isNotEmpty,
        NarrativeProfileValidationCodes.missingPatchContent,
      ),
    );
    return result;
  }
}
