import 'package:flutter/foundation.dart';

import 'primary_action_view_data.dart';

@immutable
class ConversationOpeningStateViewData {
  const ConversationOpeningStateViewData({
    required this.firstPrompt,
    required this.nextStepLabel,
    required this.hasProjectFoundation,
    required this.hasResolvedGroup,
    required this.missingRequirementTitles,
    required this.preferSingleAction,
    this.nextAction,
  });

  final String firstPrompt;
  final String nextStepLabel;
  final bool hasProjectFoundation;
  final bool hasResolvedGroup;
  final List<String> missingRequirementTitles;
  final bool preferSingleAction;
  final PrimaryActionViewData? nextAction;

  bool get hasMissingRequirements => missingRequirementTitles.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConversationOpeningStateViewData &&
            other.firstPrompt == firstPrompt &&
            other.nextStepLabel == nextStepLabel &&
            other.hasProjectFoundation == hasProjectFoundation &&
            other.hasResolvedGroup == hasResolvedGroup &&
            listEquals(other.missingRequirementTitles, missingRequirementTitles) &&
            other.preferSingleAction == preferSingleAction &&
            other.nextAction == nextAction;
  }

  @override
  int get hashCode => Object.hash(
    firstPrompt,
    nextStepLabel,
    hasProjectFoundation,
    hasResolvedGroup,
    Object.hashAll(missingRequirementTitles),
    preferSingleAction,
    nextAction,
  );
}
