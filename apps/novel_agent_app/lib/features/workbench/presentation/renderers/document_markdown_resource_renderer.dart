import 'package:flutter/widgets.dart';

import '../widgets/document_markdown_canvas.dart';
import 'document_resource_render_request.dart';
import 'document_resource_renderer.dart';

class DocumentMarkdownResourceRenderer implements DocumentResourceRenderer {
  const DocumentMarkdownResourceRenderer();

  @override
  String get id => 'markdown';

  @override
  Widget build(BuildContext context, DocumentResourceRenderRequest request) {
    return DocumentMarkdownCanvas(
      title: request.title,
      relativePath: request.relativePath,
      content: request.content,
      status: request.status,
    );
  }
}
