import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

class AgentGroupOptionCard extends StatelessWidget {
  const AgentGroupOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.isCurrent,
    required this.isSelectable,
    required this.isDegraded,
    this.extraBadges = const <String>[],
    this.reasonSummary = '',
    this.reasonDetails = const <String>[],
    this.onPressed,
  });

  final String title;
  final String description;
  final bool isCurrent;
  final bool isSelectable;
  final bool isDegraded;
  final List<String> extraBadges;
  final String reasonSummary;
  final List<String> reasonDetails;
  final VoidCallback? onPressed;

  bool get _hasReasonSummary => reasonSummary.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final radius = context.novelPanelChrome.radius;
    final active = isSelectable && isCurrent;
    final disabled = !isSelectable;
    final backgroundColor = disabled
        ? colors.inputBackground.withValues(alpha: 0.42)
        : active
        ? colors.accentSoftColor.withValues(alpha: 0.72)
        : colors.inputBackground.withValues(alpha: 0.56);
    final borderColor = active
        ? colors.lineStrongColor
        : disabled
        ? colors.lineColor.withValues(alpha: 0.92)
        : colors.lineColor;
    final titleColor = disabled
        ? colors.textColor.withValues(alpha: 0.72)
        : colors.textColor;
    final descriptionColor = disabled
        ? colors.mutedTextColor.withValues(alpha: 0.88)
        : colors.mutedTextColor;
    final reasonColor = disabled
        ? colors.textColor.withValues(alpha: 0.74)
        : colors.textColor;
    final leadingColor = active
        ? colors.lineStrongColor
        : disabled
        ? colors.mutedTextColor
        : colors.mutedTextColor;

    final cardChild = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor,
          width: active ? 1.2 : context.novelPanelChrome.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_leadingIcon(), size: 20, color: leadingColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      if (isCurrent)
                        _CardTagChip(
                          label: '当前',
                          foregroundColor: active
                              ? colors.lineStrongColor
                              : colors.textColor,
                          backgroundColor: active
                              ? colors.accentSoftColor
                              : colors.inputBackground.withValues(alpha: 0.72),
                          borderColor: borderColor,
                        ),
                      if (isDegraded)
                        _CardTagChip(
                          label: '降级可用',
                          foregroundColor: colors.mutedTextColor,
                          backgroundColor: colors.inputBackground.withValues(
                            alpha: 0.72,
                          ),
                          borderColor: colors.lineColor,
                        ),
                      ...extraBadges.map(
                        (badge) => _CardTagChip(
                          label: badge,
                          foregroundColor: colors.textColor,
                          backgroundColor: colors.inputBackground.withValues(
                            alpha: 0.72,
                          ),
                          borderColor: colors.lineColor,
                        ),
                      ),
                      if (disabled)
                        _CardTagChip(
                          label: '当前不可用',
                          foregroundColor: colors.mutedTextColor,
                          backgroundColor: colors.inputBackground.withValues(
                            alpha: 0.64,
                          ),
                          borderColor: colors.lineColor.withValues(alpha: 0.92),
                        ),
                    ],
                  ),
                  if (description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: descriptionColor,
                      ),
                    ),
                  ],
                  if (_hasReasonSummary) ...[
                    const SizedBox(height: 6),
                    Text(
                      reasonSummary,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: reasonColor,
                      ),
                    ),
                  ],
                  if (reasonDetails.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...reasonDetails.map(
                      (detail) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '• $detail',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: descriptionColor),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!isSelectable || onPressed == null) {
      return cardChild;
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(radius),
      child: cardChild,
    );
  }

  IconData _leadingIcon() {
    if (!isSelectable) {
      return Icons.block_outlined;
    }
    return isCurrent ? Icons.radio_button_checked : Icons.radio_button_off;
  }
}

class _CardTagChip extends StatelessWidget {
  const _CardTagChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(context.novelChipChrome.radius),
        border: Border.all(
          color: borderColor,
          width: context.novelChipChrome.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}
