import '../../application/services/workbench_document_identity_service.dart';
import '../models/workbench_canvas_view_data.dart';
import '../renderers/document_resource_render_request.dart';
import '../widgets/document_workspace_display_mode.dart';

class DocumentResourceRenderRequestFactoryService {
  const DocumentResourceRenderRequestFactoryService({
    WorkbenchDocumentIdentityService documentIdentityService =
        const WorkbenchDocumentIdentityService(),
  }) : _documentIdentityService = documentIdentityService;

  final WorkbenchDocumentIdentityService _documentIdentityService;

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
      isBufferedDraft: viewData.activeDocumentBufferedDraft,
      hasDocument: viewData.documents.isNotEmpty,
      onChanged: onChanged,
    );
  }

  String _statusLabel(
    WorkbenchCanvasViewData viewData,
    DocumentWorkspaceDisplayMode selectedMode,
  ) {
    if (selectedMode == DocumentWorkspaceDisplayMode.structure) {
      return _documentIdentityService.statusLabel(
        relativePath: viewData.activeDocumentPath,
        isDirty: viewData.activeDocumentDirty,
        isBufferedDraft: viewData.activeDocumentBufferedDraft,
        fallbackStatus: '',
        isRenderMode: false,
        isStructureMode: true,
      );
    }
    return _documentIdentityService.statusLabel(
      relativePath: viewData.activeDocumentPath,
      isDirty: viewData.activeDocumentDirty,
      isBufferedDraft: viewData.activeDocumentBufferedDraft,
      fallbackStatus: viewData.generationStatus,
      isRenderMode: selectedMode == DocumentWorkspaceDisplayMode.render,
      isStructureMode: false,
    );
  }
}
