import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import 'conversation_panel_style.dart';

class ConversationPanelBand extends StatelessWidget {
  const ConversationPanelBand({
    super.key,
    required this.leadingIcon,
    required this.child,
    this.trailing,
    this.emphasized = false,
    this.onTap,
  });

  final IconData leadingIcon;
  final Widget child;
  final Widget? trailing;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = ConversationPanelStyle.of(context);
    final foreground = emphasized
        ? style.accentBandForegroundColor
        : style.foregroundColor;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? style.accentBandBackgroundColor
            : style.bandBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: style.bandBorderColor,
          width: AppChrome.borderWidth,
        ),
      ),
      child: Padding(
        padding: style.bandPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(leadingIcon, size: 14, color: foreground),
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }
}
