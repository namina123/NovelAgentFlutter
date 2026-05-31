import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/document_workspace_display_mode_policy_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/document_tab_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_canvas_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_workspace_display_mode.dart';

void main() {
  const service = DocumentWorkspaceDisplayModePolicyService();

  test('prefers structure mode only as a document view mode', () {
    const viewData = WorkbenchCanvasViewData(
      documents: [
        DocumentTabViewData(
          id: 'doc_1',
          title: '第一章',
          relativePath: 'chapters/chapter_01.md',
          isActive: true,
        ),
      ],
      activeDocumentTitle: '第一章',
      activeDocumentPath: 'chapters/chapter_01.md',
      activeDocumentBody: '# 标题',
      activeDocumentDirty: false,
      activeDocumentCanRender: true,
      isActiveDocumentRendered: false,
      isDocumentsWorkspaceVisible: false,
      generationStatus: '',
    );

    final policy = service.resolve(
      viewData: viewData,
      prefersStructureMode: true,
    );

    expect(policy.selectedMode, DocumentWorkspaceDisplayMode.structure);
    expect(policy.canRender, isTrue);
    expect(policy.canInspectStructure, isTrue);
  });

  test('render toggle request only follows source-render switch', () {
    expect(
      service.shouldRequestRenderToggle(
        requestedMode: DocumentWorkspaceDisplayMode.render,
        isActiveDocumentRendered: false,
      ),
      isTrue,
    );
    expect(
      service.shouldRequestRenderToggle(
        requestedMode: DocumentWorkspaceDisplayMode.structure,
        isActiveDocumentRendered: false,
      ),
      isFalse,
    );
  });
}
