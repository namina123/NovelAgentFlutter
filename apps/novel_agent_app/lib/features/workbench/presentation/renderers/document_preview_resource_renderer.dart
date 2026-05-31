import 'package:flutter/widgets.dart';

import '../widgets/document_preview_canvas.dart';
import 'document_resource_render_request.dart';
import 'document_resource_renderer.dart';

class DocumentPreviewResourceRenderer implements DocumentResourceRenderer {
  const DocumentPreviewResourceRenderer();

  @override
  String get id => 'preview_like';

  @override
  Widget build(BuildContext context, DocumentResourceRenderRequest request) {
    final extension = request.fileExtension.isEmpty
        ? '预览资源'
        : '${request.fileExtension.toUpperCase()} 预览';
    return DocumentPreviewCanvas(
      title: request.title,
      relativePath: request.relativePath,
      status: request.status,
      previewTypeLabel: extension,
      summary: '当前资源更适合直接预览，而不是纯文本编辑。这里会优先保留只读查看体验，方便你先确认内容再决定下一步。',
    );
  }
}
