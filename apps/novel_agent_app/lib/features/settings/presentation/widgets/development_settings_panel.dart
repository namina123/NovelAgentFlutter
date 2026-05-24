import 'package:flutter/material.dart';

import '../models/settings_view_data.dart';
import 'settings_overview_panel.dart';

class DevelopmentSettingsPanel extends StatelessWidget {
  const DevelopmentSettingsPanel({super.key, required this.viewData});

  final SettingsViewData viewData;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 开发页当前只展示宿主路径和搜索根，避免把系统目录编辑入口暴露到移动端工作流里。
    return SettingsOverviewPanel(
      sections: viewData.tabSections['dev'] ?? const [],
    );
  }
}
