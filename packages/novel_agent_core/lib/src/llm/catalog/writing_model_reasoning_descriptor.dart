class WritingModelReasoningDescriptor {
  const WritingModelReasoningDescriptor({
    required this.supported,
    this.modeBehavior = 'unsupported',
    this.canToggle = false,
    this.defaultEnabled = false,
    this.supportsEffort = false,
    this.effortOptions = const <String>[],
    this.defaultEffort = '',
    this.toggleParameterStrategy = const <String, Object?>{},
    this.effortParameterStrategy = const <String, Object?>{},
  });

  final bool supported;
  final String modeBehavior;
  final bool canToggle;
  final bool defaultEnabled;
  final bool supportsEffort;
  final List<String> effortOptions;
  final String defaultEffort;
  final Map<String, Object?> toggleParameterStrategy;
  final Map<String, Object?> effortParameterStrategy;
}
