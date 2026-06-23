import 'package:novel_agent_core/novel_agent_core.dart';

import 'remote_openai_compatible_embedding_provider.dart';

/// 从当前设置解析可用的 embedding provider。
///
/// 中文注释: embedding 需要一组 provider 凭据 + 一个 embedding 模型 id。
/// 这里复用「默认 chat provider」的 baseUrl/apiKey 作为凭据，embedding 模型 id
/// 从 `AppSettings.extraSettings['embedding_model_id']` 读取（可选，未配置则返回 null，
/// 检索/入库据此如实回退到关键词模式，不再造假）。把配置放在 extraSettings 里，
/// 避免改动 settings schema；将来加专门的 UI 字段时只需往 extraSettings 写同一个键。
class SettingsBackedEmbeddingProviderResolver {
  const SettingsBackedEmbeddingProviderResolver();

  /// 解析默认 provider + embedding 模型；任一缺失就返回 null（由调用方诚实降级）。
  EmbeddingProviderPort? resolve(AppSettings settings) {
    final embeddingModelId = ValueReaders.stringValue(
      settings.extraSettings['embedding_model_id'],
    ).trim();
    if (embeddingModelId.isEmpty) {
      return null;
    }
    final provider = _resolveDefaultProvider(settings);
    if (provider == null ||
        provider.baseUrl.trim().isEmpty ||
        provider.apiKey.trim().isEmpty) {
      return null;
    }
    return RemoteOpenAiCompatibleEmbeddingProvider(
      providerId: provider.id,
      baseUrl: provider.baseUrl,
      apiKey: provider.apiKey,
      modelId: embeddingModelId,
    );
  }

  ProviderEndpointSettings? _resolveDefaultProvider(AppSettings settings) {
    // 中文注释: 优先按 defaultProviderId 命中，找不到再退到 isDefault / 首个 provider，
    // 与应用层选定活动 provider 的口径保持一致。
    final providers = settings.providers;
    if (providers.isEmpty) {
      return null;
    }
    final defaultId = settings.defaultProviderId.trim();
    if (defaultId.isNotEmpty) {
      for (final provider in providers) {
        if (provider.id == defaultId) {
          return provider;
        }
      }
    }
    for (final provider in providers) {
      if (provider.isDefault) {
        return provider;
      }
    }
    return providers.first;
  }
}
