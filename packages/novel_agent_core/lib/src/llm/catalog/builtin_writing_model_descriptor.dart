import 'writing_model_provider_offering_override.dart';
import 'writing_model_reasoning_descriptor.dart';

class BuiltinWritingModelDescriptor {
  const BuiltinWritingModelDescriptor({
    required this.canonicalModelId,
    required this.vendorId,
    required this.vendorLabel,
    required this.family,
    required this.snapshot,
    required this.displayName,
    this.aliases = const <String>[],
    this.providerOfferings = const <WritingModelProviderOfferingOverride>[],
    this.contextLength = 100000,
    this.compressionContextLength = 80000,
    this.maxOutputTokens = 65536,
    this.supportsTemperature = true,
    this.supportsTopP = true,
    this.supportsStreaming = true,
    this.supportsTools = true,
    this.supportsToolChoice = false,
    this.supportsFileAttachments = false,
    this.supportsImageAttachments = false,
    this.supportsAttachmentUrlsOnly = false,
    this.supportsMultiAttachments = false,
    this.supportedParameters = const <String>[],
    this.unsupportedParameters = const <String>[],
    this.reasoning = const WritingModelReasoningDescriptor(supported: false),
    this.status = 'active',
    this.notes = '',
  });

  final String canonicalModelId;
  final String vendorId;
  final String vendorLabel;
  final String family;
  final String snapshot;
  final String displayName;
  final List<String> aliases;
  final List<WritingModelProviderOfferingOverride> providerOfferings;
  final int contextLength;
  final int compressionContextLength;
  final int maxOutputTokens;
  final bool supportsTemperature;
  final bool supportsTopP;
  final bool supportsStreaming;
  final bool supportsTools;
  final bool supportsToolChoice;
  final bool supportsFileAttachments;
  final bool supportsImageAttachments;
  final bool supportsAttachmentUrlsOnly;
  final bool supportsMultiAttachments;
  final List<String> supportedParameters;
  final List<String> unsupportedParameters;
  final WritingModelReasoningDescriptor reasoning;
  final String status;
  final String notes;
}
