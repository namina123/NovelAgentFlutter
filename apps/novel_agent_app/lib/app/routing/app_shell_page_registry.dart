import 'package:flutter/widgets.dart';

import '../../features/agent_ecosystem/presentation/models/agent_ecosystem_view_data.dart';
import '../../features/agent_ecosystem/presentation/pages/agent_ecosystem_page.dart';
import '../../features/book_deconstruction/presentation/pages/book_deconstruction_page.dart';
import '../../features/long_task_station/presentation/pages/long_task_station_page.dart';
import '../../features/project_assets/presentation/pages/project_assets_page.dart';
import '../../features/project_open/presentation/models/project_open_view_data.dart';
import '../../features/project_open/presentation/pages/project_open_page.dart';
import '../../features/settings/presentation/models/settings_view_data.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/task_center/presentation/models/task_center_view_data.dart';
import '../../features/task_center/presentation/pages/task_center_page.dart';
import '../../features/workbench/presentation/pages/workbench_page.dart';
import '../state/app_shell_controller.dart';
import 'app_destination.dart';
import 'app_shell_page_descriptor.dart';

class AppShellPageRegistry {
  const AppShellPageRegistry();

  List<AppShellPageDescriptor> build(AppShellController controller) {
    // 中文注释: 页面注册表只负责把稳定的 destination 顺序和具体页面构建器对应起来，不参与路由判断。
    return <AppShellPageDescriptor>[
      AppShellPageDescriptor(
        destination: AppDestination.projectOpen,
        builder: (context) => ValueListenableBuilder<ProjectOpenViewData>(
          valueListenable: controller.projectOpenPageListenable,
          builder: (context, viewData, _) {
            return ProjectOpenPage(
              viewData: viewData,
              actionHandler: controller,
            );
          },
        ),
      ),
      AppShellPageDescriptor(
        destination: AppDestination.workbench,
        builder: (context) => WorkbenchPage(
          resourceListenable: controller.workbenchResourceListenable,
          canvasListenable: controller.workbenchCanvasListenable,
          conversationListenable: controller.workbenchConversationListenable,
          overlayListenable: controller.workbenchOverlayListenable,
          resourceHandler: controller.resourceManagerHandler,
          documentHandler: controller.documentWorkspaceHandler,
          conversationHandler: controller.conversationHandler,
        ),
      ),
      AppShellPageDescriptor(
        destination: AppDestination.bookDeconstruction,
        builder: (context) => BookDeconstructionPage(
          controller: controller.bookDeconstructionController,
        ),
      ),
      AppShellPageDescriptor(
        destination: AppDestination.agentEcosystem,
        builder: (context) => ValueListenableBuilder<AgentEcosystemViewData>(
          valueListenable: controller.agentEcosystemPageListenable,
          builder: (context, viewData, _) {
            return AgentEcosystemPage(
              viewData: viewData,
              actionHandler: controller,
            );
          },
        ),
      ),
      AppShellPageDescriptor(
        destination: AppDestination.projectAssets,
        builder: (context) => ProjectAssetsPage(
          controller: controller.projectAssetsController,
        ),
      ),
      AppShellPageDescriptor(
        destination: AppDestination.longTaskStation,
        builder: (context) => LongTaskStationPage(
          controller: controller.longTaskStationController,
          onBackRequested: controller.showWorkbench,
        ),
      ),
      AppShellPageDescriptor(
        destination: AppDestination.taskCenter,
        builder: (context) => ValueListenableBuilder<TaskCenterViewData>(
          valueListenable: controller.taskCenterPageListenable,
          builder: (context, viewData, _) {
            return TaskCenterPage(
              viewData: viewData,
              actionHandler: controller,
            );
          },
        ),
      ),
      AppShellPageDescriptor(
        destination: AppDestination.settings,
        builder: (context) => ValueListenableBuilder<SettingsViewData>(
          valueListenable: controller.settingsPageListenable,
          builder: (context, viewData, _) {
            return SettingsPage(
              viewData: viewData,
              actionHandler: controller,
            );
          },
        ),
      ),
    ];
  }
}
