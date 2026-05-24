import 'package:flutter/material.dart';

import '../contracts/document_workspace_action_handler.dart';
import '../models/workbench_view_data.dart';
import 'document_content_canvas.dart';
import 'document_empty_canvas.dart';
import 'document_markdown_canvas.dart';
import 'document_tab_strip.dart';
import 'document_toolbar_bar.dart';

class DocumentWorkspacePanel extends StatelessWidget {
  const DocumentWorkspacePanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final WorkbenchViewData viewData;
  final DocumentWorkspaceActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 正文工作区只承接文档标签、工具栏和编辑占位，不混入资源树或会话侧栏状态。
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DocumentToolbarBar(
            onActionRequested: actionHandler.onDocumentActionRequested,
            canRender: viewData.activeDocumentCanRender,
            isRendered: viewData.isActiveDocumentRendered,
          ),
          const SizedBox(height: 18),
          DocumentTabStrip(
            documents: viewData.documents,
            onSelected: actionHandler.onDocumentSelected,
            onClosed: actionHandler.onDocumentClosed,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: viewData.documents.isEmpty
                ? DocumentEmptyCanvas(
                    headline: viewData.activeDocumentTitle.trim().isEmpty
                        ? '打开或新建文档'
                        : viewData.activeDocumentTitle,
                    message: viewData.generationStatus,
                  )
                : viewData.isActiveDocumentRendered
                ? DocumentMarkdownCanvas(
                    title: viewData.activeDocumentTitle,
                    relativePath: viewData.activeDocumentPath,
                    content: viewData.activeDocumentBody,
                    status: viewData.activeDocumentDirty
                        ? '渲染中，存在未保存修改'
                        : '渲染视图',
                  )
                : DocumentContentCanvas(
                    title: viewData.activeDocumentTitle,
                    relativePath: viewData.activeDocumentPath,
                    content: viewData.activeDocumentBody,
                    status: viewData.activeDocumentDirty
                        ? '未保存修改'
                        : viewData.generationStatus,
                    onChanged: actionHandler.onDocumentBodyChanged,
                  ),
          ),
        ],
      ),
    );
  }
}
