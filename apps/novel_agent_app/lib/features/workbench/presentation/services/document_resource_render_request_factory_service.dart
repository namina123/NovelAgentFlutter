import '../models/workbench_canvas_view_data.dart';
import '../renderers/document_resource_render_request.dart';
import '../widgets/document_workspace_display_mode.dart';

class DocumentResourceRenderRequestFactoryService {
  const DocumentResourceRenderRequestFactoryService();

  DocumentResourceRenderRequest build({
    required WorkbenchCanvasViewData viewData,
    required DocumentWorkspaceDisplayMode selectedMode,
    required void Function(String value)? onChanged,
  }) {
    return DocumentResourceRenderRequest(
      title: viewData.activeDocumentTitle.trim().isEmpty
          ? '打开或新建文档'
          : viewData.activeDocumentTitle,
      relativePath: viewData.activeDocumentPath,
      content: viewData.activeDocumentBody,
      status: _statusLabel(viewData, selectedMode),
      displayMode: selectedMode,
      canRender: viewData.activeDocumentCanRender,
      isDirty: viewData.activeDocumentDirty,
      hasDocument: viewData.documents.isNotEmpty,
      onChanged: onChanged,
    );
  }

  String _statusLabel(
    WorkbenchCanvasViewData viewData,
    DocumentWorkspaceDisplayMode selectedMode,
  ) {
    if (selectedMode == DocumentWorkspaceDisplayMode.structure) {
      return '结构视图';
    }
    if (selectedMode == DocumentWorkspaceDisplayMode.render) {
      return viewData.activeDocumentDirty ? '渲染中，存在未保存修改' : '渲染视图';
    }
    return viewData.activeDocumentDirty ? '未保存修改' : viewData.generationStatus;
  }
}
