import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectAgentGroupBindingDocumentCodecService {
  ProjectAgentGroupBindingDocumentCodecService({
    ProjectAgentGroupSelectionNormalizerService? normalizerService,
  }) : _normalizerService =
           normalizerService ??
           const ProjectAgentGroupSelectionNormalizerService();

  final ProjectAgentGroupSelectionNormalizerService _normalizerService;

  List<ProjectAgentGroupSelection> parseDocument(JsonMap document) {
    // 中文注释: 绑定文档读取只恢复项目级选择，不承担默认候选或可用性过滤逻辑。
    return ValueReaders.objectList(
          document['groups'] ?? document['agent_groups'],
        )
        .map((item) {
          return _normalizerService.normalize(ValueReaders.mapValue(item));
        })
        .where((item) => item.groupId.trim().isNotEmpty)
        .toList(growable: false);
  }

  JsonMap toDocument(List<ProjectAgentGroupSelection> selections) {
    return <String, Object?>{
      'schema_version': 1,
      'groups': selections
          .map(_normalizerService.toDocument)
          .cast<Object?>()
          .toList(growable: false),
    };
  }
}
