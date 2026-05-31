import 'package:flutter/widgets.dart';

import '../widgets/document_content_canvas.dart';
import 'document_resource_render_request.dart';
import 'document_resource_renderer.dart';

class DocumentPlainTextResourceRenderer implements DocumentResourceRenderer {
  const DocumentPlainTextResourceRenderer();

  @override
  String get id => 'plain_text';

  @override
  Widget build(BuildContext context, DocumentResourceRenderRequest request) {
    return DocumentContentCanvas(
      title: request.title,
      relativePath: request.relativePath,
      content: request.content,
      status: request.status,
      onChanged: request.onChanged ?? (_) {},
      isReadOnly: request.onChanged == null,
    );
  }
}
