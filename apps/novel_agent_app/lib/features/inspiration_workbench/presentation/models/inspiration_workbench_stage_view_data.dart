import 'inspiration_workbench_option_view_data.dart';

class InspirationWorkbenchStageViewData {
  const InspirationWorkbenchStageViewData({
    required this.id,
    required this.title,
    required this.description,
    required this.helperText,
    required this.answerPreview,
    required this.isSelected,
    required this.isCompleted,
    required this.isCurrent,
    required this.allowFreeText,
    required this.fieldKey,
    required this.answerOptions,
  });

  final String id;
  final String title;
  final String description;
  final String helperText;
  final String answerPreview;
  final bool isSelected;
  final bool isCompleted;
  final bool isCurrent;
  final bool allowFreeText;
  final String fieldKey;
  final List<InspirationWorkbenchOptionViewData> answerOptions;
}
