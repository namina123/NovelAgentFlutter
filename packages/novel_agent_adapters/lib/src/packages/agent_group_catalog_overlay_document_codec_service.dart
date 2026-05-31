import 'package:novel_agent_core/novel_agent_core.dart';

class AgentGroupCatalogOverlayDocumentCodecService {
  AgentGroupCatalogOverlayDocumentCodecService({
    AgentGroupApplicabilityScopeNormalizerService? scopeNormalizerService,
  }) : _scopeNormalizerService =
           scopeNormalizerService ??
           const AgentGroupApplicabilityScopeNormalizerService();

  final AgentGroupApplicabilityScopeNormalizerService _scopeNormalizerService;

  JsonMap normalize(JsonMap raw) {
    // 中文注释: 智能体组 overlay 只补充可见性和默认建议，组成员与编排来源仍以组定义本体为准。
    final groupId = ValueReaders.stringValue(
      raw['group_id'] ?? raw['id'],
    ).trim();
    final document = <String, Object?>{
      'schema_version': ValueReaders.intValue(raw['schema_version'], 1),
      'group_id': groupId,
      'display_label': ValueReaders.stringValue(
        raw['display_label'] ?? raw['label'],
      ).trim(),
      'metadata': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    };
    if (raw.containsKey('recommended_by_default') ||
        raw.containsKey('selected_by_default')) {
      document['recommended_by_default'] = ValueReaders.boolValue(
        raw['recommended_by_default'] ?? raw['selected_by_default'],
      );
    }
    if (raw.containsKey('applicability_scope')) {
      document['applicability_scope'] = _scopeNormalizerService.toDocument(
        _scopeNormalizerService.normalize(
          ValueReaders.mapValue(raw['applicability_scope']),
        ),
      );
    }
    return document;
  }

  JsonMap toDocument(JsonMap overlay) {
    return normalize(overlay);
  }
}
