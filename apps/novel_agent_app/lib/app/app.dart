import 'package:flutter/material.dart';

import '../shared/widgets/app_shell.dart';
import 'state/app_shell_controller.dart';
import 'theme/app_theme.dart';

class NovelAgentApp extends StatelessWidget {
  const NovelAgentApp({super.key, required this.controller});

  final AppShellController controller;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 应用根组件只负责根据控制器切换主题和挂载根壳层，不在这里处理页面业务状态。
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'NovelAgent',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: controller.themeMode,
          home: AppShell(controller: controller),
        );
      },
    );
  }
}
