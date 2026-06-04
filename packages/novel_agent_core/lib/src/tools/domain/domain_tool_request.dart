import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import '../../runtime/tool_round_evidence.dart';
import 'domain_tool_contract_typedefs.dart';
import 'domain_tool_validation_codes.dart';

const _domainToolRequestCodecService = OpenJsonContractCodecService();
const _domainToolRequestValidatorService = OpenJsonStructureValidatorService();

class DomainToolRequest {
  const DomainToolRequest({
    required this.callId,
    required this.toolName,
    required this.source,
    this.requestPayload = const <String, Object?>{},
    this.targetRefs = const <NarrativeRef>[],
    this.toolRoundEvidence,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final DomainToolCallId callId;
  final DomainToolName toolName;
  final NarrativeSourceRef source;
  final JsonMap requestPayload;
  final List<NarrativeRef> targetRefs;
  final ToolRoundEvidence? toolRoundEvidence;
  final DomainToolSchemaVersion schemaVersion;
  final JsonMap metadata;

  DomainToolRequest copyWith({
    DomainToolCallId? callId,
    DomainToolName? toolName,
    NarrativeSourceRef? source,
    JsonMap? requestPayload,
    List<NarrativeRef>? targetRefs,
    ToolRoundEvidence? toolRoundEvidence,
    DomainToolSchemaVersion? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: request 合同只承接结构化领域工具输入，不在这里定义具体工具参数含义。
    return DomainToolRequest(
      callId: callId ?? this.callId,
      toolName: toolName ?? this.toolName,
      source: source ?? this.source,
      requestPayload: requestPayload ?? this.requestPayload,
      targetRefs: targetRefs ?? this.targetRefs,
      toolRoundEvidence: toolRoundEvidence ?? this.toolRoundEvidence,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory DomainToolRequest.fromJson(JsonMap json) {
    return DomainToolRequest(
      callId: ValueReaders.stringValue(json['call_id']).trim(),
      toolName: ValueReaders.stringValue(json['tool_name']).trim(),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      requestPayload: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['request_payload']),
      ),
      targetRefs: ValueReaders.mapList(
        json['target_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      toolRoundEvidence:
          ValueReaders.mapValue(json['tool_round_evidence']).isEmpty
          ? null
          : ToolRoundEvidence.fromJson(
              ValueReaders.mapValue(json['tool_round_evidence']),
            ),
      schemaVersion: _domainToolRequestCodecService.readSchemaVersion(json),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'call_id': callId,
      'tool_name': toolName,
      'source': source.toJson(),
      'request_payload': ValueReaders.deepCopyMap(requestPayload),
      'target_refs': targetRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'tool_round_evidence': toolRoundEvidence?.toJson(),
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _domainToolRequestValidatorService.requireNonBlankString(
        callId,
        DomainToolValidationCodes.missingCallId,
      ),
    );
    result.addAll(
      _domainToolRequestValidatorService.requireNonBlankString(
        toolName,
        DomainToolValidationCodes.missingToolName,
      ),
    );
    result.addAll(
      _domainToolRequestValidatorService.requireNonBlankString(
        source.sourceType,
        DomainToolValidationCodes.missingSourceType,
      ),
    );
    return result;
  }
}
