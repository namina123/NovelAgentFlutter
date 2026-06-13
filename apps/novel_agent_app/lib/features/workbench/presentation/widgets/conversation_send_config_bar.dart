import 'package:flutter/material.dart';

import '../models/selector_option_view_data.dart';
import 'conversation_model_strip.dart';

class ConversationSendConfigBar extends StatelessWidget {
  const ConversationSendConfigBar({
    super.key,
    required this.modelLabel,
    required this.modelOptions,
    required this.onModelSelected,
  });

  final String modelLabel;
  final List<SelectorOptionViewData> modelOptions;
  final ValueChanged<String> onModelSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth < 280;
        return Padding(
          key: const ValueKey<String>('conversation_send_config_bar'),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: expanded ? double.infinity : 172,
              child: ConversationModelStrip(
                modelLabel: modelLabel,
                modelOptions: modelOptions,
                onModelSelected: onModelSelected,
                showSurface: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
