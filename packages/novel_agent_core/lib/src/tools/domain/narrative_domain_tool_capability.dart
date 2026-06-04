import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import 'domain_tool_contract_typedefs.dart';

class NarrativeDomainToolCapability {
  const NarrativeDomainToolCapability({
    required this.toolName,
    this.displayName = '',
    this.supportedSourceTypes = const <String>[],
    this.supportsPermissionDecision = true,
    this.metadata = const <String, Object?>{},
  });

  final DomainToolName toolName;
  final String displayName;
  final List<String> supportedSourceTypes;
  final bool supportsPermissionDecision;
  final JsonMap metadata;

  bool supportsSource(NarrativeSourceRef source) {
    return supportedSourceTypes.isEmpty ||
        supportedSourceTypes.contains(source.sourceType);
  }

  factory NarrativeDomainToolCapability.fromJson(JsonMap json) {
    return NarrativeDomainToolCapability(
      toolName: ValueReaders.stringValue(json['tool_name']).trim(),
      displayName: ValueReaders.stringValue(json['display_name']).trim(),
      supportedSourceTypes: ValueReaders.stringList(json['supported_sources']),
      supportsPermissionDecision: ValueReaders.boolValue(
        json['supports_permission_decision'],
        true,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'tool_name': toolName,
      'display_name': displayName,
      'supported_sources': supportedSourceTypes,
      'supports_permission_decision': supportsPermissionDecision,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
