import '../tools/project_tool_path_policy.dart';

class ProjectToolPermissionApprovalPathService {
  ProjectToolPermissionApprovalPathService({
    ProjectToolPathPolicy? toolPathPolicy,
  }) : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolPathPolicy _toolPathPolicy;

  String recordDirectoryPath() =>
      '.novel_agent/runtime/tool_permission_approvals/';

  String indexPath() => '${recordDirectoryPath()}index.json';

  String recordPath(String approvalId) {
    final safeId = _toolPathPolicy.safeFileName(
      approvalId,
      fallback: 'tool_permission_approval',
      maxLength: 96,
    );
    return '${recordDirectoryPath()}$safeId.json';
  }
}
