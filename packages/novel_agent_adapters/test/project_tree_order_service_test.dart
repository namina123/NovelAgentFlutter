import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTreeOrderService', () {
    test('reorder entry persists sibling order and hides internal metadata', () async {
      // 中文注释: 这里覆盖“重排 -> 落内部元数据 -> 再次列目录”的完整闭环，确保 GUI/CLI 真能共享排序结果。
      final root = await Directory.systemTemp.createTemp(
        'novel_agent_tree_order_test_',
      );
      try {
        await Directory('${root.path}\\chapters').create(recursive: true);
        await File('${root.path}\\chapters\\a.md').writeAsString('A');
        await File('${root.path}\\chapters\\b.md').writeAsString('B');
        final treeOrderService = ProjectTreeOrderService();
        final workspacePort = LocalProjectWorkspacePort(
          treeOrderService: treeOrderService,
        );
        final initialEntries = await workspacePort.listEntries(root.path);

        await treeOrderService.reorderEntry(
          rootPath: root.path,
          relativePath: 'chapters/b.md',
          targetIndex: 0,
          existingEntries: initialEntries,
        );

        final reorderedEntries = await workspacePort.listEntries(root.path);
        final draftChildren = reorderedEntries
            .where(
              (entry) =>
                  ValueReaders.stringValue(entry['relative_path'])
                      .startsWith('chapters/'),
            )
            .map((entry) => ValueReaders.stringValue(entry['relative_path']))
            .toList(growable: false);
        expect(draftChildren, <String>['chapters/b.md', 'chapters/a.md']);
        expect(
          reorderedEntries.any(
            (entry) => ValueReaders.stringValue(
              entry['relative_path'],
            ).startsWith('.novel_agent/'),
          ),
          isFalse,
        );
      } finally {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    });

    test('listEntries skips internal bundle trees before recursing', () async {
      final root = await Directory.systemTemp.createTemp(
        'novel_agent_tree_order_internal_skip_test_',
      );
      try {
        await Directory('${root.path}\\knowledge').create(recursive: true);
        await File(
          '${root.path}\\knowledge\\项目知识摘要.md',
        ).writeAsString('summary');
        await Directory(
          '${root.path}\\.novel_agent\\reference_extraction\\bundles\\pkg_1\\payload',
        ).create(recursive: true);
        await File(
          '${root.path}\\.novel_agent\\reference_extraction\\bundles\\pkg_1\\payload\\entries.json',
        ).writeAsString('[]');

        final workspacePort = LocalProjectWorkspacePort(
          treeOrderService: ProjectTreeOrderService(),
        );
        final entries = await workspacePort.listEntries(root.path);
        final relativePaths = entries
            .map((entry) => ValueReaders.stringValue(entry['relative_path']))
            .toList(growable: false);

        expect(relativePaths, contains('knowledge'));
        expect(relativePaths, contains('knowledge/项目知识摘要.md'));
        expect(
          relativePaths.any((path) => path.startsWith('.novel_agent/')),
          isFalse,
        );
      } finally {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    });
  });
}

