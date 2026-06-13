import 'package:flutter/material.dart';

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
    return ConversationComposerDockPanel(
      controller: controller,
      scrollController: scrollController,
      hintText: hintText,
      capabilities: capabilities,
      actionHandler: actionHandler,
      onSendRequested: onSendRequested,
      modelLabel: viewData.modelLabel,
      modelOptions: viewData.modelOptions,
      showSurface: true,
    );
  }
}
