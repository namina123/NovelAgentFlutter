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
        ? colors.accentColor
        : surface.backgroundColor.withValues(alpha: 0.96);
    final borderColor = enabled ? colors.accentColor : surface.borderColor;
    final foregroundColor = enabled
        ? colors.inverseTextColor
        : colors.mutedTextColor;
    final iconBackgroundColor = enabled
        ? colors.inverseTextColor.withValues(alpha: 0.18)
        : colors.accentSoftColor.withValues(alpha: 0.72);
    final iconColor = enabled ? colors.inverseTextColor : colors.accentColor;

    return Semantics(
      button: true,
      toggled: enabled,
      label: '深度思考',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: containerKey,
          borderRadius: BorderRadius.circular(surface.radius),
          onTap: () => onChanged(!enabled),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_alt_rounded,
                    size: 12,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '深度思考',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
