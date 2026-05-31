final class ProviderProfileConstants {
  static const String kindOpenAiCompatible = 'openai_compatible';
  static const String kindAnthropicCompatible = 'anthropic_compatible';
  static const int defaultContextLength = 100000;
  static const int defaultCompressionContextLength = 80000;
  static const int defaultMaxOutputTokens = 65536;
  static const double defaultTemperature = 0.8;
  static const double defaultTopP = 0.95;
  static const int defaultTopK = 0;
  static const bool defaultStreamingEnabled = true;
  static const bool defaultSupportsToolChoice = false;
  static const bool defaultSupportsFileAttachments = false;
  static const bool defaultSupportsImageAttachments = false;
  static const bool defaultSupportsAttachmentUrlsOnly = false;
  static const bool defaultSupportsMultiAttachments = false;
  static const String thinkingFormatNone = 'none';
  static const String thinkingFormatDeepseekObject = 'deepseek_thinking_object';
  static const String thinkingFormatEnableBoolean = 'enable_thinking_boolean';
  static const String thinkingFormatEnableBooleanWithEffort =
      'enable_thinking_with_reasoning_effort';
  static const String thinkingFormatReasoningEffortOnly =
      'reasoning_effort_only';
  static const String thinkingEffortAuto = 'auto';
  static const List<String> customParameterTypes = <String>[
    'string',
    'number',
    'integer',
    'boolean',
    'json',
  ];
  static const List<String> thinkingEfforts = <String>[
    'auto',
    'low',
    'medium',
    'high',
    'max',
  ];
  static const List<String> capabilityKeys = <String>[
    'supports_streaming',
    'supports_tools',
    'supports_tool_choice',
    'supports_image_generation',
    'supports_file_attachments',
    'supports_image_attachments',
    'supports_attachment_urls_only',
    'supports_multi_attachments',
  ];
}
