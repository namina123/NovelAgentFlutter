import 'package:flutter/material.dart';

import '../../application/controllers/project_assets_controller.dart';
import '../models/project_assets_view_data.dart';

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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pathController,
                  decoration: const InputDecoration(labelText: '绝对路径'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('覆盖同名资产'),
                  value: overwrite,
                  onChanged: (value) => setState(() => overwrite = value ?? false),
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
