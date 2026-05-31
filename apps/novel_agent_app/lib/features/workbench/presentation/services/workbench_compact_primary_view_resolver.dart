import '../models/workbench_compact_primary_view.dart';

class WorkbenchCompactPrimaryViewResolver {
  const WorkbenchCompactPrimaryViewResolver();

  WorkbenchCompactPrimaryView resolveInitial({
    required bool isDocumentsWorkspaceVisible,
  }) {
    return isDocumentsWorkspaceVisible
        ? WorkbenchCompactPrimaryView.document
        : WorkbenchCompactPrimaryView.conversation;
  }

  WorkbenchCompactPrimaryView synchronize({
    required WorkbenchCompactPrimaryView currentView,
    required bool isDocumentsWorkspaceVisible,
  }) {
    if (isDocumentsWorkspaceVisible) {
      return WorkbenchCompactPrimaryView.document;
    }
    if (currentView == WorkbenchCompactPrimaryView.document) {
      return WorkbenchCompactPrimaryView.conversation;
    }
    return currentView;
  }
}
