import 'package:flutter/material.dart';

import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/workspace_page_header.dart';
import '../../application/controllers/project_assets_controller.dart';
import '../models/project_assets_view_data.dart';
import 'project_asset_bundle_dialogs.dart';
import 'project_reference_extraction_dialog.dart';

class ProjectAssetsToolbar extends StatelessWidget {
  const ProjectAssetsToolbar({
    super.key,
    required this.controller,
    required this.viewData,
  });

  final ProjectAssetsController controller;
  final ProjectAssetsViewData viewData;

  @override
  Widget build(BuildContext context) {
    return WorkspacePageHeader(
      title: viewData.title,
      subtitle: viewData.description,
      onBackRequested: controller.onProjectAssetsBackRequested,
      actions: [
        ActionButton(
          label: '新建',
          icon: Icons.add_rounded,
          compact: true,
          onPressed: controller.onProjectAssetsNewRequested,
        ),
        ActionButton(
          label: '提取参考资料',
          icon: Icons.auto_stories_outlined,
          compact: true,
          tone: ActionButtonTone.neutral,
          onPressed: () => showProjectReferenceExtractionDialog(
            context,
            controller,
            viewData.referenceExtractionStrategyPicker,
          ),
        ),
        ActionButton(
          label: '提取语料',
          icon: Icons.dataset_outlined,
          compact: true,
          tone: ActionButtonTone.neutral,
          onPressed: () => showProjectRagExtractionDialog(context, controller, viewData.ragExtraction),
        ),
        ActionButton(
          label: '导入资产包',
          icon: Icons.file_upload_outlined,
          compact: true,
          tone: ActionButtonTone.neutral,
          onPressed: () => showProjectAssetImportDialog(context, controller),
        ),
        ActionButton(
          label: '导出资产包',
          icon: Icons.inventory_2_outlined,
          compact: true,
          tone: ActionButtonTone.neutral,
          onPressed: () => showProjectAssetExportDialog(context, controller),
        ),
        ActionButton(
          label: '刷新',
          icon: Icons.refresh_rounded,
          compact: true,
          tone: ActionButtonTone.neutral,
          onPressed: controller.onProjectAssetsRefreshRequested,
        ),
      ],
    );
  }
}
