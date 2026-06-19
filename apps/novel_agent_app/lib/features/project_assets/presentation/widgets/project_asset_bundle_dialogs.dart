import 'package:flutter/material.dart';

import '../../application/controllers/project_assets_controller.dart';
import '../models/project_assets_view_data.dart';
import '../models/project_rag_extraction_view_data.dart';

Future<void> showProjectAssetImportDialog(
  BuildContext context,
  ProjectAssetsController controller,
) async {
  final pathController = TextEditingController();
  var overwrite = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('导入资产包'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pathController,
                    decoration: const InputDecoration(labelText: '绝对路径'),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    controlAffinity: ListTileControlAffinity.leading,
                    titleAlignment: ListTileTitleAlignment.top,
                    title: const Text('覆盖同名资产'),
                    value: overwrite,
                    onChanged: (value) =>
                        setState(() => overwrite = value ?? false),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  controller.onProjectAssetsImportBundleRequested(
                    ProjectAssetBundleImportRequestViewData(
                      absolutePath: pathController.text,
                      overwrite: overwrite,
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('导入'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showProjectRagExtractionDialog(
  BuildContext context,
  ProjectAssetsController controller,
  ProjectRagExtractionViewData viewData,
) async {
  var selectedModeId = viewData.activeModeId;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('语料提取'),
            content: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewData.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: RadioGroup<String>(
                        groupValue: selectedModeId,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => selectedModeId = value);
                        },
                        child: Column(
                          children: viewData.modes
                              .map(
                                (mode) => RadioListTile<String>(
                                  value: mode.id,
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(mode.title)),
                                      if (mode.badge.trim().isNotEmpty)
                                        _ModeBadge(label: mode.badge),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(mode.summary),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: selectedModeId.trim().isEmpty
                    ? null
                    : () {
                        controller.onProjectAssetsExtractRagRequested(
                          modeId: selectedModeId,
                        );
                        Navigator.of(dialogContext).pop();
                      },
                child: const Text('开始提取'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

Future<void> showProjectAssetExportDialog(
  BuildContext context,
  ProjectAssetsController controller,
) async {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('导出资产包'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '描述'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              controller.onProjectAssetsExportBundleRequested(
                ProjectAssetBundleExportRequestViewData(
                  title: titleController.text,
                  description: descriptionController.text,
                ),
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('导出'),
          ),
        ],
      );
    },
  );
}
