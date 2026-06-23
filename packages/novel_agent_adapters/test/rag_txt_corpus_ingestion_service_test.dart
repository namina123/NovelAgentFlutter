import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('RagTxtCorpusIngestionService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late RagTxtCorpusIngestionService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'rag_txt_corpus_ingestion_service_',
      );
      project = ProjectDescriptor(
        id: 'project-rag-txt-1',
        name: 'RAG txt 项目',
        rootPath: tempDirectory.path,
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      service = RagTxtCorpusIngestionService();
    });

    tearDown(() async {
      if (!await tempDirectory.exists()) {
        return;
      }
      // 中文注释: Windows 上 sqlite 句柄释放有延迟，递归删除常瞬时命中 errno=32
      // （"另一个程序正在使用此文件"）。重试几次等句柄释放，避免把这个与用例逻辑无关的
      // 清理失败计入用例结果（pre-existing flake）。
      for (var attempt = 0; attempt < 6; attempt += 1) {
        try {
          await tempDirectory.delete(recursive: true);
          return;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
      }
    });

    test(
      'ingests txt file into corpus, source documents, chunks and run metadata',
      () async {
        final sourceFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}sample.txt',
        );
        await sourceFile.writeAsString('''
第一章
这里是第一段。

第二章
这里是第二段，内容稍长一些，用于测试 chunk 构建。
''');

        final corpusPackage = RagCorpusPackage(
          corpusId: 'corpus-rag-txt-1',
          title: 'txt 基础语料',
          sourceKind: 'txt',
          buildMode: 'basic',
          language: 'zh-CN',
          version: 'v1',
        );

        final result = await service.ingestFile(
          project: project,
          sourceFilePath: sourceFile.path,
          corpusPackage: corpusPackage,
          ingestedAt: '2026-06-17T10:00:00Z',
        );

        final repository = SqliteRagMetadataRepository();
        final storedCorpus = await repository.readCorpus(
          project,
          corpusId: 'corpus-rag-txt-1',
        );
        final storedSources = await repository.listSourceDocuments(
          project,
          corpusId: 'corpus-rag-txt-1',
        );
        final storedChunks = await repository.listChunks(
          project,
          corpusId: 'corpus-rag-txt-1',
        );
        final storedHandles = await repository.listIndexHandles(
          project,
          corpusId: 'corpus-rag-txt-1',
        );
        final storedRuns = await repository.listIngestionRuns(
          project,
          corpusId: 'corpus-rag-txt-1',
        );

        expect(result.corpusId, 'corpus-rag-txt-1');
        expect(result.sourceKind, 'txt');
        expect(result.chunkCount, greaterThan(0));
        expect(storedCorpus, isNotNull);
        expect(storedCorpus!.sourceCount, 1);
        expect(storedCorpus.chunkCount, greaterThan(0));
        final corpusAnalysis = ValueReaders.mapValue(
          storedCorpus.metadata['source_analysis_summary'],
        );
        expect(
          ValueReaders.stringValue(corpusAnalysis['story_outline_summary']),
          contains('第一章'),
        );
        expect(storedSources, hasLength(1));
        expect(storedSources.single.originPath, sourceFile.path);
        final sourceAnalysis = ValueReaders.mapValue(
          storedSources.single.metadata['source_analysis_summary'],
        );
        expect(
          ValueReaders.stringValue(sourceAnalysis['premise_summary']),
          isNotEmpty,
        );
        expect(storedChunks, isNotEmpty);
        expect(storedChunks.first.chapterTitle, '第一章');
        expect(storedChunks.first.text, contains('这里是第一段'));
        expect(storedHandles, hasLength(1));
        expect(storedHandles.single.backendKind, 'sqlite-meta');
        expect(storedRuns, hasLength(1));
        expect(storedRuns.single['status'], 'completed');
        expect(storedRuns.single['chunk_count'], result.chunkCount);
        final runPayload = ValueReaders.mapValue(
          storedRuns.single['payload_json'],
        );
        final runAnalysis = ValueReaders.mapValue(
          runPayload['source_analysis_summary'],
        );
        expect(
          ValueReaders.stringValue(runAnalysis['style_summary']),
          isNotEmpty,
        );
      },
    );

    test('rejects non txt sources', () async {
      final sourceFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}sample.md',
      );
      await sourceFile.writeAsString('# heading');

      final corpusPackage = RagCorpusPackage(
        corpusId: 'corpus-rag-md-1',
        title: 'md 语料',
        sourceKind: 'md',
        buildMode: 'basic',
        language: 'zh-CN',
        version: 'v1',
      );

      expect(
        () => service.ingestFile(
          project: project,
          sourceFilePath: sourceFile.path,
          corpusPackage: corpusPackage,
          ingestedAt: '2026-06-17T10:00:00Z',
        ),
        throwsStateError,
      );
    });

    test('emits staged progress while ingesting txt corpus', () async {
      final sourceFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}sample_progress.txt',
      );
      await sourceFile.writeAsString(
        List<String>.generate(
          40,
          (index) => '第${index + 1}章\n这是第 ${index + 1} 段的内容，用于测试进度回调。\n',
        ).join('\n'),
      );

      final corpusPackage = RagCorpusPackage(
        corpusId: 'corpus-rag-progress-1',
        title: 'txt 进度语料',
        sourceKind: 'txt',
        buildMode: 'basic',
        language: 'zh-CN',
        version: 'v1',
      );
      final phases = <String>[];
      final messages = <String>[];

      await service.ingestFile(
        project: project,
        sourceFilePath: sourceFile.path,
        corpusPackage: corpusPackage,
        ingestedAt: '2026-06-18T10:00:00Z',
        onProgress: (progress) async {
          phases.add(progress.phaseId);
          messages.add(progress.message);
        },
      );

      expect(phases, contains('reading_source'));
      expect(phases, contains('analyzing_structure'));
      expect(phases, contains('building_chunks'));
      expect(phases, contains('persisting'));
      expect(phases.last, 'completed');
      expect(messages.last, contains('语料构建完成'));
    });

    test(
      'records embedding failure honestly in corpus metadata instead of silent success',
      () async {
        final sourceFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}sample_fail.txt',
        );
        await sourceFile.writeAsString(
          '第一章 内容一。\n\n第二章 内容二，稍长用于 chunk 构建。',
        );
        final failingService = RagTxtCorpusIngestionService(
          embeddingProvider: _ThrowingEmbeddingProvider(),
        );
        final corpusPackage = RagCorpusPackage(
          corpusId: 'corpus-rag-txt-fail',
          title: '向量化失败语料',
          sourceKind: 'txt',
          buildMode: 'basic',
          language: 'zh-CN',
          version: 'v1',
        );
        final result = await failingService.ingestFile(
          project: project,
          sourceFilePath: sourceFile.path,
          corpusPackage: corpusPackage,
          ingestedAt: '2026-06-23T10:00:00Z',
        );
        // 中文注释: provider 抛错时不得静默报成功——元数据如实记 embedding_failed、
        // backend 退回 sqlite-meta，供上层给用户诚实提示（与检索侧 lexical_fallback 同源）。
        expect(
          ValueReaders.stringValue(result.metadata['embedding_degraded_reason']),
          'embedding_failed',
        );
        expect(
          ValueReaders.stringValue(result.metadata['embedding_backend']),
          'sqlite-meta',
        );
      },
    );
  });
}

class _ThrowingEmbeddingProvider implements EmbeddingProviderPort {
  @override
  String get providerId => 'throwing_provider';

  @override
  String get providerKind => 'remote_test';

  @override
  bool get isLocal => false;

  @override
  bool get isRemote => true;

  @override
  Future<List<List<num>>> embedTexts(List<String> texts) async {
    throw StateError('embedding service unavailable');
  }

  @override
  JsonMap describeCapabilities() => const <String, Object?>{};
}
