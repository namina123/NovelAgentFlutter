import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/rag/rag_command.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('RagCommand', () {
    test('help prints the rag command block', () async {
      final bundle = _buildCommand();
      addTearDown(() async {
        await bundle.tempDirectory.delete(recursive: true);
      });

      final exitCode = await bundle.command.run(const <String>['help']);

      expect(exitCode, 0);
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'rag help' &&
                block.content.contains('rag build --source') &&
                block.content.contains('rag diagnostics --query'),
          ),
        ),
      );
    });

    test('build ingests txt and emits a corpus summary', () async {
      final bundle = _buildCommand();
      addTearDown(() async {
        await bundle.tempDirectory.delete(recursive: true);
      });
      final sourceFile = File(
        '${bundle.tempDirectory.path}${Platform.pathSeparator}sample.txt',
      );
      await sourceFile.writeAsString('''
第一章
这是第一段。
''');

      final exitCode = await bundle.command.run(<String>[
        'build',
        '--project',
        bundle.project.rootPath,
        '--source',
        sourceFile.path,
        '--corpus-id',
        'corpus-cli-1',
      ]);

      expect(exitCode, 0);
      expect(bundle.printer.successes, contains('RAG txt 语料已构建。'));
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'RAG 语料摘要' &&
                block.content.contains('corpus-cli-1') &&
                block.content.contains('txt') &&
                block.content.contains('chunk 数'),
          ),
        ),
      );
    });

    test('list reports stored corpora', () async {
      final bundle = _buildCommand();
      addTearDown(() async {
        await bundle.tempDirectory.delete(recursive: true);
      });
      await bundle.repository.upsertCorpus(
        bundle.project,
        RagCorpusPackage(
          corpusId: 'corpus-cli-2',
          title: 'CLI 语料',
          sourceKind: 'txt',
          buildMode: 'basic',
          language: 'zh-CN',
          version: 'v1',
          chapterCount: 2,
          chunkCount: 4,
        ),
      );

      final exitCode = await bundle.command.run(<String>[
        'list',
        '--project',
        bundle.project.rootPath,
      ]);

      expect(exitCode, 0);
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'RAG 语料列表' &&
                block.content.contains('corpus-cli-2') &&
                block.content.contains('CLI 语料'),
          ),
        ),
      );
    });

    test('mount binds an existing corpus to the project', () async {
      final bundle = _buildCommand();
      addTearDown(() async {
        await bundle.tempDirectory.delete(recursive: true);
      });
      await bundle.repository.upsertCorpus(
        bundle.project,
        RagCorpusPackage(
          corpusId: 'corpus-cli-3',
          title: '待挂载语料',
          sourceKind: 'txt',
          buildMode: 'basic',
          language: 'zh-CN',
          version: 'v1',
        ),
      );

      final exitCode = await bundle.command.run(<String>[
        'mount',
        '--project',
        bundle.project.rootPath,
        '--corpus-id',
        'corpus-cli-3',
      ]);

      expect(exitCode, 0);
      expect(bundle.printer.successes, contains('RAG 语料已挂载。'));
      final mounts = await bundle.repository.listProjectMounts(
        bundle.project,
        projectId: bundle.project.id,
      );
      expect(mounts, hasLength(1));
      expect(mounts.single.corpusId, 'corpus-cli-3');
    });

    test('diagnostics returns the shared retrieval summary contract', () async {
      final bundle = _buildCommand();
      addTearDown(() async {
        await bundle.tempDirectory.delete(recursive: true);
      });
      await bundle.repository.upsertCorpus(
        bundle.project,
        RagCorpusPackage(
          corpusId: 'corpus-cli-4',
          title: '诊断语料',
          sourceKind: 'txt',
          buildMode: 'basic',
          language: 'zh-CN',
          version: 'v1',
        ),
      );
      await bundle.repository.upsertMountBinding(
        bundle.project,
        RetrievalMountBinding(
          bindingId: 'binding-cli-4',
          projectId: bundle.project.id,
          corpusId: 'corpus-cli-4',
          mountScope: 'project',
          priority: 10,
          usagePolicy: 'reference_only',
          activationPolicy: 'required',
          createdAt: '2026-06-17T10:00:00Z',
        ),
      );
      await bundle.repository.upsertSourceDocument(
        bundle.project,
        RagSourceDocument(
          sourceDocumentId: 'source-cli-4',
          corpusId: 'corpus-cli-4',
          sourceKind: 'txt',
          displayName: '诊断样本文本',
          originPath: 'inputs/sample.txt',
          originFormat: 'txt',
          language: 'zh-CN',
          contentHash: 'hash-cli-4',
        ),
      );
      await bundle.repository.upsertChunk(
        bundle.project,
        RagChunk(
          chunkId: 'chunk-cli-4',
          corpusId: 'corpus-cli-4',
          sourceDocumentId: 'source-cli-4',
          chapterIndex: 1,
          chapterTitle: '第一章',
          segmentIndex: 1,
          text: '镜潮回扣在这一章里反复出现。',
          normalizedText: '镜潮回扣在这一章里反复出现。',
          tokenEstimate: 16,
          rangeStart: 0,
          rangeEnd: 16,
        ),
      );

      final exitCode = await bundle.command.run(<String>[
        'diagnostics',
        '--project',
        bundle.project.rootPath,
        '--corpus-id',
        'corpus-cli-4',
        '--query',
        '镜潮回扣',
      ]);

      expect(exitCode, 0);
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'RAG 挂载摘要' &&
                block.content.contains('binding_count') &&
                block.content.contains('corpus-cli-4'),
          ),
        ),
      );
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'RAG 检索诊断' &&
                block.content.contains('retrieval_hits') &&
                block.content.contains('镜潮回扣'),
          ),
        ),
      );
    });
  });
}

({RagCommand command, _RecordingTerminalPrinter printer, Directory tempDirectory, ProjectDescriptor project, SqliteRagMetadataRepository repository})
_buildCommand() {
  final tempDirectory = Directory.systemTemp.createTempSync(
    'novel_agent_cli_rag_',
  );
  final project = ProjectDescriptor(
    id: 'project-rag-cli-1',
    name: 'CLI RAG 项目',
    rootPath: tempDirectory.path,
    storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
  );
  final repository = SqliteRagMetadataRepository();
  final printer = _RecordingTerminalPrinter();
  final command = RagCommand(
    projectRepository: _FakeProjectRepository(project),
    printer: printer,
  );
  return (
    command: command,
    printer: printer,
    tempDirectory: tempDirectory,
    project: project,
    repository: repository,
  );
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this.project);

  final ProjectDescriptor project;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async => project;
}

class _RecordingTerminalPrinter extends TerminalPrinter {
  final List<String> infos = <String>[];
  final List<String> successes = <String>[];
  final List<String> errors = <String>[];
  final List<_PrintedBlock> blocks = <_PrintedBlock>[];

  @override
  void info(String message) {
    infos.add(message);
  }

  @override
  void success(String message) {
    successes.add(message);
  }

  @override
  void error(String message) {
    errors.add(message);
  }

  @override
  void block(String title, String content) {
    blocks.add(_PrintedBlock(title, content));
  }
}

class _PrintedBlock {
  const _PrintedBlock(this.title, this.content);

  final String title;
  final String content;

  @override
  bool operator ==(Object other) {
    return other is _PrintedBlock &&
        other.title == title &&
        other.content == content;
  }

  @override
  int get hashCode => Object.hash(title, content);
}
