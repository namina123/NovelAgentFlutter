import 'tool_platform_policy.dart';

class BuiltinToolDefinition {
  const BuiltinToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.platformPolicy = ToolPlatformPolicy.mobileSafeIfProjectScoped,
    this.enabledByDefault = true,
  });

  final String id;
  final String name;
  final String description;
  final String platformPolicy;
  final bool enabledByDefault;
}
