import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'writing_model_offering_catalog_service.dart';

final class ProviderModelSelectionContract {
  const ProviderModelSelectionContract({
    required this.providerId,
    required this.providerLabel,
    required this.modelId,
    required this.modelLabel,
    required this.canonicalModelId,
    required this.sourceKind,
    required this.score,
  });

  final String providerId;
  final String providerLabel;
  final String modelId;
  final String modelLabel;
  final String canonicalModelId;
  final String sourceKind;
  final int score;

  JsonMap toJson() {
    // 中文注释: 候选合同需要稳定 JSON 投影，方便 settings / CLI / probe 共享同一选择事实。
    return <String, Object?>{
      'provider_id': providerId,
      'provider_label': providerLabel,
      'model_id': modelId,
      'model_label': modelLabel,
      'canonical_model_id': canonicalModelId,
      'source_kind': sourceKind,
      'score': score,
    };
  }
}

final class ProviderModelSelectionContractService {
  ProviderModelSelectionContractService({
    WritingModelOfferingCatalogService? offeringCatalogService,
  }) : _offeringCatalogService =
           offeringCatalogService ?? WritingModelOfferingCatalogService();

  final WritingModelOfferingCatalogService _offeringCatalogService;

  List<ProviderModelSelectionContract> providerModelOptions({
    required String providerId,
    String query = '',
    int limit = 48,
  }) {
    // 中文注释: 模型候选统一以 provider 为边界返回，确保搜索只影响提示候选，不改写手工输入自由度。
    final cleanProviderId = providerId.trim();
    final offerings = _offeringCatalogService.offeringOptions(
      providerId: cleanProviderId,
      query: query,
      limit: limit,
    );
    return _dedupeByModelId(
      offerings.map(_contractFromEntry).toList(growable: false),
    );
  }

  ProviderModelSelectionContract? bestProviderModelMatch({
    required String providerId,
    required String modelId,
  }) {
    // 中文注释: 手输模型 id 的正式命中逻辑仍然保留，但必须先在当前厂商范围内匹配。
    final cleanProviderId = providerId.trim();
    final cleanModelId = modelId.trim();
    if (cleanProviderId.isEmpty || cleanModelId.isEmpty) {
      return null;
    }
    final matched = _offeringCatalogService.offeringByProviderModelId(
      providerId: cleanProviderId,
      modelId: cleanModelId,
    );
    if (matched == null) {
      final fallback = _offeringCatalogService.bestMatch(
        modelId: cleanModelId,
        providerId: cleanProviderId,
      );
      if (fallback == null) {
        return null;
      }
      return _contractFromEntry(fallback);
    }
    return _contractFromEntry(matched);
  }

  bool shouldAutoExpandModelOptions({
    required String typedText,
    required String selectedProviderId,
    required List<ProviderModelSelectionContract> currentOptions,
  }) {
    // 中文注释: 输入后是否展开只看“当前有可见候选”，不把展开条件和结果选择混在一起。
    final query = typedText.trim();
    if (query.isNotEmpty && currentOptions.isNotEmpty) {
      return true;
    }
    return query.isEmpty && selectedProviderId.trim().isNotEmpty;
  }

  List<ProviderModelSelectionContract> _dedupeByModelId(
    List<ProviderModelSelectionContract> entries,
  ) {
    final seen = <String>{};
    final result = <ProviderModelSelectionContract>[];
    for (final entry in entries) {
      final key =
          '${entry.providerId.toLowerCase()}::${entry.modelId.toLowerCase()}';
      if (!seen.add(key)) {
        continue;
      }
      result.add(entry);
    }
    return result;
  }

  ProviderModelSelectionContract _contractFromEntry(JsonMap entry) {
    return ProviderModelSelectionContract(
      providerId: ValueReaders.stringValue(entry['provider_id']),
      providerLabel: ValueReaders.stringValue(
        entry['provider_label'],
        ValueReaders.stringValue(entry['provider_id']),
      ),
      modelId: ValueReaders.stringValue(entry['model_id']),
      modelLabel: ValueReaders.stringValue(
        entry['display_label'],
        ValueReaders.stringValue(entry['model_id']),
      ),
      canonicalModelId: ValueReaders.stringValue(entry['canonical_model_id']),
      sourceKind: ValueReaders.stringValue(entry['source_kind'], 'offering'),
      score: ValueReaders.intValue(entry['score']),
    );
  }
}
