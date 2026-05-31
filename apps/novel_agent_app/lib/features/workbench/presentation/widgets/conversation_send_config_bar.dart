import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
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
    final colors = context.novelThemeColors;
    return Container(
      key: const ValueKey<String>('conversation_send_config_bar'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.lineColor.withValues(alpha: 0.9),
            width: AppChrome.borderWidth,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConversationModelStrip(
          modelLabel: modelLabel,
          modelOptions: modelOptions,
          onModelSelected: onModelSelected,
          showSurface: false,
        ),
      ),
    );
  }
}
