import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_agent_group_binding_document_codec_service.dart';
import 'project_agent_group_binding_path_service.dart';
import 'project_json_document_service.dart';

class ProjectAgentGroupBindingRepository {
  ProjectAgentGroupBindingRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectAgentGroupBindingDocumentCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _codecService =
           codecService ?? ProjectAgentGroupBindingDocumentCodecService();

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectAgentGroupBindingDocumentCodecService _codecService;

  Future<List<ProjectAgentGroupSelection>> loadSelections(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 项目级组绑定永远从当前项目隐藏设置目录读取，确保不会串到全局设置或别的项目。
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      ProjectAgentGroupBindingPathService.relativePath,
    );
    if (document.isEmpty) {
      return const <ProjectAgentGroupSelection>[];
    }
    return _codecService.parseDocument(document);
  }

  Future<void> saveSelections(
    ProjectDescriptor project,
    List<ProjectAgentGroupSelection> selections,
  ) {
    // 中文注释: 持久化时统一走绑定文档 codec，后续 UI/CLI 只操作强类型 selection 列表即可。
    return _jsonDocumentService.writeJsonMap(
      project.rootPath,
      ProjectAgentGroupBindingPathService.relativePath,
      _codecService.toDocument(selections),
    );
  }
}
