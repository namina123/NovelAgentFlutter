import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

import '../lib/src/tools/project_file_write_tool_executor.dart';
import '../lib/src/tools/project_structured_memory_tool_executor.dart';

void main() {
  group('ProjectStructuredMemoryToolExecutor', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectWorkspaceToolHostAdapter hostPort;
    late ProjectDescriptor project;
    late ProjectStructuredMemoryToolExecutor executor;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-structured-memory-',
      );
      workspacePort = LocalProjectWorkspacePort();
      hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      project = ProjectDescriptor(
        id: 'project_memory_test',
        name: '结构化记忆测试项目',
        rootPath: tempDirectory.path,
      );
      executor = ProjectStructuredMemoryToolExecutor(
        hostPort: hostPort,
        writeToolExecutor: ProjectFileWriteToolExecutor(hostPort: hostPort),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'summarizeContext normalizes summary-style title without duplicating suffix',
      () async {
        final result = await executor.summarizeContext(
          project,
          <String, Object?>{
            'title': '第03章.summary',
            'scope': 'chapter',
            'summary': '本章状态已收口。',
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['relative_path']),
          'summaries/第03章.summary.md',
        );
        final writtenFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}summaries${Platform.pathSeparator}第03章.summary.md',
        );
        expect(await writtenFile.exists(), isTrue);
        expect(await writtenFile.readAsString(), startsWith('# 第03章'));
      },
    );

    test('summarizeContext keeps ordinary summary titles stable', () async {
      final result = await executor.summarizeContext(project, <String, Object?>{
        'title': '第02章摘要',
        'scope': 'chapter',
        'summary': '主角找到临时落脚处。',
      });

      expect(ValueReaders.boolValue(result['ok']), isTrue);
      expect(
        ValueReaders.stringValue(result['relative_path']),
        'summaries/第02章摘要.summary.md',
      );
    });
  });
}
