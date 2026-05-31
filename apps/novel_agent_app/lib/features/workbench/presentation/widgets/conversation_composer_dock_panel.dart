import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_input_capability_state.dart';
import '../models/selector_option_view_data.dart';
import 'conversation_input_dock.dart';

class ConversationComposerDockPanel extends StatelessWidget {
  const ConversationComposerDockPanel({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.hintText,
    required this.capabilities,
    required this.actionHandler,
    required this.onSendRequested,
    required this.modelLabel,
    required this.modelOptions,
    this.showSurface = true,
  });

  final TextEditingController controller;
  final ScrollController scrollController;
  final String hintText;
  final ConversationInputCapabilityState capabilities;
  final ConversationActionHandler actionHandler;
  final VoidCallback onSendRequested;
  final String modelLabel;
  final List<SelectorOptionViewData> modelOptions;
  final bool showSurface;

  @override
  Widget build(BuildContext context) {
    final content = ConversationInputDock(
      controller: controller,
      scrollController: scrollController,
      hintText: hintText,
      capabilities: capabilities,
      actionHandler: actionHandler,
      onSendRequested: onSendRequested,
      modelLabel: modelLabel,
      modelOptions: modelOptions,
      showSurface: false,
    );
    if (!showSurface) {
      return content;
    }
    return PanelSurface(
      role: PanelSurfaceRole.inputDock,
      padding: EdgeInsets.zero,
      child: content,
    );
  }
}
