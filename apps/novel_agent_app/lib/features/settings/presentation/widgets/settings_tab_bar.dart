import 'package:flutter/material.dart';

import '../models/settings_view_data.dart';

class SettingsTabBar extends StatelessWidget {
  const SettingsTabBar({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.onTabSelected,
  });

  final List<SettingsTabViewData> tabs;
  final String activeTabId;
  final ValueChanged<String> onTabSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 设置标签条拆开后，后续切成滚动标签或分组标签时不需要改页面主体结构。
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: tabs
            .map(
              (tab) =>
                  ButtonSegment<String>(value: tab.id, label: Text(tab.label)),
            )
            .toList(),
        selected: {activeTabId},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          // 中文注释: tab 变化只回传选中的 id，由外层控制器统一更新视图模型。
          onTabSelected(selection.first);
        },
      ),
    );
  }
}
