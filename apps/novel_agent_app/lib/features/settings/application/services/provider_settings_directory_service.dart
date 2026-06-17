import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/settings_view_data.dart';

class ProviderSettingsDirectoryService {
  ProviderSettingsDirectoryService({
    ProviderInterfaceTemplateService? templateService,
    ProviderModelSelectionContractService? modelSelectionContractService,
  }) : _templateService =
           templateService ?? ProviderInterfaceTemplateService.seeded(),
       _modelSelectionContractService =
           modelSelectionContractService ?? ProviderModelSelectionContractService();

  final ProviderInterfaceTemplateService _templateService;
  final ProviderModelSelectionContractService _modelSelectionContractService;

  List<ProviderDirectoryOptionViewData> providerOptions() {
    return _templateService
        .templates()
        .map(
          (entry) => ProviderDirectoryOptionViewData(
            id: ValueReaders.stringValue(entry['id']),
            label: ValueReaders.stringValue(
              entry['label'],
              ValueReaders.stringValue(entry['provider_id']),
            ),
            protocol: ValueReaders.stringValue(
              entry['protocol'],
              'openai_compatible',
            ),
            defaultBaseUrl: ValueReaders.stringValue(entry['default_base_url']),
          ),
        )
        .toList(growable: false);
  }

  List<SettingsSearchOptionViewData> allModelOptions() {
    final suggestions = _modelSelectionContractService.providerModelOptions(
      providerId: '',
      limit: 1000,
    );
    final seen = <String>{};
    final result = <SettingsSearchOptionViewData>[];
    for (final entry in suggestions) {
      final modelId = entry.modelId.trim();
      if (modelId.isEmpty || !seen.add('${entry.providerId}::$modelId')) {
        continue;
      }
      result.add(
        SettingsSearchOptionViewData(
          value: modelId,
          label: entry.modelLabel.isEmpty ? modelId : entry.modelLabel,
          note: entry.providerLabel,
          providerId: entry.providerId,
        ),
      );
    }
    return result;
  }

  ProviderDirectoryOptionViewData? providerOptionById(String providerId) {
    final cleanId = providerId.trim();
    if (cleanId.isEmpty) {
      return null;
    }
    for (final option in providerOptions()) {
      if (option.id == cleanId) {
        return option;
      }
    }
    return null;
  }

  ProviderDirectoryOptionViewData? providerOptionByQuery(String query) {
    final matched = _templateService.bestTemplateMatch(query: query);
    final matchedId = ValueReaders.stringValue(matched['id']).trim();
    if (matchedId.isEmpty) {
      return null;
    }
    return providerOptionById(matchedId);
  }
}
