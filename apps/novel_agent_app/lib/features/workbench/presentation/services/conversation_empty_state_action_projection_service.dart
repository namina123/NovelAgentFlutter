import '../models/primary_action_view_data.dart';
import '../models/workbench_conversation_view_data.dart';

class ConversationEmptyStateActionProjectionService {
  const ConversationEmptyStateActionProjectionService();

  List<PrimaryActionViewData> visibleActions(
    WorkbenchConversationViewData viewData,
  ) {
    if (!viewData.hasActiveProject) {
      return const <PrimaryActionViewData>[];
    }
    final actions = viewData.primaryActions;
    if (actions.isEmpty) {
      return const <PrimaryActionViewData>[];
    }
    final openingState = viewData.openingState;
    if (openingState?.preferSingleAction == true &&
        openingState?.nextAction != null) {
      return <PrimaryActionViewData>[openingState!.nextAction!];
    }
    if (openingState != null) {
      if (openingState.nextAction != null) {
        return <PrimaryActionViewData>[openingState.nextAction!];
      }
      return const <PrimaryActionViewData>[];
    }
    if (viewData.openingPanel != null || _hasExplicitGuidedActions(actions)) {
      return actions;
    }
    return <PrimaryActionViewData>[actions.first];
  }

  bool _hasExplicitGuidedActions(List<PrimaryActionViewData> actions) {
    for (final action in actions) {
      final commandId = action.commandId.trim();
      if (commandId.startsWith('guide.') ||
          commandId == 'workspace.open_import_command') {
        return true;
      }
    }
    return false;
  }
}
