import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_continuity_json_codec_support.dart';

class ProjectContinuityBuildSpecDocumentCodecService {
  ProjectContinuityBuildSpecDocumentCodecService({
    ProjectContinuityJsonCodecSupport? codecSupport,
  }) : _codecSupport =
           codecSupport ?? const ProjectContinuityJsonCodecSupport();

  final ProjectContinuityJsonCodecSupport _codecSupport;

  ContinuityBuildSpec parseDocument(JsonMap document) {
    final buildSpecDocument = ValueReaders.mapValue(document['build_spec']);
    return _codecSupport.parseBuildSpec(
      buildSpecDocument.isEmpty ? document : buildSpecDocument,
    );
  }

  JsonMap toDocument(ContinuityBuildSpec spec) {
    return <String, Object?>{
      'schema_version': 1,
      'build_spec': _codecSupport.buildSpecToDocument(spec),
    };
  }
}
