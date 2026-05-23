class BuiltinToolDefinition {
  const BuiltinToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.platformPolicy = 'mobile_safe_if_project_scoped',
    this.enabledByDefault = true,
  });

  final String id;
  final String name;
  final String description;
  final String platformPolicy;
  final bool enabledByDefault;
}
