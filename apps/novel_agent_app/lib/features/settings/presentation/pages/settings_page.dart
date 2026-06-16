import 'package:flutter/material.dart';

import '../../../../../app/layout/adaptive_page_frame.dart';
import '../contracts/settings_action_handler.dart';
import '../models/settings_view_data.dart';
import '../widgets/context_settings_panel.dart';
import '../widgets/model_settings_panel.dart';
import '../widgets/network_settings_panel.dart';
import '../widgets/permissions_settings_panel.dart';
import '../widgets/provider_settings_panel.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_overview_panel.dart';
import '../widgets/settings_tab_bar.dart';
import '../widgets/theme_settings_panel.dart';
import '../widgets/tool_strategy_settings_panel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final SettingsViewData viewData;
  final SettingsActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 设置页只装配页头、标签和内容，不把任何具体设置子面板写成一个大文件。
    return AdaptivePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsHeader(
            onBackRequested: actionHandler.onSettingsBackRequested,
          ),
          const SizedBox(height: 18),
          SettingsTabBar(
            tabs: viewData.tabs,
            activeTabId: viewData.activeTabId,
            onTabSelected: actionHandler.onSettingsTabSelected,
          ),
          const SizedBox(height: 18),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // 中文注释: 设置页主体只负责在各个独立设置面板之间分发数据，不把每个子页细节混进一个大 build。
    if (viewData.activeTabId == 'interfaces') {
      return ProviderSettingsPanel(
        providers: viewData.providers,
        providerDirectoryOptions: viewData.providerDirectoryOptions,
        allModelOptions: viewData.allModelOptions,
        onProviderSelected: actionHandler.onProviderSelected,
        onProviderCreateRequested: actionHandler.onProviderCreateRequested,
        onProviderDetailBackRequested:
            actionHandler.onProviderDetailBackRequested,
        onProviderSaved: actionHandler.onProviderSaved,
        onProviderDeleted: actionHandler.onProviderDeleted,
      );
    }
    if (viewData.activeTabId == 'models') {
      return ModelSettingsPanel(
        viewData: viewData,
        onSaved: actionHandler.onModelSettingsSaved,
      );
    }
    if (viewData.activeTabId == 'permissions') {
      return PermissionsSettingsPanel(
        settings: viewData.permissionSettings,
        onSaved: actionHandler.onPermissionSettingsSaved,
      );
    }
    if (viewData.activeTabId == 'tooling') {
      return ToolStrategySettingsPanel(
        settings: viewData.toolStrategySettings,
        onSaved: actionHandler.onToolStrategySettingsSaved,
        projectCreationDefaultsViewData:
            viewData.projectCreationExpressionConstraintDefaults,
        onProjectCreationDefaultsSaved:
            actionHandler.onProjectCreationExpressionConstraintDefaultsSaved,
      );
    }
    if (viewData.activeTabId == 'network') {
      return NetworkSettingsPanel(
        settings: viewData.networkSettings,
        onSaved: actionHandler.onNetworkSettingsSaved,
      );
    }
    if (viewData.activeTabId == 'context') {
      return ContextSettingsPanel(
        settings: viewData.contextSettings,
        defaultProjectPath: viewData.defaultProjectPath,
        draftFallbackProtectionEnabled: viewData.draftFallbackProtectionEnabled,
        allowProjectPathEdit: !viewData.isMobileProjectRootLocked,
        onSaved: actionHandler.onContextSettingsSaved,
      );
    }
    if (viewData.activeTabId == 'theme') {
      return ThemeSettingsPanel(
        viewData: viewData.themeViewData,
        onSaved: actionHandler.onThemeSettingsSaved,
      );
    }
    final sections = viewData.tabSections[viewData.activeTabId] ?? const [];
    return SettingsOverviewPanel(sections: sections);
  }
}
