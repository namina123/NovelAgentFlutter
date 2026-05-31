import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_input_capability_state.dart';
import '../models/workbench_conversation_view_data.dart';
import 'conversation_composer_dock_panel.dart';

class ConversationComposerPanel extends StatelessWidget {
  const ConversationComposerPanel({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.hintText,
    required this.capabilities,
    required this.viewData,
    required this.actionHandler,
    required this.onSendRequested,
  });

  final TextEditingController controller;
  final ScrollController scrollController;
  final String hintText;
  final ConversationInputCapabilityState capabilities;
  final WorkbenchConversationViewData viewData;
  final ConversationActionHandler actionHandler;
  final VoidCallback onSendRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工具状态 chips 已退出主界面；连续 composer 面板现在只承接输入坞。
    final colors = context.novelThemeColors;
    return PanelSurface(
      role: PanelSurfaceRole.inputDock,
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.lineColor.withValues(alpha: 0.9),
              width: AppChrome.borderWidth,
            ),
          ),
        ),
        child: ConversationComposerDockPanel(
          controller: controller,
          scrollController: scrollController,
          hintText: hintText,
          capabilities: capabilities,
          actionHandler: actionHandler,
          onSendRequested: onSendRequested,
          modelLabel: viewData.modelLabel,
          modelOptions: viewData.modelOptions,
          showSurface: false,
        ),
      ),
    );
  }
}
