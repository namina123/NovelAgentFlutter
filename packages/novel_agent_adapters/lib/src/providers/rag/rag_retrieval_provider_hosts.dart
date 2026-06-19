import 'package:novel_agent_core/novel_agent_core.dart';

import 'rag_retrieval_provider_contracts.dart';
import 'rag_retrieval_provider_resolver.dart';
import 'rag_retrieval_provider_registry.dart';

abstract interface class RagRetrievalHostCapabilityPort {
  bool supportsRetrievalProvider(String providerId);

  RagRetrievalCapabilityReport retrievalCapabilityReport(String providerId);

  List<JsonMap> retrievalProviderProfiles();
}

final class DefaultRagRetrievalHostCapabilityPort
    implements RagRetrievalHostCapabilityPort {
  DefaultRagRetrievalHostCapabilityPort({
    RagRetrievalProviderResolver? resolver,
  }) : _resolver = resolver ?? RagRetrievalProviderResolver();

  final RagRetrievalProviderResolver _resolver;

  @override
  bool supportsRetrievalProvider(String providerId) {
    // 中文注释: host capability 只做查询，不在这里创建或初始化任何 backend。
    return _resolver.supportsProvider(providerId);
  }

  @override
  RagRetrievalCapabilityReport retrievalCapabilityReport(String providerId) {
    // 中文注释: report 直接透传 resolver 结果，保证 GUI/CLI/probe 读到同一份事实。
    return _resolver.capabilityReport(providerId);
  }

  @override
  List<JsonMap> retrievalProviderProfiles() {
    // 中文注释: profiles 以 JSON 形式输出，供宿主做轻量摘要展示与诊断。
    return RagRetrievalProviderRegistry.standard()
        .profiles()
        .map((profile) => profile.toJson())
        .toList(growable: false);
  }
}
