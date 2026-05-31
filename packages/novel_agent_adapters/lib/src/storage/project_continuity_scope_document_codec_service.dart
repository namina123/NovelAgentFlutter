import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_continuity_json_codec_support.dart';
import 'project_continuity_scope_document.dart';

class ProjectContinuityScopeDocumentCodecService {
  ProjectContinuityScopeDocumentCodecService({
    ProjectContinuityJsonCodecSupport? codecSupport,
  }) : _codecSupport =
           codecSupport ?? const ProjectContinuityJsonCodecSupport();

  final ProjectContinuityJsonCodecSupport _codecSupport;

  ProjectContinuityScopeDocument parseDocument(JsonMap document) {
    final scopeDocument = ValueReaders.mapValue(document['scope']);
    return ProjectContinuityScopeDocument(
      scope: _codecSupport.parseScope(
        scopeDocument.isEmpty ? document : scopeDocument,
      ),
      overlays: ValueReaders.objectList(document['overlays'])
          .map(
            (item) =>
                _codecSupport.parseScopeOverlay(ValueReaders.mapValue(item)),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false),
    );
  }

  JsonMap toDocument({
    required ContinuationScope scope,
    required List<ContinuationScopeOverlay> overlays,
  }) {
    return <String, Object?>{
      'schema_version': 1,
      'scope': _codecSupport.scopeToDocument(scope),
      'overlays': overlays
          .map(_codecSupport.scopeOverlayToDocument)
          .cast<Object?>()
          .toList(growable: false),
    };
  }
}
