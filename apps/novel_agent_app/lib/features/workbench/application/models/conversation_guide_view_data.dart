import '../../presentation/models/primary_action_view_data.dart';

class ConversationGuideViewData {
  const ConversationGuideViewData({
    required this.workflowTitle,
    required this.workflowDescription,
    required this.composerHint,
    required this.primaryActions,
  });

  final String workflowTitle;
  final String workflowDescription;
  final String composerHint;
  final List<PrimaryActionViewData> primaryActions;
}
