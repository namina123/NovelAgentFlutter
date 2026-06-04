import '../../common/json_types.dart';

class NarrativeDomainToolDefinition {
  const NarrativeDomainToolDefinition({
    required this.toolName,
    required this.displayName,
    required this.description,
    required this.parametersSchema,
  });

  final String toolName;
  final String displayName;
  final String description;
  final JsonMap parametersSchema;

  JsonMap toOpenAiSchema() {
    return <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': toolName,
        'description': description,
        'parameters': parametersSchema,
      },
    };
  }
}
