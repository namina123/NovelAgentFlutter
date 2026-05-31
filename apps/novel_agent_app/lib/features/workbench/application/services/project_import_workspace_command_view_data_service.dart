import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/workspace_command_request_view_data.dart';
import '../models/project_import_action_policy.dart';
import 'project_import_action_policy_service.dart';

class ProjectImportWorkspaceCommandViewDataService {
  ProjectImportWorkspaceCommandViewDataService({
    ProjectImportActionPolicyService? actionPolicyService,
  }) : _actionPolicyService =
           actionPolicyService ?? ProjectImportActionPolicyService();

  final ProjectImportActionPolicyService _actionPolicyService;

  WorkspaceCommandViewData build({
    required String projectType,
    List<String> sourcePaths = const <String>[],
    String requestedTargetDirectory = '',
    bool requestedAutoDeconstruct = false,
    String status = '',
  }) {
    final policy = _actionPolicyService.build(
      projectType: projectType,
      sourcePaths: sourcePaths,
      requestedTargetDirectory: requestedTargetDirectory,
      requestedAutoDeconstruct: requestedAutoDeconstruct,
    );
    return WorkspaceCommandViewData(
      mode: WorkspaceCommandMode.importFiles,
      title: '导入文件',
      description: _descriptionFor(projectType.trim()),
      confirmLabel: '导入文件',
      status: status,
      projectTitle: '',
      projectType: projectType.trim(),
      genre: '',
      premise: '',
      notes: '',
      relativePath: '',
      entryName: '',
      content: '',
      sourcePathsText: policy.sourcePaths.join('\n'),
      targetDirectory: policy.resolvedTargetDirectory,
      autoDeconstruct: policy.autoDeconstruct,
      canAutoDeconstruct: policy.canAutoDeconstruct,
      importFileSelectionHint: policy.fileSelectionHint,
      importOutputHint: policy.outputHint,
    );
  }

  WorkspaceCommandViewData rebuild({
    required WorkspaceCommandRequestViewData request,
    String status = '',
  }) {
    return build(
      projectType: request.projectType,
      sourcePaths: request.sourcePaths,
      requestedTargetDirectory: request.targetDirectory,
      requestedAutoDeconstruct: request.autoDeconstruct,
      status: status,
    );
  }

  ProjectImportActionPolicy resolvePolicy({
    required WorkspaceCommandRequestViewData request,
  }) {
    return _actionPolicyService.build(
      projectType: request.projectType,
      sourcePaths: request.sourcePaths,
      requestedTargetDirectory: request.targetDirectory,
      requestedAutoDeconstruct: request.autoDeconstruct,
    );
  }

  String _descriptionFor(String projectType) {
    if (projectType == BookDeconstructionConstants.projectTypeId) {
      return '选择源文稿导入当前拆书项目；支持自动拆书预演，并把纪要写回项目。';
    }
    return '选择一个或多个本地文件导入当前项目；支持对单个文本或 Markdown 文件进行自动拆书预演。';
  }
}
