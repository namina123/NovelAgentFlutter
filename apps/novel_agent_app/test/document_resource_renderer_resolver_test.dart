import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/presentation/renderers/document_resource_render_request.dart';
import 'package:novel_agent_app/features/workbench/presentation/renderers/document_resource_renderer_resolver.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_workspace_display_mode.dart';

void main() {
  const resolver = DocumentResourceRendererResolver();

  DocumentResourceRenderRequest buildRequest({
    required bool hasDocument,
    required String relativePath,
    required DocumentWorkspaceDisplayMode displayMode,
    bool canRender = false,
  }) {
    return DocumentResourceRenderRequest(
      title: '测试资源',
      relativePath: relativePath,
      content: '# hello',
      status: 'ready',
      displayMode: displayMode,
      canRender: canRender,
      isDirty: false,
      hasDocument: hasDocument,
      onChanged: null,
    );
  }

  test('resolver returns empty renderer when there is no active document', () {
    final resolution = resolver.resolve(
      buildRequest(
        hasDocument: false,
        relativePath: '',
        displayMode: DocumentWorkspaceDisplayMode.source,
      ),
    );

    expect(
      resolution.rendererId,
      DocumentResourceRendererResolver.emptyRendererId,
    );
  });

  test('resolver returns markdown renderer for markdown render mode', () {
    final resolution = resolver.resolve(
      buildRequest(
        hasDocument: true,
        relativePath: 'chapters/chapter_01.md',
        displayMode: DocumentWorkspaceDisplayMode.render,
        canRender: true,
      ),
    );

    expect(
      resolution.rendererId,
      DocumentResourceRendererResolver.markdownRendererId,
    );
  });

  test('resolver returns structured renderer for structure mode', () {
    final resolution = resolver.resolve(
      buildRequest(
        hasDocument: true,
        relativePath: 'assets/characters/hero.txt',
        displayMode: DocumentWorkspaceDisplayMode.structure,
      ),
    );

    expect(
      resolution.rendererId,
      DocumentResourceRendererResolver.structuredRendererId,
    );
  });

  test(
    'resolver returns plain text renderer for source mode text resources',
    () {
      final resolution = resolver.resolve(
        buildRequest(
          hasDocument: true,
          relativePath: 'notes/world_setup.yaml',
          displayMode: DocumentWorkspaceDisplayMode.source,
        ),
      );

      expect(
        resolution.rendererId,
        DocumentResourceRendererResolver.plainTextRendererId,
      );
    },
  );

  test('resolver returns preview renderer for preview-like resources', () {
    final resolution = resolver.resolve(
      buildRequest(
        hasDocument: true,
        relativePath: 'assets/maps/city_overview.png',
        displayMode: DocumentWorkspaceDisplayMode.source,
      ),
    );

    expect(
      resolution.rendererId,
      DocumentResourceRendererResolver.previewRendererId,
    );
  });

  test('resolver returns structured renderer for sqlite resources', () {
    final sourceResolution = resolver.resolve(
      buildRequest(
        hasDocument: true,
        relativePath: '.novel_agent/sqlite/novel_agent.db',
        displayMode: DocumentWorkspaceDisplayMode.source,
      ),
    );
    final renderResolution = resolver.resolve(
      buildRequest(
        hasDocument: true,
        relativePath: 'premise/sqlite_projection/index.sqlite',
        displayMode: DocumentWorkspaceDisplayMode.render,
      ),
    );

    expect(
      sourceResolution.rendererId,
      DocumentResourceRendererResolver.structuredRendererId,
    );
    expect(
      renderResolution.rendererId,
      DocumentResourceRendererResolver.structuredRendererId,
    );
  });
}
