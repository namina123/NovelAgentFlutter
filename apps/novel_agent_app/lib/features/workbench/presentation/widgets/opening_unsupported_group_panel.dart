import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../models/opening_unsupported_group_view_data.dart';
import 'agent_group_option_card.dart';

class OpeningUnsupportedGroupPanel extends StatefulWidget {
  const OpeningUnsupportedGroupPanel({super.key, required this.groups});

  final List<OpeningUnsupportedGroupViewData> groups;

  @override
  State<OpeningUnsupportedGroupPanel> createState() =>
      _OpeningUnsupportedGroupPanelState();
}

class _OpeningUnsupportedGroupPanelState
    extends State<OpeningUnsupportedGroupPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 不可用组放到可折叠高级入口，避免干扰主流程，同时保留问题排查所需信息。
    if (widget.groups.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colors = context.novelThemeColors;
    final radius = context.novelPanelChrome.radius;
    final summary = '${widget.groups.length} 个智能体组当前不适用于本项目，展开可查看具体原因。';
    return PanelSurface(
      role: PanelSurfaceRole.inputDock,
      showBorder: false,
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.inputBackground.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: colors.lineColor.withValues(alpha: 0.9),
            width: context.novelPanelChrome.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: const ValueKey<String>('opening_unsupported_groups'),
                borderRadius: BorderRadius.circular(radius),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.inputBackground.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(
                            context.novelChipChrome.radius,
                          ),
                          border: Border.all(
                            color: colors.lineColor.withValues(alpha: 0.92),
                            width: context.novelChipChrome.borderWidth,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: colors.mutedTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '当前不可用智能体组',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: colors.textColor,
                                    ),
                                  ),
                                ),
                                _UnsupportedGroupCountChip(
                                  count: widget.groups.length,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.45,
                                color: colors.mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colors.lineColor.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 10),
                          ...widget.groups.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: KeyedSubtree(
                                key: ValueKey<String>(
                                  'opening_unsupported_group_${group.groupId}',
                                ),
                                child: AgentGroupOptionCard(
                                  title: group.displayName,
                                  description: group.description,
                                  isCurrent: false,
                                  isSelectable: false,
                                  isDegraded: false,
                                  reasonSummary: group.reasonSummary,
                                  reasonDetails: group.reasonDetails,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedGroupCountChip extends StatelessWidget {
  const _UnsupportedGroupCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.inputBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(context.novelChipChrome.radius),
        border: Border.all(
          color: colors.lineColor.withValues(alpha: 0.92),
          width: context.novelChipChrome.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          '$count 项',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textColor,
          ),
        ),
      ),
    );
  }
}
