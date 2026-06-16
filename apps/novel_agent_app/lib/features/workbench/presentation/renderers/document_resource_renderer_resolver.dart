import '../widgets/document_workspace_display_mode.dart';
import 'document_resource_render_request.dart';
import 'document_resource_renderer_resolution.dart';

class DocumentResourceRendererResolver {
  const DocumentResourceRendererResolver();

  static const String emptyRendererId = 'empty';
  static const String plainTextRendererId = 'plain_text';
  static const String markdownRendererId = 'markdown';
  static const String structuredRendererId = 'structured';
  static const String previewRendererId = 'preview_like';
  static const Set<String> _markdownExtensions = <String>{'md', 'markdown'};

  static const Set<String> _plainTextExtensions = <String>{
    'txt',
    'text',
    'yaml',
    'yml',
    'json',
    'jsonl',
    'toml',
    'ini',
    'cfg',
    'conf',
    'csv',
    'xml',
    'html',
    'htm',
    'css',
    'scss',
    'js',
    'ts',
    'dart',
    'py',
    'java',
    'kt',
    'swift',
    'sql',
    'sh',
    'ps1',
    'bat',
    'prompt',
  };

  static const Set<String> _previewLikeExtensions = <String>{
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'bmp',
    'svg',
    'pdf',
  };

  DocumentResourceRendererResolution resolve(
    DocumentResourceRenderRequest request,
  ) {
    if (!request.hasDocument) {
      return const DocumentResourceRendererResolution(
        rendererId: emptyRendererId,
        reason: 'no-active-document',
      );
    }
    switch (request.displayMode) {
      case DocumentWorkspaceDisplayMode.structure:
        return const DocumentResourceRendererResolution(
          rendererId: structuredRendererId,
          reason: 'manual-structure-mode',
        );
      case DocumentWorkspaceDisplayMode.render:
        if (request.canRender) {
          return const DocumentResourceRendererResolution(
            rendererId: markdownRendererId,
            reason: 'markdown-render-mode',
          );
        }
        if (_sqliteStructuredExtensions.contains(request.fileExtension)) {
          return const DocumentResourceRendererResolution(
            rendererId: structuredRendererId,
            reason: 'sqlite-structured-render-resource',
          );
        }
        if (_previewLikeExtensions.contains(request.fileExtension)) {
          return const DocumentResourceRendererResolution(
            rendererId: previewRendererId,
            reason: 'preview-like-render-resource',
          );
        }
        return const DocumentResourceRendererResolution(
          rendererId: plainTextRendererId,
          reason: 'render-mode-fallback-to-text',
        );
      case DocumentWorkspaceDisplayMode.source:
        return _resolveSourceRenderer(request);
    }
  }

  DocumentResourceRendererResolution _resolveSourceRenderer(
    DocumentResourceRenderRequest request,
  ) {
    if (_sqliteStructuredExtensions.contains(request.fileExtension)) {
      return const DocumentResourceRendererResolution(
        rendererId: structuredRendererId,
        reason: 'sqlite-structured-source-resource',
      );
    }
    if (_markdownExtensions.contains(request.fileExtension)) {
      return const DocumentResourceRendererResolution(
        rendererId: markdownRendererId,
        reason: 'markdown-source-resource',
      );
    }
    if (_previewLikeExtensions.contains(request.fileExtension)) {
      return const DocumentResourceRendererResolution(
        rendererId: previewRendererId,
        reason: 'preview-like-source-resource',
      );
    }
    if (_plainTextExtensions.contains(request.fileExtension)) {
      return const DocumentResourceRendererResolution(
        rendererId: plainTextRendererId,
        reason: 'text-like-source-resource',
      );
    }
    return const DocumentResourceRendererResolution(
      rendererId: plainTextRendererId,
      reason: 'default-source-resource',
    );
  }

  static const Set<String> _sqliteStructuredExtensions = <String>{
    'db',
    'sqlite',
  };
}
