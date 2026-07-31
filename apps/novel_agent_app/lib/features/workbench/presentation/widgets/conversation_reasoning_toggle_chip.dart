import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

class ConversationReasoningToggleChip extends StatelessWidget {
  const ConversationReasoningToggleChip({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  static const containerKey = ValueKey<String>(
    'conversation_reasoning_toggle_chip',
  );

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    final backgroundColor = enabled
        ? colors.accentSoftColor.withValues(alpha: 0.68)
        : surface.backgroundColor.withValues(alpha: 0.9);
    final borderColor = enabled
        ? colors.accentColor.withValues(alpha: 0.54)
        : surface.borderColor.withValues(alpha: 0.72);
    final foregroundColor = enabled
        ? colors.lineStrongColor
        : colors.mutedTextColor;
    final iconBackgroundColor = enabled
        ? colors.accentColor.withValues(alpha: 0.14)
        : colors.panelBackground.withValues(alpha: 0.82);
    final iconColor = enabled ? colors.accentColor : colors.lineStrongColor;

    return Semantics(
      button: true,
      toggled: enabled,
      label: '深度思考',
      child: Tooltip(
        message: '深度思考：更慢、更细致，但会耗用更多上下文与时间。',
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: containerKey,
            borderRadius: BorderRadius.circular(surface.radius),
            onTap: () => onChanged(!enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(surface.radius),
                border: Border.all(
                  color: borderColor,
                  width: surface.borderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      size: 13,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '深度思考',
                    style: TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: enabled
                          ? colors.accentColor.withValues(alpha: 0.1)
                          : colors.panelBackground.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      enabled ? '开' : '关',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.08,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
