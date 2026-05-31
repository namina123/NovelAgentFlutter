import 'workbench_file_panel_action_handler.dart';
import 'workbench_project_panel_action_handler.dart';

abstract class ResourceManagerActionHandler
    implements
        WorkbenchFilePanelActionHandler,
        WorkbenchProjectPanelActionHandler {
  void onProjectAgentGroupDismissed();

  void onProjectAgentGroupSelected(String groupId);

  void onTasksRequested();

  void onReviewsRequested();
}
