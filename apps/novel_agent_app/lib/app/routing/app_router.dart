import 'package:flutter/widgets.dart';

import '../../features/agent_ecosystem/presentation/pages/agent_ecosystem_page.dart';
import '../../features/long_task_station/presentation/pages/long_task_station_page.dart';
import '../../features/project_assets/presentation/pages/project_assets_page.dart';
import '../../features/prompt_templates/presentation/pages/prompt_templates_page.dart';
import '../../features/project_collection/presentation/pages/project_collection_page.dart';
import '../../features/review_center/presentation/pages/review_center_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/task_center/presentation/pages/task_center_page.dart';
import '../../features/workbench/presentation/pages/workbench_page.dart';
import '../state/app_shell_controller.dart';
import 'app_destination.dart';

class AppRouter {
  const AppRouter();

  Widget buildPage(AppShellController controller) {
    // 中文注释: 轻量路由器只根据当前目的地选择页面，不在这里保存页面业务状态。
    switch (controller.viewModel.destination) {
      case AppDestination.workbench:
        return WorkbenchPage(
          viewData: controller.viewModel.workbench,
          resourceHandler: controller.resourceManagerHandler,
          documentHandler: controller.documentWorkspaceHandler,
          conversationHandler: controller.conversationHandler,
        );
      case AppDestination.longTaskStation:
        return LongTaskStationPage(
          controller: controller.longTaskStationController,
          onBackRequested: controller.showWorkbench,
        );
      case AppDestination.settings:
        return SettingsPage(
          viewData: controller.viewModel.settings,
          actionHandler: controller,
        );
      case AppDestination.agentEcosystem:
        return AgentEcosystemPage(
          viewData: controller.viewModel.agentEcosystem,
          actionHandler: controller,
        );
      case AppDestination.projectCollection:
        return ProjectCollectionPage(
          viewData: controller.viewModel.projectCollection,
          actionHandler: controller,
        );
      case AppDestination.taskCenter:
        return TaskCenterPage(
          viewData: controller.viewModel.taskCenter,
          actionHandler: controller,
        );
      case AppDestination.reviewCenter:
        return ReviewCenterPage(
          viewData: controller.viewModel.reviewCenter,
          actionHandler: controller,
        );
      case AppDestination.promptTemplates:
        return PromptTemplatesPage(
          viewData: controller.viewModel.promptTemplates,
          actionHandler: controller,
        );
      case AppDestination.projectAssets:
        return ProjectAssetsPage(
          viewData: controller.viewModel.projectAssets,
          actionHandler: controller,
        );
    }
  }
}
