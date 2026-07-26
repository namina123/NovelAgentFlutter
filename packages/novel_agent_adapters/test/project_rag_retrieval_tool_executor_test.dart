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
      final result = await executor.retrievePassages(project, <String, Object?>{
        'query_id': 'query-001',
        'query_text': '镜潮回扣',
        'project_id': project.id,
        'corpus_filters': <Object?>['corpus-001'],
        'top_k': 5,
      });

      expect(result['ok'], isTrue);
      expect(result['retrieval_hits'], isNotEmpty);
      expect(ValueReaders.stringList(result['citation_paths']), isNotEmpty);
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
          ValueReaders.mapValue(
            result['retrieval_activation_package'],
          )['activation_package_id'],
        ),
        'rag_activation:project-rag-retrieval-1:query-001',
      );
    });

    test('rejects malformed query payloads', () async {
      final result = await executor.retrievePassages(project, <String, Object?>{
        'query_id': '',
        'query_text': '',
      });

      expect(result['ok'], isFalse);
      expect(ValueReaders.stringValue(result['error']), contains('参数不合法'));
      expect(ValueReaders.stringList(result['validation_errors']), isNotEmpty);
    });

    test(
      'surfaces retrieval_mode=lexical and honest keyword label when no vector port is wired',
      () async {
        // 中文注释: 无向量端口时必须如实标 lexical，并把"关键词匹配"亮给下游，不再冒充语义检索。
        final result = await executor.retrievePassages(
          project,
          <String, Object?>{
            'query_id': 'query-lexical',
            'query_text': '镜潮回扣',
            'project_id': project.id,
            'corpus_filters': <Object?>['corpus-001'],
            'top_k': 5,
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.stringValue(result['retrieval_mode']), 'lexical');
        expect(
          ValueReaders.stringValue(result['display_text']),
          contains('关键词匹配'),
        );
        expect(
          ValueReaders.stringList(
            result['warning_notes'],
          ).any((note) => note.contains('关键词匹配')),
          isTrue,
        );
      },
    );

    test(
      'falls back to lexical_fallback with honest note when the vector port throws',
      () async {
        // 中文注释: 注入了向量端口但本次嵌入/检索失败时，既不让工具报错，也不静默冒充语义——
        // 降级到关键词匹配并标 lexical_fallback。
        final executorWithFailingPort = ProjectRagRetrievalToolExecutor(
          searchPort: _ThrowingRetrievalSearchPort(),
        );
        final result = await executorWithFailingPort.retrievePassages(
          project,
          <String, Object?>{
            'query_id': 'query-fallback',
            'query_text': '镜潮回扣',
            'project_id': project.id,
            'corpus_filters': <Object?>['corpus-001'],
            'top_k': 5,
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['retrieval_mode']),
          'lexical_fallback',
        );
        // 降级后仍能从元数据召回真实命中，而不是空结果。
        expect(result['retrieval_hits'], isNotEmpty);
        expect(
          ValueReaders.stringList(
            result['warning_notes'],
          ).any((note) => note.contains('向量检索不可用')),
          isTrue,
        );
      },
    );

    test(
      'uses retrieval_mode=vector when the search port returns hits',
      () async {
        // 中文注释: 向量端口正常返回时走 vector 路径，不再附加词法降级提示。
        final executorWithVectorPort = ProjectRagRetrievalToolExecutor(
          searchPort: _StubRetrievalSearchPort(),
        );
        final result = await executorWithVectorPort.retrievePassages(
          project,
          <String, Object?>{
            'query_id': 'query-vector',
            'query_text': '镜潮回扣',
            'project_id': project.id,
            'corpus_filters': <Object?>['corpus-001'],
            'top_k': 5,
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.stringValue(result['retrieval_mode']), 'vector');
        expect(result['retrieval_hits'], isNotEmpty);
        expect(
          ValueReaders.stringValue(result['display_text']),
          isNot(contains('关键词匹配')),
        );
      },
    );

    test(
      'resolves the search port lazily via searchPortResolver when no static port is wired',
      () async {
        // 中文注释: 生产装配里向量端口是惰性解析的（设置每次可能变）。验证：只给 resolver、
        // 不给静态端口时，executor 会调用 resolver 并走 vector 路径；resolver 返回 null 时
        // 如实落到 lexical。
        var resolverCalls = 0;
        final executorWithResolver = ProjectRagRetrievalToolExecutor(
          searchPortResolver: () async {
            resolverCalls += 1;
            return _StubRetrievalSearchPort();
          },
        );
        final result = await executorWithResolver.retrievePassages(
          project,
          <String, Object?>{
            'query_id': 'query-lazy',
            'query_text': '镜潮回扣',
            'project_id': project.id,
            'corpus_filters': <Object?>['corpus-001'],
            'top_k': 5,
          },
        );

        expect(resolverCalls, 1);
        expect(ValueReaders.stringValue(result['retrieval_mode']), 'vector');
        expect(result['retrieval_hits'], isNotEmpty);

        // resolver 返回 null（未配置 embedding）时如实降级到 lexical，不冒充。
        final executorWithNullResolver = ProjectRagRetrievalToolExecutor(
          searchPortResolver: () async => null,
        );
        final lexicalResult = await executorWithNullResolver.retrievePassages(
          project,
          <String, Object?>{
            'query_id': 'query-lazy-null',
            'query_text': '镜潮回扣',
            'project_id': project.id,
            'corpus_filters': <Object?>['corpus-001'],
            'top_k': 5,
          },
        );
        expect(
          ValueReaders.stringValue(lexicalResult['retrieval_mode']),
          'lexical',
        );
      },
    );
  });
}

class _ThrowingRetrievalSearchPort implements RetrievalSearchPort {
  @override
  Future<List<RetrievalHit>> search(RetrievalQuery query) async =>
      throw StateError('embedding provider unavailable');

  @override
  Future<List<RetrievalHit>> searchWithinMounts(
    RetrievalQuery query,
    List<RetrievalMountBinding> bindings,
  ) async => throw StateError('embedding provider unavailable');

  @override
  Future<List<RetrievalHit>> searchByCorpus(
    RetrievalQuery query,
    RagCorpusId corpusId,
  ) async => throw StateError('embedding provider unavailable');
}

class _StubRetrievalSearchPort implements RetrievalSearchPort {
  @override
  Future<List<RetrievalHit>> search(RetrievalQuery query) async => _hit();

  @override
  Future<List<RetrievalHit>> searchWithinMounts(
    RetrievalQuery query,
    List<RetrievalMountBinding> bindings,
  ) async => _hit();

  @override
  Future<List<RetrievalHit>> searchByCorpus(
    RetrievalQuery query,
    RagCorpusId corpusId,
  ) async => _hit();

  List<RetrievalHit> _hit() => <RetrievalHit>[
    const RetrievalHit(
      hitId: 'vector-hit-001',
      corpusId: 'corpus-001',
      sourceDocumentId: 'source-001',
      score: 0.92,
      rerankScore: 0.92,
      excerpt: '镜潮回扣语义近邻片段。',
      chapterTitle: '第一章',
    ),
  ];
}
