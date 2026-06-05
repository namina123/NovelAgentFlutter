import '../common/json_types.dart';
import '../common/open_json_structure_validator_service.dart';
import 'information_source_ref.dart';
import 'information_validation_codes.dart';
import 'reference_work_record.dart';

class ReferenceWorkRecordValidator {
  const ReferenceWorkRecordValidator({
    OpenJsonStructureValidatorService? structureValidatorService,
  }) : _structureValidatorService =
           structureValidatorService ??
           const OpenJsonStructureValidatorService();

  final OpenJsonStructureValidatorService _structureValidatorService;

  List<String> validateJson(JsonMap json) {
    return validate(ReferenceWorkRecord.fromJson(json));
  }

  List<String> validate(ReferenceWorkRecord record) {
    final result = <String>[];
    result.addAll(record.validateBasics());
    result.addAll(
      record.sourceRefs.expand(
        (ref) => _validateSourceRef(
          ref,
          InformationValidationCodes.invalidReferenceWorkSourceRef,
        ),
      ),
    );
    return result;
  }

  List<String> _validateSourceRef(InformationSourceRef ref, String code) {
    return _structureValidatorService.requireCondition(
      ref.validateBasics().isEmpty,
      code,
    );
  }
}
