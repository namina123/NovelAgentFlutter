import 'project_launcher_view_data.dart';
import 'project_agent_group_workspace_view_data.dart';
import 'workspace_command_request_view_data.dart';

class WorkbenchOverlayViewData {
  const WorkbenchOverlayViewData({
    required this.projectLauncher,
    required this.projectAgentGroupWorkspace,
    required this.workspaceCommand,
  });

  final ProjectLauncherViewData? projectLauncher;
  final ProjectAgentGroupWorkspaceViewData? projectAgentGroupWorkspace;
  final WorkspaceCommandViewData? workspaceCommand;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkbenchOverlayViewData &&
            other.projectLauncher == projectLauncher &&
            other.projectAgentGroupWorkspace == projectAgentGroupWorkspace &&
            other.workspaceCommand == workspaceCommand;
  }

  @override
  int get hashCode => Object.hash(
    projectLauncher,
    projectAgentGroupWorkspace,
    workspaceCommand,
  );
}
