import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_continuity_json_codec_support.dart';

class ProjectContinuityFrameDocumentCodecService {
  ProjectContinuityFrameDocumentCodecService({
    ProjectContinuityJsonCodecSupport? codecSupport,
  }) : _codecSupport =
           codecSupport ?? const ProjectContinuityJsonCodecSupport();

  final ProjectContinuityJsonCodecSupport _codecSupport;

  ContinuityFrame parseDocument(JsonMap document) {
    final frameDocument = ValueReaders.mapValue(document['frame']);
    return _codecSupport.parseFrame(
      frameDocument.isEmpty ? document : frameDocument,
    );
  }

  JsonMap toDocument(ContinuityFrame frame) {
    return <String, Object?>{
      'schema_version': 1,
      'frame': _codecSupport.frameToDocument(frame),
    };
  }
}
