import 'package:flutter/widgets.dart';

import '../widgets/document_empty_canvas.dart';
import 'document_resource_render_request.dart';
import 'document_resource_renderer.dart';

class DocumentEmptyResourceRenderer implements DocumentResourceRenderer {
  const DocumentEmptyResourceRenderer();

  @override
  String get id => 'empty';

  @override
  Widget build(BuildContext context, DocumentResourceRenderRequest request) {
    return DocumentEmptyCanvas(
      headline: request.title.trim().isEmpty ? '打开或新建文档' : request.title,
      message: request.status,
      onCreateNew: request.onCreateFileRequested,
    );
  }
}
