import 'package:flutter/material.dart';

import '../../../../shared/widgets/toolbar_icon_button.dart';
import '../../../../shared/widgets/workspace_page_header.dart';
import '../../application/controllers/book_deconstruction_controller.dart';
import '../models/book_deconstruction_view_data.dart';

class BookDeconstructionToolbar extends StatelessWidget {
  const BookDeconstructionToolbar({
    super.key,
    required this.controller,
    required this.viewData,
  });

  final BookDeconstructionController controller;
  final BookDeconstructionViewData viewData;

  @override
  Widget build(BuildContext context) {
    return WorkspacePageHeader(
      title: '拆书分析',
      subtitle: viewData.projectTitle.trim().isEmpty
          ? null
          : viewData.projectTitle,
      onBackRequested: controller.onBookDeconstructionBackRequested,
      actions: [
        ToolbarIconButton(
          icon: Icons.refresh_rounded,
          tooltip: '刷新',
          onPressed: controller.onBookDeconstructionRefreshRequested,
        ),
      ],
    );
  }
}
