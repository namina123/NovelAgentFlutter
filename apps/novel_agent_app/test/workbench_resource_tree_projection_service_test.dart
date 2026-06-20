import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_resource_tree_projection_service.dart';

void main() {
  group('WorkbenchResourceTreeProjectionService', () {
    final service = WorkbenchResourceTreeProjectionService();

    test('projects visible entries with cached snapshots and selection', () {
      final entries = <JsonMap>[
        <String, Object?>{'relative_path': 'chapters', 'is_dir': true},
        <String, Object?>{'relative_path': 'chapters/ch01.md', 'is_dir': false},
        <String, Object?>{
          'relative_path': '.novel_agent/runtime/session_state.json',
          'is_dir': false,
        },
      ];

      final first = service.project(
        snapshotEntries: entries,
        expandedDirectories: const <String>{'chapters'},
        selectedId: 'chapters/ch01.md',
      );
      final second = service.project(
        snapshotEntries: entries,
        expandedDirectories: const <String>{'chapters'},
        selectedId: 'chapters/ch01.md',
      );

      expect(identical(first, second), isTrue);
      expect(first, hasLength(2));
      expect(first.first.id, 'chapters');
      expect(first.first.isDirectory, isTrue);
      expect(first.last.id, 'chapters/ch01.md');
      expect(first.last.isSelected, isTrue);
    });

    test(
      'tracks directory metadata and expands only known roots by default',
      () {
        final entries = <JsonMap>[
          <String, Object?>{'relative_path': 'chapters', 'is_dir': true},
          <String, Object?>{
            'relative_path': 'chapters/ch01.md',
            'is_dir': false,
          },
          <String, Object?>{'relative_path': 'assets', 'is_dir': true},
          <String, Object?>{
            'relative_path': 'assets/cover.png',
            'is_dir': false,
          },
        ];

        expect(
          service.isDirectory(
            snapshotEntries: entries,
            relativePath: 'chapters',
          ),
          isTrue,
        );
        expect(
          service.containsPath(
            snapshotEntries: entries,
            relativePath: 'assets/cover.png',
          ),
          isTrue,
        );
        expect(service.defaultExpandedDirectories(entries), <String>{
          'chapters',
          'assets',
        });
        expect(
          service.mergedExpandedDirectories(
            snapshotEntries: entries,
            currentExpandedDirectories: const <String>{'chapters', 'missing'},
            selectedId: 'assets/cover.png',
          ),
          <String>{'chapters', 'assets'},
        );
      },
    );
  });
}
