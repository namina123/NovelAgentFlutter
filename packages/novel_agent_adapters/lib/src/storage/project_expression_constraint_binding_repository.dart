import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_expression_constraint_binding_document_codec_service.dart';
import 'project_expression_constraint_binding_path_service.dart';
import 'project_json_document_service.dart';

class ProjectExpressionConstraintBindingRepository {
  ProjectExpressionConstraintBindingRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectExpressionConstraintBindingDocumentCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _codecService =
           codecService ??
           ProjectExpressionConstraintBindingDocumentCodecService();

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectExpressionConstraintBindingDocumentCodecService _codecService;

  Future<List<ProjectExpressionConstraintBinding>> loadBindings(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 当前项目表达限制 binding 永远从项目隐藏设置目录读取，确保不会串到别的项目。
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      ProjectExpressionConstraintBindingPathService.relativePath,
    );
    if (document.isEmpty) {
      return const <ProjectExpressionConstraintBinding>[];
    }
    return _codecService.parseDocument(document);
  }

  Future<void> saveBindings(
    ProjectDescriptor project,
    List<ProjectExpressionConstraintBinding> bindings,
  ) {
    // 中文注释: 持久化时统一走 binding codec，后续 GUI/CLI 只处理强类型 binding 列表。
    return _jsonDocumentService.writeJsonMap(
      project.rootPath,
      ProjectExpressionConstraintBindingPathService.relativePath,
      _codecService.toDocument(bindings),
    );
  }
}
