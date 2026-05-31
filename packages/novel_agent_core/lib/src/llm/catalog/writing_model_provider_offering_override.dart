class WritingModelProviderOfferingOverride {
  const WritingModelProviderOfferingOverride({
    required this.providerId,
    required this.providerLabel,
    required this.providerModelId,
    this.baseUrlHint = '',
    this.reasoningOverride = const <String, Object?>{},
    this.supportedParametersOverride = const <String>[],
    this.notes = '',
  });

  final String providerId;
  final String providerLabel;
  final String providerModelId;
  final String baseUrlHint;
  final Map<String, Object?> reasoningOverride;
  final List<String> supportedParametersOverride;
  final String notes;
}
