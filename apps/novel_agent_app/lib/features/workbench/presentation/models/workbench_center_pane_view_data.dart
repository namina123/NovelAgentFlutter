import 'workbench_auxiliary_panel_id.dart';
import 'workbench_center_auxiliary_panel_view_data.dart';

class WorkbenchCenterPaneViewData {
  const WorkbenchCenterPaneViewData({
    required this.primaryTitle,
    required this.primaryDescription,
    required this.auxiliaryTitle,
    required this.auxiliaryRevealLabel,
    required this.canRevealAuxiliary,
    required this.auxiliaryPanels,
  });

  final String primaryTitle;
  final String primaryDescription;
  final String auxiliaryTitle;
  final String auxiliaryRevealLabel;
  final bool canRevealAuxiliary;
  final List<WorkbenchCenterAuxiliaryPanelViewData> auxiliaryPanels;

  WorkbenchCenterAuxiliaryPanelViewData descriptorFor(
    WorkbenchAuxiliaryPanelId panelId,
  ) {
    for (final panel in auxiliaryPanels) {
      if (panel.panelId == panelId) {
        return panel;
      }
    }
    return auxiliaryPanels.first;
  }
}
