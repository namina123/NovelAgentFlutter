import 'workbench_auxiliary_panel_id.dart';

class WorkbenchCenterAuxiliaryPanelViewData {
  const WorkbenchCenterAuxiliaryPanelViewData({
    required this.panelId,
    required this.label,
    required this.description,
  });

  final WorkbenchAuxiliaryPanelId panelId;
  final String label;
  final String description;
}
