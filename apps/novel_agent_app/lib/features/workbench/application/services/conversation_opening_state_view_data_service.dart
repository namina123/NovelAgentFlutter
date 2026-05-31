import '../models/opening_session_projection.dart';
import '../models/project_opening_maturity_assessment.dart';
import '../../presentation/models/conversation_opening_state_view_data.dart';
import '../../presentation/models/primary_action_view_data.dart';

class ConversationOpeningStateViewDataService {
  const ConversationOpeningStateViewDataService();

  ConversationOpeningStateViewData build({
    required String projectType,
    required ProjectOpeningMaturityAssessment maturity,
    required List<PrimaryActionViewData> primaryActions,
    OpeningSessionProjection? projection,
    PrimaryActionViewData? preferredNextAction,
    String firstPromptOverride = '',
    String nextStepLabelOverride = '',
    bool preferSingleAction = false,
  }) {
    final hasProjectFoundation =
        maturity.authoredFoundationFileCount > 0 ||
        maturity.narrativeFileCount > 0 ||
        maturity.isContinueReady;
    final hasResolvedGroup =
        projection == null
            ? !maturity.shouldShowOpeningEntry
            : projection.currentGroupDisplayName.trim().isNotEmpty ||
                  projection.currentGroupId.trim().isNotEmpty;
    final missingRequirementTitles =
        projection?.orchestration.readiness.missingRequirements
            .map((item) => item.title.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    final nextAction =
        preferredNextAction ??
        (primaryActions.isEmpty ? null : primaryActions.first);
    final resolvedFirstPrompt = firstPromptOverride.trim().isNotEmpty
        ? firstPromptOverride.trim()
        : _firstPromptOf(
            projectType: projectType,
            maturity: maturity,
            hasProjectFoundation: hasProjectFoundation,
            hasResolvedGroup: hasResolvedGroup,
            missingRequirementTitles: missingRequirementTitles,
          );
    final nextStepLabel = nextStepLabelOverride.trim().isNotEmpty
        ? nextStepLabelOverride.trim()
        : _nextStepLabelOf(
            nextAction: nextAction,
            hasResolvedGroup: hasResolvedGroup,
            missingRequirementTitles: missingRequirementTitles,
          );
    final shouldPreferSingleAction =
        preferSingleAction ||
        (nextAction != null &&
            primaryActions.length <= 1 &&
            missingRequirementTitles.isEmpty);
    return ConversationOpeningStateViewData(
      firstPrompt: resolvedFirstPrompt,
      nextStepLabel: nextStepLabel,
      hasProjectFoundation: hasProjectFoundation,
      hasResolvedGroup: hasResolvedGroup,
      missingRequirementTitles: missingRequirementTitles,
      preferSingleAction: shouldPreferSingleAction,
      nextAction: nextAction,
    );
  }

  String _firstPromptOf({
    required String projectType,
    required ProjectOpeningMaturityAssessment maturity,
    required bool hasProjectFoundation,
    required bool hasResolvedGroup,
    required List<String> missingRequirementTitles,
  }) {
    if (!hasResolvedGroup) {
      return '先确认一个适用于当前项目的智能体组。';
    }
    if (missingRequirementTitles.isNotEmpty) {
      return projectType.trim() == 'long_novel'
          ? '先补齐长任务开局缺口。'
          : '先补齐当前开局缺口。';
    }
    if (maturity.isContinueReady || hasProjectFoundation) {
      return '直接告诉智能体你现在要继续推进什么。';
    }
    return projectType.trim() == 'long_novel'
        ? '先把这部长篇怎么开局说清楚。'
        : '先用一句话说明你想让智能体怎么开始。';
  }

  String _nextStepLabelOf({
    required PrimaryActionViewData? nextAction,
    required bool hasResolvedGroup,
    required List<String> missingRequirementTitles,
  }) {
    if (!hasResolvedGroup) {
      return '确认项目智能体组';
    }
    if (missingRequirementTitles.isNotEmpty) {
      return '补齐关键开局信息';
    }
    if (nextAction != null) {
      return nextAction.title;
    }
    return '直接输入当前目标';
  }
}
