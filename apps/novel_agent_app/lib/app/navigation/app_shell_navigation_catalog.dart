import 'package:flutter/material.dart';

import '../routing/app_destination.dart';
import 'app_shell_navigation_item.dart';
import 'app_shell_navigation_section.dart';

class AppShellNavigationCatalog {
  const AppShellNavigationCatalog._();

  static List<AppShellNavigationSection> sections() {
    return const <AppShellNavigationSection>[
      AppShellNavigationSection(
        id: 'project',
        label: '项目',
        items: <AppShellNavigationItem>[
          AppShellNavigationItem(
            destination: AppDestination.projectOpen,
            label: '作品库',
            tooltip: '作品库',
            icon: Icons.folder_open_outlined,
          ),
        ],
      ),
      AppShellNavigationSection(
        id: 'workspace',
        label: '创作',
        items: <AppShellNavigationItem>[
          AppShellNavigationItem(
            destination: AppDestination.workbench,
            label: '创作台',
            tooltip: '创作台',
            icon: Icons.space_dashboard_outlined,
          ),
          AppShellNavigationItem(
            destination: AppDestination.agentEcosystem,
            label: '智能体生态',
            tooltip: '智能体生态',
            icon: Icons.hub_outlined,
          ),
        ],
      ),
      AppShellNavigationSection(
        id: 'runtime',
        label: '运行',
        items: <AppShellNavigationItem>[
          AppShellNavigationItem(
            destination: AppDestination.longTaskStation,
            label: '长任务',
            tooltip: '长任务总站',
            icon: Icons.route_outlined,
          ),
        ],
      ),
      AppShellNavigationSection(
        id: 'system',
        label: '系统',
        items: <AppShellNavigationItem>[
          AppShellNavigationItem(
            destination: AppDestination.settings,
            label: '设置',
            tooltip: '设置',
            icon: Icons.settings_outlined,
          ),
        ],
      ),
    ];
  }

  static AppShellNavigationItem? findItem(AppDestination destination) {
    // 中文注释: 紧凑布局和标题条都要复用同一份导航元数据，避免在多个组件里重复维护映射。
    for (final section in sections()) {
      for (final item in section.items) {
        if (item.destination == destination) {
          return item;
        }
      }
    }
    return null;
  }

  static AppShellNavigationSection? findSection(AppDestination destination) {
    // 中文注释: 当前页面所属分组由目录统一提供，避免顶部条和抽拉栏各自猜测分类。
    for (final section in sections()) {
      for (final item in section.items) {
        if (item.destination == destination) {
          return section;
        }
      }
    }
    return null;
  }
}
