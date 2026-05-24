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
        await Directory('${root.path}\\drafts').create(recursive: true);
        await File('${root.path}\\drafts\\a.md').writeAsString('A');
        await File('${root.path}\\drafts\\b.md').writeAsString('B');
        final treeOrderService = ProjectTreeOrderService();
        final workspacePort = LocalProjectWorkspacePort(
          treeOrderService: treeOrderService,
        );
        final initialEntries = await workspacePort.listEntries(root.path);

        await treeOrderService.reorderEntry(
          rootPath: root.path,
          relativePath: 'drafts/b.md',
          targetIndex: 0,
          existingEntries: initialEntries,
        );

        final reorderedEntries = await workspacePort.listEntries(root.path);
        final draftChildren = reorderedEntries
            .where(
              (entry) =>
                  ValueReaders.stringValue(entry['relative_path'])
                      .startsWith('drafts/'),
            )
            .map((entry) => ValueReaders.stringValue(entry['relative_path']))
            .toList(growable: false);
        expect(draftChildren, <String>['drafts/b.md', 'drafts/a.md']);
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
  });
}
