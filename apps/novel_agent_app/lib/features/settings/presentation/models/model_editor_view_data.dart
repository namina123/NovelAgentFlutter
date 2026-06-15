import 'custom_model_reasoning_override_view_data.dart';
import 'model_parameter_entry_view_data.dart';
import 'settings_search_option.dart';

class ModelEditorViewData {
  const ModelEditorViewData({
    required this.providerId,
    required this.providerLabel,
    required this.protocolMode,
    required this.baseUrl,
    required this.modelId,
    required this.supportsReasoning,
    required this.reasoningCanToggle,
    required this.reasoningDefaultEnabled,
    required this.supportsTemperature,
    required this.supportsTopP,
    required this.supportsTopK,
    required this.supportsStreaming,
    required this.supportsTools,
    required this.supportsToolChoice,
    required this.supportsFileAttachments,
    required this.supportsImageAttachments,
    required this.supportsAttachmentUrlsOnly,
    required this.supportsMultiAttachments,
    required this.thinkingParameterFormat,
    required this.thinkingParameterLabel,
    required this.thinkingEnabled,
    required this.thinkingEffortSupported,
    required this.thinkingEffortParameterLabel,
    required this.thinkingEffort,
    required this.thinkingEffortOptions,
    required this.temperature,
    required this.topP,
    required this.topK,
    required this.modelSuggestions,
    required this.customParameters,
    required this.supportedParameters,
    required this.unsupportedParameters,
    required this.customReasoningOverride,
  });

  final String providerId;
  final String providerLabel;
  final String protocolMode;
  final String baseUrl;
  final String modelId;
  final bool supportsReasoning;
  final bool reasoningCanToggle;
  final bool reasoningDefaultEnabled;
  final bool supportsTemperature;
  final bool supportsTopP;
  final bool supportsTopK;
  final bool supportsStreaming;
  final bool supportsTools;
  final bool supportsToolChoice;
  final bool supportsFileAttachments;
  final bool supportsImageAttachments;
  final bool supportsAttachmentUrlsOnly;
  final bool supportsMultiAttachments;
  final String thinkingParameterFormat;
  final String thinkingParameterLabel;
  final bool thinkingEnabled;
  final bool thinkingEffortSupported;
  final String thinkingEffortParameterLabel;
  final String thinkingEffort;
  final List<String> thinkingEffortOptions;
  final double temperature;
  final double topP;
  final int topK;
  final List<SettingsSearchOption<String>> modelSuggestions;
  final List<ModelParameterEntryViewData> customParameters;
  final List<String> supportedParameters;
  final List<String> unsupportedParameters;
  final CustomModelReasoningOverrideViewData customReasoningOverride;

  static const ModelEditorViewData initial = ModelEditorViewData(
    providerId: '',
    providerLabel: '',
    protocolMode: 'openai_compatible',
    baseUrl: '',
    modelId: '',
    supportsReasoning: false,
    reasoningCanToggle: false,
    reasoningDefaultEnabled: false,
    supportsTemperature: true,
    supportsTopP: true,
    supportsTopK: false,
    supportsStreaming: true,
    supportsTools: true,
    supportsToolChoice: false,
    supportsFileAttachments: false,
    supportsImageAttachments: false,
    supportsAttachmentUrlsOnly: false,
    supportsMultiAttachments: false,
    thinkingParameterFormat: 'none',
    thinkingParameterLabel: '深度思考',
    thinkingEnabled: false,
    thinkingEffortSupported: false,
    thinkingEffortParameterLabel: '深度思考强度',
    thinkingEffort: 'high',
    thinkingEffortOptions: <String>[],
    temperature: 0.8,
    topP: 0.95,
    topK: 0,
    modelSuggestions: <SettingsSearchOption<String>>[],
    customParameters: <ModelParameterEntryViewData>[],
    supportedParameters: <String>[],
    unsupportedParameters: <String>[],
    customReasoningOverride: CustomModelReasoningOverrideViewData.initial,
  );
}
