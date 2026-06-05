import 'package:flutter/material.dart';

import '../contracts/workbench_file_panel_action_handler.dart';
import '../models/workbench_information_view_data.dart';
import 'resource_panel_section.dart';

class ResourceInformationSection extends StatelessWidget {
  const ResourceInformationSection({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final WorkbenchInformationViewData viewData;
  final WorkbenchFilePanelActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    if (!viewData.hasContent) {
      return const SizedBox.shrink();
    }
    return ResourcePanelSection(
      title: viewData.title,
      emphasized: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(viewData.summary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            viewData.usageSummary,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (viewData.entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...viewData.entries.map(
              (entry) => _InformationEntryTile(
                entry: entry,
                onPressed: () => actionHandler.onResourceEntrySelected(
                  entry.relativePath,
                ),
              ),
            ),
          ],
          if (viewData.pendingEntries.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '待确认',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ...viewData.pendingEntries.map(
              (entry) => _InformationEntryTile(
                entry: entry,
                onPressed: () => actionHandler.onResourceEntrySelected(
                  entry.relativePath,
                ),
              ),
            ),
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
  });

  final WorkbenchInformationEntryViewData entry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(onPressed: onPressed, child: Text(entry.actionLabel)),
            ],
          ),
          if (entry.subtitle.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                entry.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Text(entry.summary, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoBadge(text: entry.statusLabel),
              if (entry.usageLabel.trim().isNotEmpty)
                _InfoBadge(text: entry.usageLabel),
              if (entry.riskLabel.trim().isNotEmpty)
                _InfoBadge(text: entry.riskLabel),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
