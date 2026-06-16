import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_primary_document_selection_service.dart';

void main() {
  group('WorkspacePrimaryDocumentSelectionService', () {
    const service = WorkspacePrimaryDocumentSelectionService();

    test('prefers formal premise over overview and random text files', () {
      final selected = service.select(const <Map<String, Object?>>[
        <String, Object?>{
          'relative_path': 'analysis/notes.md',
          'is_dir': false,
        },
        <String, Object?>{
          'relative_path': 'premise/project_overview.md',
          'is_dir': false,
        },
        <String, Object?>{
          'relative_path': 'premise/project_constitution.md',
          'is_dir': false,
        },
      ]);

      expect(selected, 'premise/project_constitution.md');
    });

    test('falls back to story outline when no formal premise exists', () {
      final selected = service.select(const <Map<String, Object?>>[
        <String, Object?>{
          'relative_path': 'outlines/story/project_outline.md',
          'is_dir': false,
        },
        <String, Object?>{
          'relative_path': 'analysis/notes.md',
          'is_dir': false,
        },
      ]);

      expect(selected, 'outlines/story/project_outline.md');
    });
  });
}
