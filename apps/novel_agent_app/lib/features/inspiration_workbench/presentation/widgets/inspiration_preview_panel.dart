import 'package:flutter/material.dart';

import '../models/inspiration_workbench_view_data.dart';

class InspirationPreviewPanel extends StatelessWidget {
  const InspirationPreviewPanel({super.key, required this.viewData});

  final InspirationWorkbenchViewData viewData;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 预览面板只展示将沉淀出的共享资产，不承担编辑或导航动作。
    return ListView(
      padding: const EdgeInsets.all(14),
      children: viewData.previewSections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (section.items.isEmpty)
                Text(
                  section.emptyHint,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...section.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(item.summary),
                        if (item.path.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.path,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (item.metaLines.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ...item.metaLines.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                line,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
