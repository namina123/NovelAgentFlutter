import 'package:flutter/foundation.dart';

import '../widgets/document_workspace_display_mode.dart';

class DocumentResourceRenderRequest {
  const DocumentResourceRenderRequest({
    required this.title,
    required this.relativePath,
    required this.content,
    required this.status,
    required this.displayMode,
    required this.canRender,
    required this.isDirty,
    required this.isBufferedDraft,
    required this.hasDocument,
    required this.onChanged,
    this.onCreateFileRequested,
  });

  final String title;
  final String relativePath;
  final String content;
  final String status;
  final DocumentWorkspaceDisplayMode displayMode;
  final bool canRender;
  final bool isDirty;
  final bool isBufferedDraft;
  final bool hasDocument;
  final void Function(String value)? onChanged;

  /// 空态「新建文档」入口；非空时空画布显示新建按钮。
  final VoidCallback? onCreateFileRequested;

  String get normalizedPath => relativePath.trim().replaceAll('\\', '/');

  String get fileExtension {
    final path = normalizedPath.toLowerCase();
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex >= path.length - 1) {
      return '';
    }
    return path.substring(dotIndex + 1);
  }
}
