import 'package:novel_agent_core/novel_agent_core.dart';

class AgentCatalogOverlayDocumentCodecService {
  AgentCatalogOverlayDocumentCodecService({
    AgentApplicabilityScopeNormalizerService? scopeNormalizerService,
  }) : _scopeNormalizerService =
           scopeNormalizerService ??
           const AgentApplicabilityScopeNormalizerService();

  final AgentApplicabilityScopeNormalizerService _scopeNormalizerService;

  JsonMap normalize(JsonMap raw) {
    // 中文注释: 智能体 overlay 文档只声明产品层补充信息，真正智能体主体仍来自包目录。
    final agentId = ValueReaders.stringValue(
      raw['agent_id'] ?? raw['id'],
    ).trim();
    final scopeDocument = _scopeNormalizerService.toDocument(
      _scopeNormalizerService.normalize(
        ValueReaders.mapValue(raw['applicability_scope']),
      ),
    );
    return <String, Object?>{
      'schema_version': ValueReaders.intValue(raw['schema_version'], 1),
      'agent_id': agentId,
      'display_label': ValueReaders.stringValue(
        raw['display_label'] ?? raw['label'],
      ).trim(),
      'recommended_by_default': ValueReaders.boolValue(
        raw['recommended_by_default'] ?? raw['selected_by_default'],
      ),
      'applicability_scope': scopeDocument,
      'metadata': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    };
  }

  JsonMap toDocument(JsonMap overlay) {
    return normalize(overlay);
  }
}
