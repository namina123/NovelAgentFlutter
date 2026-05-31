class CustomModelReasoningOverrideViewData {
  const CustomModelReasoningOverrideViewData({
    required this.isKnownWritingModel,
    required this.supportsReasoning,
    required this.reasoningCanToggle,
    required this.reasoningDefaultEnabled,
    required this.reasoningSupportsEffort,
    required this.toggleStrategyKind,
    required this.toggleKey,
    required this.toggleEnabledValue,
    required this.toggleDisabledValue,
    required this.effortKey,
    required this.effortValues,
  });

  final bool isKnownWritingModel;
  final bool supportsReasoning;
  final bool reasoningCanToggle;
  final bool reasoningDefaultEnabled;
  final bool reasoningSupportsEffort;
  final String toggleStrategyKind;
  final String toggleKey;
  final String toggleEnabledValue;
  final String toggleDisabledValue;
  final String effortKey;
  final Map<String, String> effortValues;

  bool get showCustomOverrideEditor => !isKnownWritingModel;

  static const CustomModelReasoningOverrideViewData initial =
      CustomModelReasoningOverrideViewData(
        isKnownWritingModel: true,
        supportsReasoning: false,
        reasoningCanToggle: true,
        reasoningDefaultEnabled: false,
        reasoningSupportsEffort: false,
        toggleStrategyKind: 'boolean',
        toggleKey: 'enable_thinking',
        toggleEnabledValue: 'true',
        toggleDisabledValue: 'false',
        effortKey: 'reasoning_effort',
        effortValues: <String, String>{
          'auto': 'auto',
          'low': 'low',
          'medium': 'medium',
          'high': 'high',
          'max': 'max',
        },
      );
}
