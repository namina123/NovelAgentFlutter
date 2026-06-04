import 'package:flutter/material.dart';

import '../models/project_assets_view_data.dart';

class ProjectAssetsInspectorPanel extends StatelessWidget {
  const ProjectAssetsInspectorPanel({
    super.key,
    required this.viewData,
    required this.onReferenceSelected,
  });

  final ProjectAssetsInspectorViewData viewData;
  final ValueChanged<String> onReferenceSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          viewData.title.isEmpty ? '资产详情' : viewData.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (viewData.badge.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(viewData.badge, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (viewData.subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(viewData.subtitle),
        ],
        if (viewData.sourcePath.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(viewData.sourcePath, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (viewData.sections.isEmpty && viewData.relatedAssets.isEmpty) ...[
          const SizedBox(height: 12),
          Text(viewData.emptyMessage),
        ],
        ...viewData.sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ...section.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (viewData.relatedAssets.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            '关联资产',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...viewData.relatedAssets.map(
            (item) => Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: Text(item.badge),
                selected: item.isSelected,
                onTap: () => onReferenceSelected(item.referenceKey),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
