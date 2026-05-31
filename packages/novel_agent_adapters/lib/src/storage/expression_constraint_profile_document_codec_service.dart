import 'package:novel_agent_core/novel_agent_core.dart';

class ExpressionConstraintProfileDocumentCodecService {
  ExpressionConstraintProfileDocumentCodecService({
    ExpressionConstraintProfileNormalizerService? normalizerService,
  }) : _normalizerService =
           normalizerService ??
           const ExpressionConstraintProfileNormalizerService();

  final ExpressionConstraintProfileNormalizerService _normalizerService;

  List<ExpressionConstraintProfile> parseDocument(JsonMap document) {
    // 中文注释: 表达限制 profile 文档只恢复项目内显式保存的 preset，不混入 builtin 注册逻辑。
    return ValueReaders.objectList(document['profiles'])
        .map(
          (item) => _normalizerService.normalize(ValueReaders.mapValue(item)),
        )
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  JsonMap toDocument(List<ExpressionConstraintProfile> profiles) {
    return <String, Object?>{
      'schema_version': 1,
      'profiles': profiles
          .map(_normalizerService.toDocument)
          .cast<Object?>()
          .toList(growable: false),
    };
  }
}
