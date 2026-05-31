import 'package:flutter/material.dart';

import '../renderers/document_empty_resource_renderer.dart';
import '../renderers/document_markdown_resource_renderer.dart';
import '../renderers/document_plain_text_resource_renderer.dart';
import '../renderers/document_preview_resource_renderer.dart';
import '../renderers/document_resource_render_request.dart';
import '../renderers/document_resource_renderer_registry.dart';
import '../renderers/document_resource_renderer_resolver.dart';
import '../renderers/document_structured_resource_renderer.dart';

class DocumentResourceCanvasHost extends StatelessWidget {
  const DocumentResourceCanvasHost({
    super.key,
    required this.request,
    this.rendererRegistry,
    this.rendererResolver = const DocumentResourceRendererResolver(),
  });

  final DocumentResourceRenderRequest request;
  final DocumentResourceRendererRegistry? rendererRegistry;
  final DocumentResourceRendererResolver rendererResolver;

  static final DocumentResourceRendererRegistry _defaultRendererRegistry =
      DocumentResourceRendererRegistry(
        renderers: const [
          DocumentEmptyResourceRenderer(),
          DocumentPlainTextResourceRenderer(),
          DocumentMarkdownResourceRenderer(),
          DocumentStructuredResourceRenderer(),
          DocumentPreviewResourceRenderer(),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final resolution = rendererResolver.resolve(request);
    final renderer = (rendererRegistry ?? _defaultRendererRegistry)
        .rendererOf(resolution.rendererId);
    return renderer.build(context, request);
  }
}
