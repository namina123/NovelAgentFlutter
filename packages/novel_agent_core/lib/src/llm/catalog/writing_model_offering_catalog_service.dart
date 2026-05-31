import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'builtin_writing_model_catalog_service.dart';
import 'builtin_writing_model_descriptor.dart';
import 'writing_model_provider_offering_override.dart';

class WritingModelOfferingCatalogService {
  WritingModelOfferingCatalogService({
    BuiltinWritingModelCatalogService? catalogService,
  }) : _catalogService =
           catalogService ?? BuiltinWritingModelCatalogService.seeded();

  final BuiltinWritingModelCatalogService _catalogService;

  List<JsonMap> offeringOptions({
    String query = '',
    String providerId = '',
    int limit = 200,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final cleanProviderId = providerId.trim();
    final scored = <JsonMap>[];
    for (final model in _catalogService.models()) {
      final baseEntry = _canonicalOption(model);
      final baseScore = _offeringScore(
        entry: baseEntry,
        query: cleanQuery,
        providerId: cleanProviderId,
      );
      if (baseScore > 0 || (cleanQuery.isEmpty && cleanProviderId.isEmpty)) {
        final item = ValueReaders.deepCopyMap(baseEntry);
        item['score'] = baseScore > 0 ? baseScore : 1;
        scored.add(item);
      }
      for (final offering in model.providerOfferings) {
        final entry = _offeringOption(model, offering);
        final score = _offeringScore(
          entry: entry,
          query: cleanQuery,
          providerId: cleanProviderId,
        );
        if (score <= 0 && !(cleanQuery.isEmpty && cleanProviderId.isEmpty)) {
          continue;
        }
        final item = ValueReaders.deepCopyMap(entry);
        item['score'] = score > 0 ? score : 1;
        scored.add(item);
      }
    }
    scored.sort((a, b) {
      return ValueReaders.intValue(
        b['score'],
      ).compareTo(ValueReaders.intValue(a['score']));
    });
    final seen = <String>{};
    final deduped = <JsonMap>[];
    for (final item in scored) {
      final key =
          '${ValueReaders.stringValue(item['provider_id'])}::${ValueReaders.stringValue(item['model_id'])}';
      if (!seen.add(key)) {
        continue;
      }
      deduped.add(ValueReaders.deepCopyMap(item));
      if (deduped.length >= limit) {
        break;
      }
    }
    return deduped;
  }

  JsonMap? bestMatch({
    required String modelId,
    String providerId = '',
  }) {
    final cleanModelId = modelId.trim();
    if (cleanModelId.isEmpty) {
      return null;
    }
    final candidates = offeringOptions(
      query: cleanModelId,
      providerId: providerId,
      limit: 16,
    );
    for (final item in candidates) {
      final currentId = ValueReaders.stringValue(item['model_id']).toLowerCase();
      if (currentId == cleanModelId.toLowerCase()) {
        return item;
      }
    }
    if (candidates.isEmpty) {
      return null;
    }
    return ValueReaders.intValue(candidates.first['score']) >= 80
        ? candidates.first
        : null;
  }

  JsonMap? offeringByProviderModelId({
    required String providerId,
    required String modelId,
  }) {
    final cleanProviderId = providerId.trim();
    final cleanModelId = modelId.trim().toLowerCase();
    if (cleanProviderId.isEmpty || cleanModelId.isEmpty) {
      return null;
    }
    for (final model in _catalogService.models()) {
      for (final offering in model.providerOfferings) {
        if (offering.providerId == cleanProviderId &&
            offering.providerModelId.trim().toLowerCase() == cleanModelId) {
          return _offeringOption(model, offering);
        }
      }
    }
    return null;
  }

  JsonMap? canonicalByAlias(String query) {
    final matched = _catalogService.matchByAlias(query);
    if (matched == null) {
      return null;
    }
    return _canonicalOption(matched);
  }

  JsonMap _canonicalOption(BuiltinWritingModelDescriptor model) {
    return <String, Object?>{
      'provider_id': '',
      'provider_label': model.vendorLabel,
      'model_id': model.displayName,
      'display_label': model.displayName,
      'canonical_model_id': model.canonicalModelId,
      'vendor_id': model.vendorId,
      'vendor_label': model.vendorLabel,
      'status': model.status,
      'source_kind': 'canonical',
      'aliases': model.aliases,
      'base_url_hint': '',
      'context_length': model.contextLength,
      'compression_context_length': model.compressionContextLength,
      'max_output_tokens': model.maxOutputTokens,
      'supports_temperature': model.supportsTemperature,
      'supports_top_p': model.supportsTopP,
      'supports_streaming': model.supportsStreaming,
      'supports_tools': model.supportsTools,
      'supports_tool_choice': model.supportsToolChoice,
      'supports_file_attachments': model.supportsFileAttachments,
      'supports_image_attachments': model.supportsImageAttachments,
      'supports_attachment_urls_only': model.supportsAttachmentUrlsOnly,
      'supports_multi_attachments': model.supportsMultiAttachments,
      'supported_parameters': model.supportedParameters,
      'unsupported_parameters': model.unsupportedParameters,
      'notes': model.notes,
    };
  }

  JsonMap _offeringOption(
    BuiltinWritingModelDescriptor model,
    WritingModelProviderOfferingOverride offering,
  ) {
    return <String, Object?>{
      'provider_id': offering.providerId,
      'provider_label': offering.providerLabel,
      'model_id': offering.providerModelId,
      'display_label': model.displayName,
      'canonical_model_id': model.canonicalModelId,
      'vendor_id': model.vendorId,
      'vendor_label': model.vendorLabel,
      'status': model.status,
      'source_kind': 'provider_offering',
      'aliases': model.aliases,
      'base_url_hint': offering.baseUrlHint,
      'context_length': model.contextLength,
      'compression_context_length': model.compressionContextLength,
      'max_output_tokens': model.maxOutputTokens,
      'supports_temperature': model.supportsTemperature,
      'supports_top_p': model.supportsTopP,
      'supports_streaming': model.supportsStreaming,
      'supports_tools': model.supportsTools,
      'supports_tool_choice': model.supportsToolChoice,
      'supports_file_attachments': model.supportsFileAttachments,
      'supports_image_attachments': model.supportsImageAttachments,
      'supports_attachment_urls_only': model.supportsAttachmentUrlsOnly,
      'supports_multi_attachments': model.supportsMultiAttachments,
      'supported_parameters': model.supportedParameters,
      'unsupported_parameters': model.unsupportedParameters,
      'supported_parameters_override': offering.supportedParametersOverride,
      'reasoning_override': offering.reasoningOverride,
      'notes': offering.notes,
    };
  }

  int _offeringScore({
    required JsonMap entry,
    required String query,
    required String providerId,
  }) {
    final currentProviderId = ValueReaders.stringValue(entry['provider_id']);
    if (providerId.isNotEmpty) {
      if (currentProviderId.isEmpty || currentProviderId != providerId) {
        return 0;
      }
    }
    if (query.isEmpty) {
      return providerId.isNotEmpty ? 20 : 1;
    }
    var score = _max(
      _textScore(ValueReaders.stringValue(entry['model_id']), query),
      _textScore(ValueReaders.stringValue(entry['display_label']), query),
    );
    score = _max(
      score,
      _textScore(ValueReaders.stringValue(entry['canonical_model_id']), query),
    );
    for (final alias in ValueReaders.objectList(entry['aliases'])) {
      score = _max(score, _textScore(ValueReaders.stringValue(alias), query));
    }
    if (providerId.isNotEmpty && currentProviderId == providerId && score > 0) {
      score += 30;
    }
    return score;
  }

  int _textScore(String value, String query) {
    final haystack = value.trim().toLowerCase();
    if (haystack.isEmpty || query.isEmpty) {
      return 0;
    }
    if (haystack == query) {
      return 140;
    }
    if (haystack.startsWith(query)) {
      return 110;
    }
    if (haystack.contains(query)) {
      return 80;
    }
    final compactHaystack = haystack.replaceAll(RegExp(r'[-_/ .()]'), '');
    final compactQuery = query.replaceAll(RegExp(r'[-_/ .()]'), '');
    if (compactQuery.isNotEmpty && compactHaystack.contains(compactQuery)) {
      return 70;
    }
    return 0;
  }

  int _max(int left, int right) {
    return left > right ? left : right;
  }
}
