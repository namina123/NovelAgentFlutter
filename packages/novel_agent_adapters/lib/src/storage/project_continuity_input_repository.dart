import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_continuity_input_document_codec_service.dart';
import 'project_continuity_input_path_service.dart';
import 'project_json_document_service.dart';

class ProjectContinuityInputRepository {
  ProjectContinuityInputRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectContinuityInputDocumentCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _codecService =
           codecService ?? const ProjectContinuityInputDocumentCodecService();

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectContinuityInputDocumentCodecService _codecService;

  Future<ProjectContinuityInputProfile?> load(ProjectDescriptor project) async {
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      ProjectContinuityInputPathService.relativePath,
    );
    if (document.isEmpty) {
      return null;
    }
    return _codecService.parseDocument(document);
  }

  Future<void> save(
    ProjectDescriptor project,
    ProjectContinuityInputProfile profile,
  ) {
    return _jsonDocumentService.writeJsonMap(
      project.rootPath,
      ProjectContinuityInputPathService.relativePath,
      _codecService.toDocument(profile),
    );
  }
}
