import '../models/project_opening_maturity_assessment.dart';
import '../../presentation/models/primary_action_view_data.dart';

class OpeningStarterActionPolicyService {
  const OpeningStarterActionPolicyService();

  List<PrimaryActionViewData> apply({
    required String projectType,
    required ProjectOpeningMaturityAssessment maturity,
    required List<PrimaryActionViewData> actions,
  }) {
    if (actions.isEmpty) {
      return const <PrimaryActionViewData>[];
    }
    switch (projectType.trim()) {
      case 'long_novel':
        return maturity.shouldShowOpeningEntry
            ? _selectByCommandIds(actions, const <String>[
                'guide.open_long_task_modes',
              ])
            : _selectByCommandIds(actions, const <String>[
                'long_task.run_next',
                'long_task.run_controlled',
                'long_task.open_detail',
              ], fallback: actions);
      case 'novel':
        return maturity.shouldShowOpeningEntry
            ? _selectByActionIds(actions, const <String>[
                'session.goal.smart_opening',
                'session.goal.import_article',
              ])
            : _selectByActionIds(actions, const <String>[
                'session.goal.continue_writing',
                'session.goal.chapter_draft',
                'session.goal.summarize_book',
                'session.goal.import_article',
              ], fallback: actions);
      default:
        return actions;
    }
  }

  List<PrimaryActionViewData> _selectByCommandIds(
    List<PrimaryActionViewData> actions,
    List<String> commandIds, {
    List<PrimaryActionViewData>? fallback,
  }) {
    final selected = <PrimaryActionViewData>[];
    for (final commandId in commandIds) {
      for (final action in actions) {
        if (action.commandId == commandId) {
          selected.add(action);
          break;
        }
      }
    }
    if (selected.isEmpty) {
      return fallback ?? actions;
    }
    return List<PrimaryActionViewData>.unmodifiable(selected);
  }

  List<PrimaryActionViewData> _selectByActionIds(
    List<PrimaryActionViewData> actions,
    List<String> actionIds, {
    List<PrimaryActionViewData>? fallback,
  }) {
    final selected = <PrimaryActionViewData>[];
    for (final actionId in actionIds) {
      for (final action in actions) {
        if (action.id == actionId) {
          selected.add(action);
          break;
        }
      }
    }
    if (selected.isEmpty) {
      return fallback ?? actions;
    }
    return List<PrimaryActionViewData>.unmodifiable(selected);
  }
}
