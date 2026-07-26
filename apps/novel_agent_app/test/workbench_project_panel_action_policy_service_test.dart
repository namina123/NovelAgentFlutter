import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_project_panel_action_policy_service.dart';

void main() {
  test('项目类型转换入口在宿主可用时只对 novel 与 long_novel 开放', () {
    // 中文注释: 这条回归把项目类型转换入口锁在第一阶段写作项目里，并确认宿主未接线时会前置隐藏。
    const service = WorkbenchProjectPanelActionPolicyService();
    final available = EntryAvailabilityDecision.available(
      entryId: 'workspace.transition_project_type',
    );
    final hidden = EntryAvailabilityDecision.hidden(
      entryId: 'workspace.transition_project_type',
    );

    final novelActions = service.primaryActions(
      hasActiveProject: true,
      projectTypeId: 'novel',
      projectTypeTransitionAvailability: available,
    );
    final longNovelActions = service.primaryActions(
      hasActiveProject: true,
      projectTypeId: 'long_novel',
      projectTypeTransitionAvailability: available,
    );
    final knowledgeBaseActions = service.primaryActions(
      hasActiveProject: true,
      projectTypeId: 'knowledge_base',
      projectTypeTransitionAvailability: available,
    );
    final hiddenNovelActions = service.primaryActions(
      hasActiveProject: true,
      projectTypeId: 'novel',
      projectTypeTransitionAvailability: hidden,
    );

    expect(
      novelActions.any(
        (action) =>
            action.actionId ==
            WorkbenchProjectPanelActionIds.transitionProjectType,
      ),
      isTrue,
    );
    expect(
      novelActions
          .firstWhere(
            (action) =>
                action.actionId ==
                WorkbenchProjectPanelActionIds.transitionProjectType,
          )
          .description,
      contains('长篇长任务'),
    );

    expect(
      longNovelActions.any(
        (action) =>
            action.actionId ==
            WorkbenchProjectPanelActionIds.transitionProjectType,
      ),
      isTrue,
    );
    expect(
      longNovelActions
          .firstWhere(
            (action) =>
                action.actionId ==
                WorkbenchProjectPanelActionIds.transitionProjectType,
          )
          .description,
      contains('普通小说'),
    );
    expect(
      longNovelActions.any(
        (action) =>
            action.actionId ==
            WorkbenchProjectPanelActionIds.configureRuntimeBaseline,
      ),
      isTrue,
    );
    expect(
      novelActions.any(
        (action) =>
            action.actionId ==
            WorkbenchProjectPanelActionIds.configureRuntimeBaseline,
      ),
      isFalse,
    );

    expect(
      knowledgeBaseActions.any(
        (action) =>
            action.actionId ==
            WorkbenchProjectPanelActionIds.transitionProjectType,
      ),
      isFalse,
    );
    expect(
      hiddenNovelActions.any(
        (action) =>
            action.actionId ==
            WorkbenchProjectPanelActionIds.transitionProjectType,
      ),
      isFalse,
    );
  });
}
