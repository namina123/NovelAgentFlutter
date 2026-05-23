import 'package:flutter/widgets.dart';

import '../../features/agent_ecosystem/presentation/pages/agent_ecosystem_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
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
          resourceHandler: controller,
          documentHandler: controller,
          conversationHandler: controller,
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
    }
  }
}
