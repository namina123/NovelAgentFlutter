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
      onBackRequested: viewData.isCommitInProgress
          ? null
          : controller.onBookDeconstructionBackRequested,
      actions: [
        // 中文注释: 任意长操作进行中（智能拆书/生成预览/提取知识）时露出取消入口，
        // 避免用户被"正在..."卡死且无处可退。
        if (viewData.isLoading)
          ToolbarIconButton(
            icon: Icons.stop_circle_outlined,
            tooltip: viewData.isCommitInProgress ? '正在提交，暂不可取消' : '取消当前操作',
            onPressed: viewData.isCommitInProgress
                ? null
                : controller.onBookDeconstructionCancelRequested,
          ),
        ToolbarIconButton(
          icon: Icons.refresh_rounded,
          tooltip: '刷新',
          onPressed: controller.onBookDeconstructionRefreshRequested,
        ),
      ],
    );
  }
}
