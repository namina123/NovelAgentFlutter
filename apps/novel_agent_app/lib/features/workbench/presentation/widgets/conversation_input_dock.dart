import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
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
    final surface = context.novelThemeSurfaces.inputDock;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.12),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConversationSendConfigBar(
            modelLabel: modelLabel,
            modelOptions: modelOptions,
            onModelSelected: actionHandler.onModelSelected,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
            child: ConversationComposerTextField(
              controller: controller,
              scrollController: scrollController,
              hintText: hintText,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border(
                top: BorderSide(
                  color: surface.borderColor.withValues(alpha: 0.08),
                  width: AppChrome.borderWidth,
                ),
              ),
            ),
            child: ConversationInputActionRow(
              capabilities: capabilities,
              actionHandler: actionHandler,
              onSendRequested: onSendRequested,
            ),
          ),
        ],
      ),
    );
    if (!showSurface) {
      return content;
    }
    return PanelSurface(
      role: PanelSurfaceRole.inputDock,
      padding: EdgeInsets.zero,
      showBorder: false,
      child: content,
    );
  }
}
