import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectRagRetrievalToolExecutor', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late SqliteRagMetadataRepository repository;
    late ProjectRagRetrievalToolExecutor executor;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'project-rag-retrieval-tool-executor-',
      );
      project = ProjectDescriptor(
        id: 'project-rag-retrieval-1',
        name: 'RAG retrieval 项目',
        rootPath: tempDirectory.path,
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      repository = SqliteRagMetadataRepository();
      executor = ProjectRagRetrievalToolExecutor();

      await repository.upsertCorpus(
        project,
        RagCorpusPackage(
          corpusId: 'corpus-001',
          title: '基础语料',
          sourceKind: 'txt',
          buildMode: 'basic',
          language: 'zh-CN',
          version: 'v1',
        ),
      );
      await repository.upsertSourceDocument(
        project,
        RagSourceDocument(
          sourceDocumentId: 'source-001',
          corpusId: 'corpus-001',
          sourceKind: 'txt',
          displayName: '样本文本',
          originPath: 'inputs/sample.txt',
          originFormat: 'txt',
          language: 'zh-CN',
          contentHash: 'hash-001',
        ),
      );
      await repository.upsertChunk(
        project,
        RagChunk(
          chunkId: 'chunk-001',
          corpusId: 'corpus-001',
          sourceDocumentId: 'source-001',
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
      await repository.upsertMountBinding(
        project,
        RetrievalMountBinding(
          bindingId: 'binding-001',
          projectId: project.id,
          corpusId: 'corpus-001',
          mountScope: 'project',
          priority: 10,
          usagePolicy: 'reference_only',
          activationPolicy: 'required',
          createdAt: '2026-06-17T10:00:00Z',
        ),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('returns retrieval hits from mounted corpus metadata', () async {
      final result = await executor.retrievePassages(
        project,
        <String, Object?>{
          'query_id': 'query-001',
          'query_text': '镜潮回扣',
          'project_id': project.id,
          'corpus_filters': <Object?>['corpus-001'],
          'top_k': 5,
        },
      );

      expect(result['ok'], isTrue);
      expect(result['retrieval_hits'], isNotEmpty);
      expect(
        ValueReaders.stringList(result['citation_paths']),
        isNotEmpty,
      );
      expect(
        ValueReaders.stringValue(result['display_text']),
        contains('已召回语料证据片段'),
      );
      expect(
        ValueReaders.mapValue(result['retrieval_activation_package']),
        isNotEmpty,
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(result['retrieval_activation_package'])[
            'activation_package_id'
          ],
        ),
        'rag_activation:project-rag-retrieval-1:query-001',
      );
    });

    test('rejects malformed query payloads', () async {
      final result = await executor.retrievePassages(
        project,
        <String, Object?>{
          'query_id': '',
          'query_text': '',
        },
      );

      expect(result['ok'], isFalse);
      expect(
        ValueReaders.stringValue(result['error']),
        contains('参数不合法'),
      );
      expect(
        ValueReaders.stringList(result['validation_errors']),
        isNotEmpty,
      );
    });
  });
}
