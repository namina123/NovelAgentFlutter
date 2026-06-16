import '../project/project_support_document_catalog.dart';
import 'mode_guidance_workspace_path_service.dart';

class ModeGuidanceContextPathService {
  const ModeGuidanceContextPathService({
    ModeGuidanceWorkspacePathService? workspacePathService,
  }) : _workspacePathService =
           workspacePathService ?? const ModeGuidanceWorkspacePathService();

  final ModeGuidanceWorkspacePathService _workspacePathService;

  List<String> sourcePaths({
    required String modeId,
    required Map<String, String> projectedDocuments,
  }) {
    final formalPaths = _formalProjectedPaths(projectedDocuments);
    final result = <String>[
      _workspacePathService.summaryMarkdownPath(modeId),
      ...formalPaths,
    ];
    if (formalPaths.isEmpty) {
      result.add(ProjectSupportDocumentCatalog.projectOverviewRelativePath);
    }
    return result;
  }

  List<String> persistentContextPaths({
    required String modeId,
    required Map<String, String> projectedDocuments,
  }) {
    return <String>[
      _workspacePathService.summaryMarkdownPath(modeId),
      ..._formalProjectedPaths(projectedDocuments),
    ];
  }

  List<String> _formalProjectedPaths(Map<String, String> projectedDocuments) {
    final result = <String>[];
    for (final path in projectedDocuments.keys) {
      final trimmed = path.trim();
      if (trimmed.isEmpty ||
          ProjectSupportDocumentCatalog.isProjectOverviewPath(trimmed) ||
          result.contains(trimmed)) {
        continue;
      }
      result.add(trimmed);
    }
    return result;
  }
}
