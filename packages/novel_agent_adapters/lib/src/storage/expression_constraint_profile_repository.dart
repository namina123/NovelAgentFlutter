import 'package:novel_agent_core/novel_agent_core.dart';

import '../packages/builtin_expression_constraint_profile_registration_service.dart';
import 'expression_constraint_profile_document_codec_service.dart';
import 'expression_constraint_profile_path_service.dart';
import 'project_json_document_service.dart';

class ExpressionConstraintProfileRepository {
  ExpressionConstraintProfileRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ExpressionConstraintProfileDocumentCodecService? codecService,
    BuiltinExpressionConstraintProfileRegistrationService?
    builtinRegistrationService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _codecService =
           codecService ?? ExpressionConstraintProfileDocumentCodecService(),
       _builtinRegistrationService =
           builtinRegistrationService ??
           BuiltinExpressionConstraintProfileRegistrationService();

  final ProjectJsonDocumentService _jsonDocumentService;
  final ExpressionConstraintProfileDocumentCodecService _codecService;
  final BuiltinExpressionConstraintProfileRegistrationService
  _builtinRegistrationService;

  Future<List<ExpressionConstraintProfile>> loadProfiles(
    ProjectDescriptor project, {
    bool includeBuiltins = true,
  }) async {
    // 中文注释: 这里统一合并 builtin preset 与项目自定义 profile，后续消费方不需要再手写覆盖规则。
    final projectProfiles = await loadProjectProfiles(project);
    if (!includeBuiltins) {
      return projectProfiles;
    }
    final merged = <String, ExpressionConstraintProfile>{};
    for (final profile in _builtinRegistrationService.registeredProfiles()) {
      merged[profile.id] = profile;
    }
    for (final profile in projectProfiles) {
      merged[profile.id] = profile;
    }
    final result = merged.values.toList(growable: false);
    result.sort((left, right) => left.displayName.compareTo(right.displayName));
    return result;
  }

  Future<List<ExpressionConstraintProfile>> loadProjectProfiles(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 项目自定义表达限制只从当前项目隐藏设置读取，避免把其他项目的局部 preset 串进来。
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      ExpressionConstraintProfilePathService.relativePath,
    );
    if (document.isEmpty) {
      return const <ExpressionConstraintProfile>[];
    }
    return _codecService.parseDocument(document);
  }

  Future<void> saveProjectProfiles(
    ProjectDescriptor project,
    List<ExpressionConstraintProfile> profiles,
  ) {
    // 中文注释: 持久化时只写项目显式 profile，不把 builtin preset 反写回项目文档。
    return _jsonDocumentService.writeJsonMap(
      project.rootPath,
      ExpressionConstraintProfilePathService.relativePath,
      _codecService.toDocument(profiles),
    );
  }
}
