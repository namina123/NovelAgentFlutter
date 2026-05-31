import 'package:flutter/foundation.dart';

import 'workbench_navigation_panel_id.dart';
import 'workbench_side_panel_entry_kind.dart';

@immutable
class WorkbenchSidePanelContract {
  const WorkbenchSidePanelContract({
    required this.panelId,
    required this.label,
    required this.tooltip,
    required this.objectTitle,
    required this.summary,
    required this.responsibilities,
    required this.allowedEntryKinds,
    required this.disallowedEntryKinds,
  });

  final WorkbenchNavigationPanelId panelId;
  final String label;
  final String tooltip;
  final String objectTitle;
  final String summary;
  final List<String> responsibilities;
  final List<WorkbenchSidePanelEntryKind> allowedEntryKinds;
  final List<WorkbenchSidePanelEntryKind> disallowedEntryKinds;

  bool supportsEntryKind(WorkbenchSidePanelEntryKind kind) {
    return allowedEntryKinds.contains(kind);
  }

  bool rejectsEntryKind(WorkbenchSidePanelEntryKind kind) {
    return disallowedEntryKinds.contains(kind);
  }
}
