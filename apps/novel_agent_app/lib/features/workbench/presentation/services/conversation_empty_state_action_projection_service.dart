import '../models/primary_action_view_data.dart';
import '../models/workbench_conversation_view_data.dart';

class ConversationEmptyStateActionProjectionService {
  const ConversationEmptyStateActionProjectionService();

  List<PrimaryActionViewData> visibleActions(
    WorkbenchConversationViewData viewData,
  ) {
    if (!viewData.hasActiveProject) {
      return const <PrimaryActionViewData>[];
    }
    final actions = viewData.primaryActions;
    if (actions.isEmpty) {
      return const <PrimaryActionViewData>[];
    }
    final openingState = viewData.openingState;
    if (openingState?.preferSingleAction == true &&
        openingState?.nextAction != null) {
      return <PrimaryActionViewData>[openingState!.nextAction!];
    }
    if (openingState != null) {
      if (openingState.nextAction == null) {
        return const <PrimaryActionViewData>[];
      }
      final guidedActions = _prioritizeGuidedOpeningActions(actions);
      if (guidedActions.isNotEmpty) {
        return guidedActions;
      }
      return <PrimaryActionViewData>[openingState.nextAction!];
    }
    if (_isNaturalNovelWritingPath(viewData, actions)) {
      final prioritized = _prioritizeNovelWritingActions(actions);
      if (prioritized.isNotEmpty) {
        return prioritized;
      }
    }
    if (viewData.openingPanel != null || _hasExplicitGuidedActions(actions)) {
      return _sanitizeActions(actions);
    }
    return <PrimaryActionViewData>[_sanitizeActions(actions).first];
  }

  bool _hasExplicitGuidedActions(List<PrimaryActionViewData> actions) {
    for (final action in actions) {
      final commandId = action.commandId.trim();
      if (commandId.startsWith('guide.') ||
          commandId == 'workspace.open_import_command') {
        return true;
      }
    }
    return false;
  }

  bool _isNaturalNovelWritingPath(
    WorkbenchConversationViewData viewData,
    List<PrimaryActionViewData> actions,
  ) {
    if (viewData.openingPanel != null) {
      return false;
    }
    if (viewData.workflowTitle.contains('长任务') ||
        viewData.workflowDescription.contains('长任务')) {
      return false;
    }
    for (final action in actions) {
      if (action.id.startsWith('session.goal.')) {
        return true;
      }
    }
    return false;
  }

  List<PrimaryActionViewData> _prioritizeNovelWritingActions(
    List<PrimaryActionViewData> actions,
  ) {
    const preferredIds = <String>[
      'session.goal.smart_opening',
      'session.goal.chapter_draft',
      'session.goal.continue_writing',
      'session.goal.summarize_book',
    ];
    final selected = <PrimaryActionViewData>[];
    for (final actionId in preferredIds) {
      for (final action in actions) {
        if (action.id == actionId) {
          selected.add(_humanizeAction(action));
          break;
        }
      }
    }
    return selected;
  }

  List<PrimaryActionViewData> _sanitizeActions(
    List<PrimaryActionViewData> actions,
  ) {
    return actions.map(_humanizeAction).toList(growable: false);
  }

  List<PrimaryActionViewData> _prioritizeGuidedOpeningActions(
    List<PrimaryActionViewData> actions,
  ) {
    final sanitized = _sanitizeActions(actions);
    if (sanitized.length <= 1) {
      return sanitized;
    }
    final focused = sanitized
        .where((action) => action.commandId.trim() != 'guide.back.default')
        .toList(growable: false);
    return focused.isEmpty ? sanitized : focused;
  }

  PrimaryActionViewData _humanizeAction(PrimaryActionViewData action) {
    switch (action.id) {
      case 'session.goal.smart_opening':
        return const PrimaryActionViewData(
          id: 'session.goal.smart_opening',
          title: '写第一章',
          description: '从题材、主角、冲突和第一章钩子出发，把这部作品真正写起来。',
          commandId: 'session.goal',
          payload: <String, Object?>{'mode': 'smart_opening'},
        );
      case 'session.goal.chapter_draft':
        return const PrimaryActionViewData(
          id: 'session.goal.chapter_draft',
          title: '新建章节',
          description: '围绕当前上下文起草一章正文，或先写出一个可继续扩展的关键场景。',
          commandId: 'session.goal',
          payload: <String, Object?>{'mode': 'chapter_draft'},
        );
      case 'session.goal.continue_writing':
        return const PrimaryActionViewData(
          id: 'session.goal.continue_writing',
          title: '续写下一章',
          description: '接着最近章节、场景片段或当前打开内容继续往前推进。',
          commandId: 'session.goal',
          payload: <String, Object?>{'mode': 'continue_writing'},
        );
      case 'session.goal.summarize_book':
        return const PrimaryActionViewData(
          id: 'session.goal.summarize_book',
          title: '整理设定',
          description: '回看已有正文、摘要和资料，整理当前设定脉络与风险。',
          commandId: 'session.goal',
          payload: <String, Object?>{'mode': 'summarize_book'},
        );
      default:
        return action;
    }
  }
}
