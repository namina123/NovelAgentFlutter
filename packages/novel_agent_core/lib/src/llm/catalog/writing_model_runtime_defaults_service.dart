import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../profile/provider_profile_constants.dart';
import 'writing_model_offering_catalog_service.dart';

class WritingModelRuntimeDefaultsService {
  WritingModelRuntimeDefaultsService({
    WritingModelOfferingCatalogService? offeringCatalogService,
  }) : _offeringCatalogService =
           offeringCatalogService ?? WritingModelOfferingCatalogService();

  final WritingModelOfferingCatalogService _offeringCatalogService;

  JsonMap resolveDefaults({
    required String providerId,
    required String modelId,
    required String credentialId,
  }) {
    final matched = _offeringCatalogService.bestMatch(
      providerId: providerId,
      modelId: modelId,
    );
    if (matched == null) {
      return <String, Object?>{};
    }
    final supported = ValueReaders.stringList(
      matched['supported_parameters_override'],
    );
    return <String, Object?>{
      'matched_writing_model_offering': matched,
      'matched_writing_model_canonical_id': ValueReaders.stringValue(
        matched['canonical_model_id'],
      ),
      'name': ValueReaders.stringValue(
        matched['display_label'],
        ValueReaders.stringValue(matched['model_id']),
      ),
      'purpose': '通用创作',
      'credential_id': credentialId,
      'kind': ProviderProfileConstants.kindOpenAiCompatible,
      'model': ValueReaders.stringValue(matched['model_id']),
      'context_length': ValueReaders.intValue(matched['context_length'], 100000),
      'compression_context_length': ValueReaders.intValue(
        matched['compression_context_length'],
        80000,
      ),
      'max_output_tokens': ValueReaders.intValue(
        matched['max_output_tokens'],
        65536,
      ),
      'supported_parameters': supported.isNotEmpty
          ? supported
          : ValueReaders.stringList(matched['supported_parameters']),
      'unsupported_parameters': supported.isNotEmpty
          ? const <String>[]
          : ValueReaders.stringList(matched['unsupported_parameters']),
      'supports_temperature': ValueReaders.boolValue(
        matched['supports_temperature'],
        supported.isEmpty || supported.contains('temperature'),
      ),
      'supports_top_p': ValueReaders.boolValue(
        matched['supports_top_p'],
        supported.isEmpty || supported.contains('top_p'),
      ),
      'supports_tools': ValueReaders.boolValue(
        matched['supports_tools'],
        supported.isEmpty || supported.contains('tools'),
      ),
      'supports_streaming': ValueReaders.boolValue(
        matched['supports_streaming'],
        true,
      ),
      'supports_tool_choice': ValueReaders.boolValue(
        matched['supports_tool_choice'],
      ),
      'supports_file_attachments': ValueReaders.boolValue(
        matched['supports_file_attachments'],
      ),
      'supports_image_attachments': ValueReaders.boolValue(
        matched['supports_image_attachments'],
      ),
      'supports_attachment_urls_only': ValueReaders.boolValue(
        matched['supports_attachment_urls_only'],
      ),
      'supports_multi_attachments': ValueReaders.boolValue(
        matched['supports_multi_attachments'],
      ),
    };
  }

  JsonMap parameterSummary(JsonMap defaults) {
    return <String, Object?>{
      'supported_parameters': ValueReaders.stringList(
        defaults['supported_parameters'],
      ),
      'unsupported_parameters': ValueReaders.stringList(
        defaults['unsupported_parameters'],
      ),
    };
  }
}
