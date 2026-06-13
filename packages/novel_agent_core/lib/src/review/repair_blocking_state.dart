import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'repair_contract_catalog.dart';

const _repairBlockingStateCodecService = OpenJsonContractCodecService();
const _repairBlockingStateValidatorService =
    OpenJsonStructureValidatorService();
const _repairBlockingStateKnownFields = <String>{
  'blocks_main_flow',
  'reason',
  'waiting_user',
  'manual_attention_required',
  'resolved',
  'metadata',
};

class RepairBlockingState {
  const RepairBlockingState({
    required this.blocksMainFlow,
    required this.reason,
    this.waitingUser = false,
    this.manualAttentionRequired = false,
    this.resolved = false,
    this.metadata = const <String, Object?>{},
  });

  final bool blocksMainFlow;
  final String reason;
  final bool waitingUser;
  final bool manualAttentionRequired;
  final bool resolved;
  final JsonMap metadata;

  factory RepairBlockingState.fromJson(JsonMap json) {
    return RepairBlockingState(
      blocksMainFlow: ValueReaders.boolValue(json['blocks_main_flow']),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      waitingUser: ValueReaders.boolValue(json['waiting_user']),
      manualAttentionRequired: ValueReaders.boolValue(
        json['manual_attention_required'],
      ),
      resolved: ValueReaders.boolValue(json['resolved']),
      metadata: _repairBlockingStateCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _repairBlockingStateKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _repairBlockingStateCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'blocks_main_flow': blocksMainFlow,
        'reason': reason,
        'waiting_user': waitingUser,
        'manual_attention_required': manualAttentionRequired,
        'resolved': resolved,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    return _repairBlockingStateValidatorService.requireCondition(
      reason.trim().isNotEmpty || !blocksMainFlow || resolved,
      RepairContractValidationCodes.invalidRepairBlockingResolution,
    );
  }
}
