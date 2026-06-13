import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../contracts/pending_research_action_handler.dart';
import '../contracts/workbench_file_panel_action_handler.dart';
import '../models/workbench_information_view_data.dart';
import 'resource_panel_section.dart';
import 'workbench_visual_style.dart';

class ResourceInformationSection extends StatelessWidget {
  const ResourceInformationSection({
    super.key,
    required this.viewData,
    required this.actionHandler,
    this.pendingResearchActionHandler,
  });

  final WorkbenchInformationViewData viewData;
  final WorkbenchFilePanelActionHandler actionHandler;
  final PendingResearchActionHandler? pendingResearchActionHandler;

  @override
  Widget build(BuildContext context) {
    if (!viewData.hasContent) {
      return const SizedBox.shrink();
    }
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return ResourcePanelSection(
      title: viewData.title,
      emphasized: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewData.summary,
            style: TextStyle(
              fontSize: visual.bodyFontSize,
              fontWeight: FontWeight.w600,
              height: visual.bodyLineHeight,
              color: surface.foregroundColor,
            ),
          ),
          SizedBox(height: visual.microGap + 2),
          Text(
            viewData.usageSummary,
            style: TextStyle(
              fontSize: visual.metaFontSize,
              height: visual.bodyLineHeight,
              fontWeight: FontWeight.w500,
              color: surface.mutedForegroundColor,
            ),
          ),
          if (viewData.entries.isNotEmpty) ...[
            SizedBox(height: visual.compactGap + 4),
            ...viewData.entries.asMap().entries.map((entry) {
              final index = entry.key;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == viewData.entries.length - 1 ? 0 : 6,
                ),
                child: _InformationEntryTile(
                  entry: entry.value,
                  onPressed: () => actionHandler.onResourceEntrySelected(
                    entry.value.relativePath,
                  ),
                  pendingResearchActionHandler: pendingResearchActionHandler,
                ),
              );
            }),
          ],
          if (viewData.pendingEntries.isNotEmpty) ...[
            SizedBox(height: visual.compactGap + 4),
            Text(
              '待确认',
              style: TextStyle(
                fontSize: visual.compactLabelFontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: surface.mutedForegroundColor,
              ),
            ),
            SizedBox(height: visual.microGap + 2),
            ...viewData.pendingEntries.asMap().entries.map((entry) {
              final index = entry.key;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == viewData.pendingEntries.length - 1 ? 0 : 6,
                ),
                child: _InformationEntryTile(
                  entry: entry.value,
                  onPressed: () => actionHandler.onResourceEntrySelected(
                    entry.value.relativePath,
                  ),
                  pendingResearchActionHandler: pendingResearchActionHandler,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _InformationEntryTile extends StatelessWidget {
  const _InformationEntryTile({
    required this.entry,
    required this.onPressed,
    this.pendingResearchActionHandler,
  });

  final WorkbenchInformationEntryViewData entry;
  final VoidCallback onPressed;
  final PendingResearchActionHandler? pendingResearchActionHandler;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(color: surface.borderColor.withValues(alpha: 0.26)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colors.panelBackground.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 13,
                  color: surface.foregroundColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: visual.sectionTitleFontSize,
                        fontWeight: FontWeight.w800,
                        color: surface.foregroundColor,
                      ),
                    ),
                    if (entry.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.subtitle,
                        style: TextStyle(
                          fontSize: visual.metaFontSize,
                          height: visual.bodyLineHeight,
                          fontWeight: FontWeight.w500,
                          color: surface.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _InfoBadge(text: entry.statusLabel),
            ],
          ),
          SizedBox(height: visual.microGap + 2),
          Text(
            entry.summary,
            style: TextStyle(
              fontSize: visual.bodyFontSize,
              height: visual.bodyLineHeight,
              fontWeight: FontWeight.w500,
              color: surface.foregroundColor,
            ),
          ),
          if (entry.sourceOfTruthSummary.trim().isNotEmpty) ...[
            SizedBox(height: visual.microGap),
            Text(
              entry.sourceOfTruthSummary,
              style: TextStyle(
                fontSize: visual.metaFontSize,
                height: visual.bodyLineHeight,
                fontWeight: FontWeight.w500,
                color: colors.mutedTextColor,
              ),
            ),
          ],
          if (entry.sourceIdentitySummary.trim().isNotEmpty) ...[
            SizedBox(height: visual.microGap),
            Text(
              entry.sourceIdentitySummary,
              style: TextStyle(
                fontSize: visual.metaFontSize,
                height: visual.bodyLineHeight,
                fontWeight: FontWeight.w500,
                color: colors.mutedTextColor,
              ),
            ),
          ],
          SizedBox(height: visual.compactGap),
          Wrap(
            spacing: 8,
            runSpacing: 5,
            children: [
              if (entry.mountStatusLabel.trim().isNotEmpty)
                _InfoBadge(text: entry.mountStatusLabel),
              if (entry.usageLabel.trim().isNotEmpty)
                _InfoBadge(text: entry.usageLabel),
              if (entry.riskLabel.trim().isNotEmpty)
                _InfoBadge(text: entry.riskLabel),
            ],
          ),
          SizedBox(height: visual.compactGap),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InlineActionButton(
                label: entry.actionLabel,
                onPressed: onPressed,
              ),
              if (entry.supportsPendingResearchActions &&
                  pendingResearchActionHandler != null)
                _InlineActionButton(
                  label: '确认',
                  tone: _InlineActionTone.accent,
                  onPressed: () =>
                      pendingResearchActionHandler!.onPendingResearchApproved(
                        entry.pendingResearchRequestId,
                      ),
                ),
              if (entry.supportsPendingResearchActions &&
                  pendingResearchActionHandler != null)
                _InlineActionButton(
                  label: '拒绝',
                  tone: _InlineActionTone.neutral,
                  onPressed: () =>
                      pendingResearchActionHandler!.onPendingResearchRejected(
                        entry.pendingResearchRequestId,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: visual.metaFontSize,
          fontWeight: FontWeight.w700,
          color: surface.foregroundColor,
        ),
      ),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({
    required this.label,
    required this.onPressed,
    this.tone = _InlineActionTone.neutral,
  });

  final String label;
  final VoidCallback onPressed;
  final _InlineActionTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    final (foreground, background) = switch (tone) {
      _InlineActionTone.neutral => (
        colors.textColor,
        colors.panelBackground.withValues(alpha: 0.18),
      ),
      _InlineActionTone.accent => (
        colors.lineStrongColor,
        colors.accentSoftColor.withValues(alpha: 0.42),
      ),
    };
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        foregroundColor: foreground,
        backgroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(
          fontSize: visual.metaFontSize + 0.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}

enum _InlineActionTone { neutral, accent }
