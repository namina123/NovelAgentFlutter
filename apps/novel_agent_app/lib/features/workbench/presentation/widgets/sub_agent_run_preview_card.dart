import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/sub_agent_run_preview_view_data.dart';

class SubAgentRunPreviewCard extends StatelessWidget {
  const SubAgentRunPreviewCard({
    super.key,
    required this.viewData,
    required this.onTap,
    this.isActive = false,
  });

  final SubAgentRunPreviewViewData viewData;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surfaces = context.novelThemeSurfaces;
    final borderColor = isActive
        ? colors.accentColor
        : surfaces.panel.borderColor;
    final backgroundColor = isActive
        ? colors.accentSoftColor.withValues(alpha: 0.18)
        : surfaces.panel.backgroundColor.withValues(alpha: 0.08);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor.withValues(alpha: isActive ? 0.58 : 0.18),
              width: AppChrome.borderWidth,
            ),
            borderRadius: BorderRadius.circular(surfaces.panel.radius),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _RunKindBadge(
                      label: viewData.statusLabel,
                      tone: viewData.statusTone,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewData.agentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      viewData.toolCountLabel,
                      style: TextStyle(
                        color: colors.mutedTextColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.open_in_full_rounded,
                      size: 16,
                      color: colors.lineStrongColor,
                    ),
                  ],
                ),
                if (viewData.taskPreview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    viewData.taskPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 11.5,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (viewData.summaryPreview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    viewData.summaryPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.mutedTextColor,
                      fontSize: 11.5,
                      height: 1.42,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RunKindBadge extends StatelessWidget {
  const _RunKindBadge({required this.label, required this.tone});

  final String label;
  final SubAgentRunPreviewTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final foreground = switch (tone) {
      SubAgentRunPreviewTone.active => colors.accentColor,
      SubAgentRunPreviewTone.success => colors.warmStrongColor,
      SubAgentRunPreviewTone.danger => colors.dangerStrongColor,
      SubAgentRunPreviewTone.neutral => colors.lineStrongColor,
    };
    final background = switch (tone) {
      SubAgentRunPreviewTone.active => colors.accentSoftColor.withValues(
        alpha: 0.26,
      ),
      SubAgentRunPreviewTone.success => colors.warmColor.withValues(
        alpha: 0.18,
      ),
      SubAgentRunPreviewTone.danger => colors.dangerSoftColor.withValues(
        alpha: 0.24,
      ),
      SubAgentRunPreviewTone.neutral => colors.panelBackground.withValues(
        alpha: 0.52,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          '子智能体 · $label',
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
