import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTimelineStateUpdateService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectTimelineStateUpdateService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_timeline_update_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      service = ProjectTimelineStateUpdateService(
        hostPort: ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        ),
      );
      project = ProjectDescriptor(
        id: 'timeline_project',
        name: '时间线测试',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('writes canonical timeline asset document', () async {
      final result = await service.updateTimelineState(
        project,
        const <String, Object?>{
          'title': '塔楼之夜',
          'summary': '主角正式卷入塔楼事件。',
          'phase_label': '第三章后',
          'sequence': 12,
          'related_paths': <Object?>['chapters/ch03.md'],
        },
      );

      expect(ValueReaders.boolValue(result['ok']), isTrue);
      expect(
        ValueReaders.stringValue(result['relative_path']),
        'assets/timeline/塔楼之夜.timeline.md',
      );
      final file = File(
        '${tempDirectory.path}\\assets\\timeline\\塔楼之夜.timeline.md',
      );
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), contains('第三章后'));
    });
  });
}
