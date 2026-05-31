import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectExpressionConstraintBindingDocumentCodecService {
  ProjectExpressionConstraintBindingDocumentCodecService({
    ProjectExpressionConstraintBindingNormalizerService? normalizerService,
  }) : _normalizerService =
           normalizerService ??
           const ProjectExpressionConstraintBindingNormalizerService();

  final ProjectExpressionConstraintBindingNormalizerService _normalizerService;

  List<ProjectExpressionConstraintBinding> parseDocument(JsonMap document) {
    // 中文注释: 当前项目表达限制 binding 文档只恢复项目内启用方式，不参与 builtin preset 注册。
    return ValueReaders.objectList(document['bindings'])
        .map(
          (item) => _normalizerService.normalize(ValueReaders.mapValue(item)),
        )
        .where((item) => item.profileId.trim().isNotEmpty)
        .toList(growable: false);
  }

  JsonMap toDocument(List<ProjectExpressionConstraintBinding> bindings) {
    return <String, Object?>{
      'schema_version': 1,
      'bindings': bindings
          .map(_normalizerService.toDocument)
          .cast<Object?>()
          .toList(growable: false),
    };
  }
}
