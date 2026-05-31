import 'inspiration_workbench_mode_option_view_data.dart';
import 'inspiration_workbench_option_view_data.dart';
import 'inspiration_workbench_long_task_launch_view_data.dart';
import 'inspiration_workbench_preview_section_view_data.dart';
import 'inspiration_workbench_stage_view_data.dart';

class InspirationWorkbenchViewData {
  const InspirationWorkbenchViewData({
    required this.projectTitle,
    required this.status,
    required this.isLoading,
    required this.modeOptions,
    required this.selectedModeTitle,
    required this.selectedModeDescription,
    required this.progressText,
    required this.isReady,
    required this.stages,
    required this.selectedStageTitle,
    required this.selectedStageDescription,
    required this.selectedStageHelperText,
    required this.selectedStageFieldKey,
    required this.selectedStageAllowFreeText,
    required this.selectedStageValue,
    required this.selectedStageOptions,
    required this.previewSections,
    required this.longTaskLaunch,
  });

  final String projectTitle;
  final String status;
  final bool isLoading;
  final List<InspirationWorkbenchModeOptionViewData> modeOptions;
  final String selectedModeTitle;
  final String selectedModeDescription;
  final String progressText;
  final bool isReady;
  final List<InspirationWorkbenchStageViewData> stages;
  final String selectedStageTitle;
  final String selectedStageDescription;
  final String selectedStageHelperText;
  final String selectedStageFieldKey;
  final bool selectedStageAllowFreeText;
  final String selectedStageValue;
  final List<InspirationWorkbenchOptionViewData> selectedStageOptions;
  final List<InspirationWorkbenchPreviewSectionViewData> previewSections;
  final InspirationWorkbenchLongTaskLaunchViewData longTaskLaunch;

  factory InspirationWorkbenchViewData.initial() {
    return InspirationWorkbenchViewData(
      projectTitle: '',
      status: '请先创建或打开项目。',
      isLoading: false,
      modeOptions: <InspirationWorkbenchModeOptionViewData>[],
      selectedModeTitle: '',
      selectedModeDescription: '',
      progressText: '0/0',
      isReady: false,
      stages: <InspirationWorkbenchStageViewData>[],
      selectedStageTitle: '',
      selectedStageDescription: '',
      selectedStageHelperText: '',
      selectedStageFieldKey: '',
      selectedStageAllowFreeText: false,
      selectedStageValue: '',
      selectedStageOptions: <InspirationWorkbenchOptionViewData>[],
      previewSections: <InspirationWorkbenchPreviewSectionViewData>[],
      longTaskLaunch: InspirationWorkbenchLongTaskLaunchViewData.hidden(),
    );
  }
}
