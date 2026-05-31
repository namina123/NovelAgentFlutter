import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectRelationshipStateUpdateService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectRelationshipStateUpdateService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_relationship_update_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      service = ProjectRelationshipStateUpdateService(
        hostPort: ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        ),
      );
      project = ProjectDescriptor(
        id: 'relationship_project',
        name: '关系测试',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('writes canonical relationship asset document', () async {
      final result = await service.updateRelationshipState(
        project,
        const <String, Object?>{
          'title': '师徒裂痕',
          'left_entity_id': 'hero',
          'right_entity_id': 'mentor',
          'summary': '双方信任出现裂口。',
          'relationship_type': 'mentor',
          'related_timeline_ids': <Object?>['tower_night'],
        },
      );

      expect(ValueReaders.boolValue(result['ok']), isTrue);
      expect(
        ValueReaders.stringValue(result['relative_path']),
        'assets/relationships/hero_mentor_师徒裂痕.relationship.md',
      );
      final file = File(
        '${tempDirectory.path}\\assets\\relationships\\hero_mentor_师徒裂痕.relationship.md',
      );
      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('left_entity_id: "hero"'));
      expect(content, contains('right_entity_id: "mentor"'));
    });
  });
}
