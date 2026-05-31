import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_continuity_build_spec_document_codec_service.dart';
import 'project_continuity_path_policy.dart';
import 'project_json_document_service.dart';

class ProjectContinuityBuildSpecRepository {
  ProjectContinuityBuildSpecRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectContinuityPathPolicy? pathPolicy,
    ProjectContinuityBuildSpecDocumentCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _pathPolicy = pathPolicy ?? ProjectContinuityPathPolicy(),
       _codecService =
           codecService ?? ProjectContinuityBuildSpecDocumentCodecService();

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectContinuityPathPolicy _pathPolicy;
  final ProjectContinuityBuildSpecDocumentCodecService _codecService;

  Future<List<ContinuityBuildSpec>> loadAll(ProjectDescriptor project) async {
    final indexDocument = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathPolicy.buildSpecIndexPath(),
    );
    final specIds = ValueReaders.stringList(indexDocument['build_spec_ids']);
    final result = <ContinuityBuildSpec>[];
    for (final specId in specIds) {
      final document = await _jsonDocumentService.readJsonMap(
        project.rootPath,
        _pathPolicy.buildSpecPath(specId),
      );
      if (document.isEmpty) {
        continue;
      }
      final spec = _codecService.parseDocument(document);
      if (spec.id.isEmpty) {
        continue;
      }
      result.add(spec);
    }
    return result;
  }

  Future<void> saveAll(
    ProjectDescriptor project,
    List<ContinuityBuildSpec> specs,
  ) async {
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathPolicy.buildSpecIndexPath(),
      <String, Object?>{
        'schema_version': 1,
        'build_spec_ids': specs
            .map((item) => item.id)
            .cast<Object?>()
            .toList(growable: false),
      },
    );

    for (final spec in specs) {
      await _jsonDocumentService.writeJsonMap(
        project.rootPath,
        _pathPolicy.buildSpecPath(spec.id),
        _codecService.toDocument(spec),
      );
    }
  }
}
