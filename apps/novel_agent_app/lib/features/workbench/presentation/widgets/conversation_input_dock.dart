import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_input_capability_state.dart';
import '../models/selector_option_view_data.dart';
import 'conversation_composer_text_field.dart';
import 'conversation_input_action_row.dart';
import 'conversation_send_config_bar.dart';

class ConversationInputDock extends StatelessWidget {
  const ConversationInputDock({
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
    // 中文注释: 输入坞负责统一文本输入表面和动作栏，后续接附件或真正停止链时不需要再改侧栏骨架。
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConversationSendConfigBar(
          modelLabel: modelLabel,
          modelOptions: modelOptions,
          onModelSelected: actionHandler.onModelSelected,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConversationComposerTextField(
                controller: controller,
                scrollController: scrollController,
                hintText: hintText,
              ),
              const SizedBox(height: 8),
              ConversationInputActionRow(
                capabilities: capabilities,
                actionHandler: actionHandler,
                onSendRequested: onSendRequested,
              ),
            ],
          ),
        ),
      ],
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
