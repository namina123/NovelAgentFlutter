import '../../presentation/models/primary_action_view_data.dart';
import '../../presentation/models/conversation_opening_state_view_data.dart';

class ConversationGuideViewData {
  const ConversationGuideViewData({
    required this.workflowTitle,
    required this.workflowDescription,
    required this.composerHint,
    required this.primaryActions,
    this.openingState,
  });

  final String workflowTitle;
  final String workflowDescription;
  final String composerHint;
  final List<PrimaryActionViewData> primaryActions;
  final ConversationOpeningStateViewData? openingState;

  ConversationGuideViewData copyWith({
    String? workflowTitle,
    String? workflowDescription,
    String? composerHint,
    List<PrimaryActionViewData>? primaryActions,
    Object? openingState = _openingStateSentinel,
  }) {
    return ConversationGuideViewData(
      workflowTitle: workflowTitle ?? this.workflowTitle,
      workflowDescription: workflowDescription ?? this.workflowDescription,
      composerHint: composerHint ?? this.composerHint,
      primaryActions: primaryActions ?? this.primaryActions,
      openingState: identical(openingState, _openingStateSentinel)
          ? this.openingState
          : openingState as ConversationOpeningStateViewData?,
    );
  }
}

const Object _openingStateSentinel = Object();
