import 'package:flutter/material.dart';

import 'scroll/app_scroll_behavior.dart';
import 'theme/app_theme.dart';
import '../shared/widgets/app_shell.dart';
import 'state/app_shell_controller.dart';

class NovelAgentApp extends StatelessWidget {
  const NovelAgentApp({super.key, required this.controller});

  final AppShellController controller;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 应用根组件现在只监听主题变化，避免工作台局部流式更新把整棵 MaterialApp 一起拖进重建。
    return ValueListenableBuilder<String>(
      valueListenable: controller.activeThemeIdListenable,
      builder: (context, themeId, _) {
        return MaterialApp(
          title: 'NovelAgent',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeDataFor(themeId),
          scrollBehavior: const AppScrollBehavior(),
          home: AppShell(controller: controller),
        );
      },
    );
  }
}
