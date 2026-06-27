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
    // 中文注释: 拆书/分析用的"可用模型"取当前生效的默认接口 + 默认模型（在「模型」页选定），
    // 而不是遍历每个 provider 的 modelId——provider 详情只承载厂商凭据，模型由「模型」页统一管理。
    // 否则用户在「模型」页保存模型后，拆书面板仍读 provider.modelId（空），显示"尚未配置可用模型"。
    if (settings == null) {
      return const <SelectorOptionViewData>[];
    }
    final providerId = settings.defaultProviderId.trim();
    final modelId = settings.defaultModelId.trim();
    if (providerId.isEmpty || modelId.isEmpty) {
      return const <SelectorOptionViewData>[];
    }
    var providerLabel = providerId;
    for (final provider in settings.providers) {
      if (provider.id.trim() == providerId) {
        providerLabel = provider.title.trim().isEmpty
            ? providerId
            : provider.title.trim();
        break;
      }
    }
    return <SelectorOptionViewData>[
      SelectorOptionViewData(
        id: '$providerId::$modelId',
        label: '$providerLabel · $modelId',
        note: providerId,
      ),
    ];
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
