import 'document_resource_renderer.dart';

class DocumentResourceRendererRegistry {
  DocumentResourceRendererRegistry({
    required Iterable<DocumentResourceRenderer> renderers,
  }) : _renderers = <String, DocumentResourceRenderer>{
         for (final renderer in renderers) renderer.id: renderer,
       };

  final Map<String, DocumentResourceRenderer> _renderers;

  DocumentResourceRenderer rendererOf(String id) {
    final renderer = _renderers[id];
    if (renderer == null) {
      throw StateError('Unknown document resource renderer: $id');
    }
    return renderer;
  }
}
