import 'package:flutter/widgets.dart';

import '../../features/agent_ecosystem/presentation/models/agent_ecosystem_view_data.dart';
import '../../features/long_task_station/presentation/pages/long_task_station_page.dart';
import '../../features/agent_ecosystem/presentation/pages/agent_ecosystem_page.dart';
import '../../features/project_open/presentation/models/project_open_view_data.dart';
import '../../features/project_open/presentation/pages/project_open_page.dart';
import '../../features/project_assets/presentation/pages/project_assets_page.dart';
import '../../features/settings/presentation/models/settings_view_data.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/workbench/presentation/pages/workbench_page.dart';
import '../state/app_shell_controller.dart';
import 'app_destination.dart';

class AppRouter {
  const AppRouter();

  Widget buildPage(AppShellController controller) {
    // 中文注释: 轻量路由器只根据当前目的地选择页面，不在这里保存页面业务状态。
    switch (controller.viewModel.destination) {
      case AppDestination.projectOpen:
        return ValueListenableBuilder<ProjectOpenViewData>(
          valueListenable: controller.projectOpenPageListenable,
          builder: (context, viewData, _) {
            return ProjectOpenPage(
              viewData: viewData,
              actionHandler: controller,
            );
          },
        );
      case AppDestination.workbench:
        return WorkbenchPage(
          resourceListenable: controller.workbenchResourceListenable,
          canvasListenable: controller.workbenchCanvasListenable,
          conversationListenable: controller.workbenchConversationListenable,
          overlayListenable: controller.workbenchOverlayListenable,
          resourceHandler: controller.resourceManagerHandler,
          documentHandler: controller.documentWorkspaceHandler,
          conversationHandler: controller.conversationHandler,
        );
      case AppDestination.agentEcosystem:
        return ValueListenableBuilder<AgentEcosystemViewData>(
          valueListenable: controller.agentEcosystemPageListenable,
          builder: (context, viewData, _) {
            return AgentEcosystemPage(
              viewData: viewData,
              actionHandler: controller,
            );
          },
        );
      case AppDestination.projectAssets:
        return ProjectAssetsPage(
          controller: controller.projectAssetsController,
        );
      case AppDestination.longTaskStation:
        return LongTaskStationPage(
          controller: controller.longTaskStationController,
          onBackRequested: controller.showWorkbench,
        );
      case AppDestination.settings:
        return ValueListenableBuilder<SettingsViewData>(
          valueListenable: controller.settingsPageListenable,
          builder: (context, viewData, _) {
            return SettingsPage(viewData: viewData, actionHandler: controller);
          },
        );
    }
  }
}
