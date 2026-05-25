class AgentProfile {
  const AgentProfile({
    required this.id,
    required this.name,
    required this.description,
    this.role = '',
    this.version = '1',
    this.objective = '',
    this.kpis = const <String>[],
    this.canDo = const <String>[],
    this.mustNotDo = const <String>[],
    this.knowledgeSources = const <String>[],
    this.requiredCapabilities = const <String>[],
    this.optionalCapabilities = const <String>[],
    this.outputSchemaPath = '',
    this.outputSchema = const <String, Object?>{},
    this.preferredOutput = '',
    this.shortTermMemoryPolicy = 'conversation_window',
    this.longTermMemoryPaths = const <String>[],
    this.reflectionMode = 'on_demand',
    this.resourceHints = const <String, Object?>{},
    this.source = '',
    this.sourceScope = '',
    this.enabledByDefault = false,
    this.builtinPreset = '',
    this.customizable = true,
    this.stages = const <String>[],
    this.skills = const <String>[],
    this.skillGroups = const <String>[],
    this.memoryPath = '',
    this.providerProfile = 'default',
    this.systemPrompt = '',
    this.operatingManualMarkdown = '',
    this.thinkingSupported = true,
    this.thinkingEnabled = false,
    this.thinkingEffort = 'high',
    this.temperature,
    this.topP,
    this.topK,
    this.advancedModelOverrides = const <Object?>[],
    this.metadata = const <String, Object?>{},
    this.portableCore = const <String, Object?>{},
    this.novelAgentExtensions = const <String, Object?>{},
  });

  final String id;
  final String name;
  final String description;
  final String role;
  final String version;
  final String objective;
  final List<String> kpis;
  final List<String> canDo;
  final List<String> mustNotDo;
  final List<String> knowledgeSources;
  final List<String> requiredCapabilities;
  final List<String> optionalCapabilities;
  final String outputSchemaPath;
  final Map<String, Object?> outputSchema;
  final String preferredOutput;
  final String shortTermMemoryPolicy;
  final List<String> longTermMemoryPaths;
  final String reflectionMode;
  final Map<String, Object?> resourceHints;
  final String source;
  final String sourceScope;
  final bool enabledByDefault;
  final String builtinPreset;
  final bool customizable;
  final List<String> stages;
  final List<String> skills;
  final List<String> skillGroups;
  final String memoryPath;
  final String providerProfile;
  final String systemPrompt;
  final String operatingManualMarkdown;
  final bool thinkingSupported;
  final bool thinkingEnabled;
  final String thinkingEffort;
  final double? temperature;
  final double? topP;
  final int? topK;
  final List<Object?> advancedModelOverrides;
  final Map<String, Object?> metadata;
  final Map<String, Object?> portableCore;
  final Map<String, Object?> novelAgentExtensions;
}
