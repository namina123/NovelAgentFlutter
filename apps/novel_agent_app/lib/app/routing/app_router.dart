import 'package:flutter/widgets.dart';

import '../state/app_shell_controller.dart';
import 'app_shell_page_host.dart';
import 'app_shell_page_registry.dart';

class AppRouter {
  const AppRouter();

  Widget buildPageHost(AppShellController controller) {
    // 中文注释: 路由器不再返回单页，而是返回稳定驻留宿主，让已访问页面保留状态树。
    return AppShellPageHost(
      selectedDestination: controller.viewModel.destination,
      pageDescriptors: AppShellPageRegistry().build(controller),
    );
  }
}
