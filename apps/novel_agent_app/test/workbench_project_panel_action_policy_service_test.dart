import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_project_panel_action_policy_service.dart';

void main() {
  test('项目类型转换入口只对 novel 与 long_novel 开放', () {
    // 中文注释: 这条回归把项目类型转换入口锁在第一阶段写作项目里，避免资料知识库暴露错误动作。
    const service = WorkbenchProjectPanelActionPolicyService();

    final novelActions = service.primaryActions(
      hasActiveProject: true,
      projectTypeId: 'novel',
    );
    final longNovelActions = service.primaryActions(
      hasActiveProject: true,
      projectTypeId: 'long_novel',
    );
    final knowledgeBaseActions = service.primaryActions(
      hasActiveProject: true,
      projectTypeId: 'knowledge_base',
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
      knowledgeBaseActions.any(
        (action) =>
            action.actionId ==
            WorkbenchProjectPanelActionIds.transitionProjectType,
      ),
      isFalse,
    );
  });
}
