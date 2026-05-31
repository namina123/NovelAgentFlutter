import 'package:flutter/foundation.dart';

import 'document_tab_view_data.dart';

class WorkbenchCanvasViewData {
  const WorkbenchCanvasViewData({
    required this.documents,
    required this.activeDocumentTitle,
    required this.activeDocumentPath,
    required this.activeDocumentBody,
    required this.activeDocumentDirty,
    required this.activeDocumentCanRender,
    required this.isActiveDocumentRendered,
    required this.isDocumentsWorkspaceVisible,
    required this.generationStatus,
  });

  final List<DocumentTabViewData> documents;
  final String activeDocumentTitle;
  final String activeDocumentPath;
  final String activeDocumentBody;
  final bool activeDocumentDirty;
  final bool activeDocumentCanRender;
  final bool isActiveDocumentRendered;
  final bool isDocumentsWorkspaceVisible;
  final String generationStatus;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkbenchCanvasViewData &&
            listEquals(other.documents, documents) &&
            other.activeDocumentTitle == activeDocumentTitle &&
            other.activeDocumentPath == activeDocumentPath &&
            other.activeDocumentBody == activeDocumentBody &&
            other.activeDocumentDirty == activeDocumentDirty &&
            other.activeDocumentCanRender == activeDocumentCanRender &&
            other.isActiveDocumentRendered == isActiveDocumentRendered &&
            other.isDocumentsWorkspaceVisible == isDocumentsWorkspaceVisible &&
            other.generationStatus == generationStatus;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(documents),
    activeDocumentTitle,
    activeDocumentPath,
    activeDocumentBody,
    activeDocumentDirty,
    activeDocumentCanRender,
    isActiveDocumentRendered,
    isDocumentsWorkspaceVisible,
    generationStatus,
  );
}
