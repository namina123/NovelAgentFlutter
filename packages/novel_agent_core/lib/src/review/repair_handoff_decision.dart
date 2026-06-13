import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/value_readers.dart';
import 'repair_contract_catalog.dart';
import 'repair_request.dart';

const _repairHandoffDecisionCodecService = OpenJsonContractCodecService();
const _repairHandoffDecisionKnownFields = <String>{
  'action',
  'reason',
  'blocks_main_flow',
  'requires_repair_task',
  'note',
  'repair_request',
  'metadata',
};

class RepairHandoffDecision {
  const RepairHandoffDecision({
    required this.action,
    required this.reason,
    this.blocksMainFlow = false,
    this.requiresRepairTask = false,
    this.note = '',
    this.repairRequest,
    this.metadata = const <String, Object?>{},
  });

  final String action;
  final String reason;
  final bool blocksMainFlow;
  final bool requiresRepairTask;
  final String note;
  final RepairRequest? repairRequest;
  final JsonMap metadata;

  factory RepairHandoffDecision.fromJson(JsonMap json) {
    final repairRequestJson = ValueReaders.mapValue(json['repair_request']);
    return RepairHandoffDecision(
      action: ValueReaders.stringValue(json['action']).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      blocksMainFlow: ValueReaders.boolValue(json['blocks_main_flow']),
      requiresRepairTask: ValueReaders.boolValue(json['requires_repair_task']),
      note: ValueReaders.stringValue(json['note']).trim(),
      repairRequest: repairRequestJson.isEmpty
          ? null
          : RepairRequest.fromJson(repairRequestJson),
      metadata: _repairHandoffDecisionCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _repairHandoffDecisionKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _repairHandoffDecisionCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'action': action,
        'reason': reason,
        'blocks_main_flow': blocksMainFlow,
        'requires_repair_task': requiresRepairTask,
        'note': note,
        'repair_request': repairRequest?.toJson() ?? <String, Object?>{},
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (!RepairHandoffActions.knownValues.contains(action)) {
      result.add(RepairContractValidationCodes.invalidRepairHandoffAction);
    }
    if (requiresRepairTask && repairRequest == null) {
      result.add(RepairContractValidationCodes.repairHandoffRequiresRequest);
    }
    if (repairRequest != null) {
      result.addAll(repairRequest!.validateBasics());
    }
    return result;
  }
}
