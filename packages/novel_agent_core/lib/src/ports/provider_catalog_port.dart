import '../common/json_types.dart';

abstract class ProviderCatalogPort {
  List<JsonMap> providerOptions({String query = '', String baseUrl = ''});

  List<JsonMap> providers();

  JsonMap providerById(String providerId);

  JsonMap bestProviderMatch({String query = '', String baseUrl = ''});

  List<JsonMap> modelSuggestions({
    String query = '',
    String providerId = '',
    bool includeImage = true,
    int limit = 16,
  });

  JsonMap matchModel(String modelId, {String providerId = ''});

  JsonMap modelProfileDefaults(JsonMap modelEntry, {String credentialId = ''});

  JsonMap catalogParameterSummary(JsonMap modelEntry);
}
