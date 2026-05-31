import '../../common/json_types.dart';
import 'provider_catalog_service.dart';

class LegacyProviderCatalogBridgeService {
  LegacyProviderCatalogBridgeService({
    ProviderCatalogService? catalogService,
  }) : _catalogService = catalogService ?? ProviderCatalogService.seeded();

  final ProviderCatalogService _catalogService;

  JsonMap legacyProviderById(String providerId) {
    return _catalogService.providerById(providerId);
  }

  List<JsonMap> legacyModelSuggestions({
    String providerId = '',
    String query = '',
    bool includeImage = false,
    int limit = 48,
  }) {
    return _catalogService.modelSuggestions(
      providerId: providerId,
      query: query,
      includeImage: includeImage,
      limit: limit,
    );
  }

  JsonMap legacyMatchModel(String modelId, {String providerId = ''}) {
    return _catalogService.matchModel(modelId, providerId: providerId);
  }

  JsonMap legacyModelProfileDefaults(
    JsonMap modelEntry, {
    String credentialId = '',
  }) {
    return _catalogService.modelProfileDefaults(
      modelEntry,
      credentialId: credentialId,
    );
  }

  JsonMap legacyCatalogParameterSummary(JsonMap modelEntry) {
    return _catalogService.catalogParameterSummary(modelEntry);
  }
}
