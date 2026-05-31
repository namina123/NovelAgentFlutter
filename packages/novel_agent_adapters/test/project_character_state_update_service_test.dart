import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectCharacterStateUpdateService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectCharacterStateUpdateService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_character_state_update_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      service = ProjectCharacterStateUpdateService(
        hostPort: ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        ),
      );
      project = ProjectDescriptor(
        id: 'character_state_project',
        name: '角色状态测试',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('writes stable profile latest state and history paths', () async {
      final first = await service.updateCharacterState(
        project,
        const <String, Object?>{
          'name': '林澈',
          'status': '刚拿到情报',
          'content': '他从黑市带回了关键线索。',
          'stage_id': 'chapter_03',
          'stage_label': '第3章后',
          'source_paths': <Object?>['chapters/ch03.md'],
        },
      );
      final second = await service.updateCharacterState(
        project,
        const <String, Object?>{
          'name': '林澈',
          'status': '准备撤离',
          'content': '他发现自己已经被盯上，只能立刻撤离。',
          'stage_id': 'chapter_04',
          'stage_label': '第4章后',
          'source_paths': <Object?>['chapters/ch04.md'],
        },
      );

      expect(ValueReaders.boolValue(first['ok']), isTrue);
      expect(ValueReaders.boolValue(second['ok']), isTrue);
      expect(
        ValueReaders.stringValue(second['profile_path']),
        'assets/characters/林澈.md',
      );
      expect(
        ValueReaders.stringValue(second['latest_state_path']),
        '.novel_agent/state/characters/林澈/latest.md',
      );
      expect(
        ValueReaders.stringValue(second['history_path']),
        '.novel_agent/state/characters/林澈/history.md',
      );

      final profileFile = File(
        '${tempDirectory.path}\\assets\\characters\\林澈.md',
      );
      final latestStateFile = File(
        '${tempDirectory.path}\\.novel_agent\\state\\characters\\林澈\\latest.md',
      );
      final historyFile = File(
        '${tempDirectory.path}\\.novel_agent\\state\\characters\\林澈\\history.md',
      );

      expect(await profileFile.exists(), isTrue);
      expect(await latestStateFile.exists(), isTrue);
      expect(await historyFile.exists(), isTrue);
      expect(await profileFile.readAsString(), contains('准备撤离'));
      expect(await latestStateFile.readAsString(), contains('第4章后'));
      final history = await historyFile.readAsString();
      expect(RegExp(r'## .*第3章后').hasMatch(history), isTrue);
      expect(RegExp(r'## .*第4章后').hasMatch(history), isTrue);
      expect(
        File('${tempDirectory.path}\\assets\\characters\\林澈_2.md').existsSync(),
        isFalse,
      );
    });

    test(
      'reads legacy characters path and rewrites into canonical asset path',
      () async {
        final legacyFile = File('${tempDirectory.path}\\characters\\苏九.md');
        await legacyFile.parent.create(recursive: true);
        await legacyFile.writeAsString('# 苏九\n\n旧档案内容');

        final result = await service.updateCharacterState(
          project,
          const <String, Object?>{
            'name': '苏九',
            'status': '重新登场',
            'content': '旧档案已迁回主资产目录。',
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final canonicalFile = File(
          '${tempDirectory.path}\\assets\\characters\\苏九.md',
        );
        expect(await canonicalFile.exists(), isTrue);
        expect(await canonicalFile.readAsString(), contains('重新登场'));
      },
    );
  });
}
