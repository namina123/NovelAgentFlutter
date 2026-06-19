import 'dart:io';

import 'package:fast_gbk/fast_gbk.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('project text reading', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'local_project_text_read_service_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('workspace port decodes gbk txt inside project assets', () async {
      final rootPath = tempDirectory.path;
      final relativePath = 'assets/re_zero.txt';
      final absolutePath =
          '$rootPath${Platform.pathSeparator}assets${Platform.pathSeparator}re_zero.txt';
      await File(absolutePath).parent.create(recursive: true);
      await File(absolutePath).writeAsBytes(
        gbk.encode('''
第一章
菜月昴突然来到了异世界。
'''),
      );

      final workspacePort = LocalProjectWorkspacePort();
      final content = await workspacePort.readTextFile(rootPath, relativePath);

      expect(content, contains('第一章'));
      expect(content, contains('菜月昴突然来到了异世界。'));
    });

    test(
      'workspace port returns null for unsupported binary decode failure',
      () async {
        final rootPath = tempDirectory.path;
        final relativePath = 'assets/cover.png';
        final absolutePath =
            '$rootPath${Platform.pathSeparator}assets${Platform.pathSeparator}cover.png';
        await File(absolutePath).parent.create(recursive: true);
        await File(absolutePath).writeAsBytes(<int>[0x89, 0x50, 0x4E, 0x47]);

        final workspacePort = LocalProjectWorkspacePort();
        final content = await workspacePort.readTextFile(
          rootPath,
          relativePath,
        );

        expect(content, isNull);
      },
    );

    test('file mutation adapter decodes supported external txt', () async {
      final absolutePath =
          '${tempDirectory.path}${Platform.pathSeparator}external_source.txt';
      await File(absolutePath).writeAsBytes(gbk.encode('哈利第一次收到霍格沃兹来信。'));

      final adapter = LocalProjectFileMutationAdapter();
      final content = await adapter.readExternalTextFile(absolutePath);

      expect(content, '哈利第一次收到霍格沃兹来信。');
    });
  });
}
