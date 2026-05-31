import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectForeshadowStateUpdateService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectForeshadowStateUpdateService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_foreshadow_update_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      service = ProjectForeshadowStateUpdateService(
        hostPort: ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        ),
      );
      project = ProjectDescriptor(
        id: 'foreshadow_project',
        name: '伏笔测试',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'writes stable foreshadow asset file and merges followup state',
      () async {
        final first = await service.updateForeshadowState(
          project,
          const <String, Object?>{
            'title': '塔楼密钥',
            'status': 'planted',
            'summary': '主角在黑市得到一把可疑的金属钥匙。',
            'related_paths': <Object?>['chapters/ch03.md'],
          },
        );
        final second = await service.updateForeshadowState(
          project,
          const <String, Object?>{
            'foreshadow_id': '塔楼密钥',
            'title': '塔楼密钥',
            'status': 'pending_payoff',
            'target_payoff_path': 'chapters/ch08.md',
            'related_paths': <Object?>['chapters/ch08.md'],
          },
        );

        expect(ValueReaders.boolValue(first['ok']), isTrue);
        expect(ValueReaders.boolValue(second['ok']), isTrue);
        expect(
          ValueReaders.stringValue(second['relative_path']),
          'assets/foreshadows/塔楼密钥.foreshadow.md',
        );

        final file = File(
          '${tempDirectory.path}\\assets\\foreshadows\\塔楼密钥.foreshadow.md',
        );
        expect(await file.exists(), isTrue);
        final content = await file.readAsString();
        expect(content, contains('pending_payoff'));
        expect(content, contains('chapters/ch08.md'));
      },
    );
  });
}
