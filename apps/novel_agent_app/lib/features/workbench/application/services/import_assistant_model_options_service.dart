import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/selector_option_view_data.dart';

/// 构建"导入助手 / 拆书 / 分析"等场景共用的"提供商·模型"下拉选项。
///
/// 每个选项的 id 是复合键 `"$providerId::$modelId"`（调用方按 `::` 拆出 provider/model），
/// label 是 `"$providerTitle · $modelId"`，note 是 providerId。仅收录 provider.id 与
/// provider.modelId 都非空的组合，按复合键去重。
///
/// 抽到共享处，避免 workbench overlay 与拆书控制器各写一份相同的拼接逻辑。
class ImportAssistantModelOptionsService {
  const ImportAssistantModelOptionsService();

  List<SelectorOptionViewData> build(AppSettings? settings) {
    if (settings == null) {
      return const <SelectorOptionViewData>[];
    }
    final options = <SelectorOptionViewData>[];
    final seen = <String>{};
    for (final provider in settings.providers) {
      final providerId = provider.id.trim();
      final modelId = provider.modelId.trim();
      if (providerId.isEmpty || modelId.isEmpty) {
        continue;
      }
      final key = '$providerId::$modelId';
      if (!seen.add(key)) {
        continue;
      }
      final providerLabel = provider.title.trim().isEmpty
          ? providerId
          : provider.title.trim();
      options.add(
        SelectorOptionViewData(
          id: key,
          label: '$providerLabel · $modelId',
          note: providerId,
        ),
      );
    }
    return List<SelectorOptionViewData>.unmodifiable(options);
  }

  /// 把复合键 `"$providerId::$modelId"` 拆成 (providerId, modelId)；非法键返回空串。
  ({String providerId, String modelId}) splitKey(String optionKey) {
    final parts = optionKey.split('::');
    if (parts.length != 2) {
      return (providerId: '', modelId: '');
    }
    return (providerId: parts[0].trim(), modelId: parts[1].trim());
  }
}
