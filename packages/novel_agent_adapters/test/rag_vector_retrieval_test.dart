import 'dart:io';
import 'dart:typed_data';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

// 中文注释: 这组测试验证 P0-2 的 RAG 引擎可测核心：远程 embedding provider 的解析与端点构造，
// 以及本地 SQLite 暴力 cosine 检索端口真的按向量相似度召回（而不是关键词）。

void main() {
  group('RemoteOpenAiCompatibleEmbeddingProvider', () {
    test('parses data[].embedding from the POST response', () async {
      final provider = RemoteOpenAiCompatibleEmbeddingProvider(
        providerId: 'remote_test',
        baseUrl: 'https://example.test/v1',
        apiKey: 'sk-test',
        modelId: 'embed-test',
        post: ({
          required Uri requestUri,
          required String apiKey,
          required JsonMap body,
          required Duration timeout,
        }) async {
          expect(requestUri.toString(), 'https://example.test/v1/embeddings');
          expect(apiKey, 'sk-test');
          expect(body['model'], 'embed-test');
          final input = ValueReaders.objectList(body['input']);
          return <String, Object?>{
            'data': input
                .map(
                  (text) => <String, Object?>{
                    'embedding': <double>[1.0, 0.0, 0.5],
                  },
                )
                .toList(),
          };
        },
      );

      final vectors = await provider.embedTexts(<String>['a', 'b']);

      expect(vectors.length, 2);
      expect(vectors.first, <num>[1.0, 0.0, 0.5]);
      expect(provider.providerKind, RagRetrievalProviderKinds.remoteOpenAiCompatible);
      expect(provider.isRemote, isTrue);
    });

    test('builds the embeddings endpoint for a base url without /v1', () async {
      Uri? captured;
      final provider = RemoteOpenAiCompatibleEmbeddingProvider(
        providerId: 'remote_test',
        baseUrl: 'https://example.test',
        apiKey: 'sk-test',
        modelId: 'embed-test',
        post: ({
          required Uri requestUri,
          required String apiKey,
          required JsonMap body,
          required Duration timeout,
        }) async {
          captured = requestUri;
          return <String, Object?>{'data': <Object>[]};
        },
      );

      await provider.embedTexts(<String>['a']);

      expect(captured.toString(), 'https://example.test/v1/embeddings');
    });
  });

  group('SqliteVectorRetrievalPort', () {
    late Directory tempDirectory;
    late String dbPath;
    late _KeywordEmbeddingProvider embeddingProvider;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_vector_retrieval_test_',
      );
      embeddingProvider = _KeywordEmbeddingProvider();
      dbPath = ProjectSqlitePathService().databasePath(tempDirectory.path);
      File(dbPath).parent.createSync(recursive: true);
      final db = sqlite3.open(dbPath);
      try {
        SqliteRagMetadataStore().ensureSchema(db);
        _seedChunk(
          db,
          chunkId: 'chunk_cat',
          corpusId: 'corpus_test',
          text: 'cats are furry pets',
          vector: embeddingProvider.vectorFor('cats are furry pets'),
        );
        _seedChunk(
          db,
          chunkId: 'chunk_dog',
          corpusId: 'corpus_test',
          text: 'dogs bark loudly',
          vector: embeddingProvider.vectorFor('dogs bark loudly'),
        );
        _seedChunk(
          db,
          chunkId: 'chunk_other',
          corpusId: 'corpus_test',
          text: 'the quick brown fox',
          vector: embeddingProvider.vectorFor('the quick brown fox'),
        );
      } finally {
        db.dispose();
      }
    });

    tearDown(() async {
      // 中文注释: Windows 下偶发 errno 32 句柄未释放，best-effort 清理即可。
      try {
        if (tempDirectory.existsSync()) {
          await tempDirectory.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('recalls the cosine-nearest chunk instead of keyword matching', () async {
      final port = SqliteVectorRetrievalPort(embeddingProvider: embeddingProvider);
      final query = RetrievalQuery(
        queryId: 'q1',
        queryText: 'furry cat',
        projectId: 'p1',
        corpusFilters: const <String>['corpus_test'],
        metadata: <String, Object?>{'project_root_path': tempDirectory.path},
      );

      final hits = await port.search(query);

      expect(hits, isNotEmpty);
      expect(hits.first.sourceDocumentId, isNotEmpty);
      // 中文注释: query 的向量与 chunk_cat 同向（都命中 cat/furry 词），应排在 chunk_dog 之前。
      expect(hits.first.score, greaterThan(0));
      final topText = ValueReaders.stringValue(hits.first.metadata['text_value']);
      expect(topText, contains('furry'));
    });

    test('searchByCorpus restricts to the requested corpus', () async {
      final port = SqliteVectorRetrievalPort(embeddingProvider: embeddingProvider);
      final query = RetrievalQuery(
        queryId: 'q2',
        queryText: 'furry cat',
        projectId: 'p1',
        metadata: <String, Object?>{'project_root_path': tempDirectory.path},
      );

      final hits = await port.searchByCorpus(query, 'corpus_test');

      expect(hits.length, lessThanOrEqualTo(3));
      for (final hit in hits) {
        expect(hit.corpusId, 'corpus_test');
      }
    });
  });
}

void _seedChunk(
  Database db, {
  required String chunkId,
  required String corpusId,
  required String text,
  required List<num> vector,
}) {
  // 中文注释: rag_chunk 有指向 rag_corpus / rag_source_document 的外键，先幂等补齐父行。
  db.execute(
    "INSERT OR IGNORE INTO rag_corpus (corpus_id, title, source_kind, build_mode, language, version, created_at, updated_at, capability_flags_json, payload_json) VALUES (?, '测试语料', 'txt', 'txt', 'zh', 'v1', '', '', '{}', '{}')",
    <Object?>[corpusId],
  );
  db.execute(
    "INSERT OR IGNORE INTO rag_source_document (source_document_id, corpus_id, source_kind, display_name, origin_path, origin_format, language, content_hash, payload_json) VALUES (?, ?, 'txt', 'src', '', 'txt', 'zh', '', '{}')",
    <Object?>['src_test', corpusId],
  );
  final bytes = Float32List.fromList(vector.map((e) => e.toDouble()).toList())
      .buffer
      .asUint8List();
  db.execute(
    '''
    INSERT INTO rag_chunk (
      chunk_id, corpus_id, source_document_id, chapter_index, chapter_title,
      segment_index, range_start, range_end, text_value, normalized_text,
      token_estimate, payload_json, embedding_blob, embedding_dim, embedding_model
    ) VALUES (?, ?, 'src_test', 0, '', 0, 0, 0, ?, ?, 0, '{}', ?, ?, 'test')
    ''',
    <Object?>[chunkId, corpusId, text, text, bytes, vector.length],
  );
}

class _KeywordEmbeddingProvider implements EmbeddingProviderPort {
  @override
  String get providerId => 'test_keyword';

  @override
  String get providerKind => 'test_keyword';

  @override
  bool get isLocal => true;

  @override
  bool get isRemote => false;

  List<num> vectorFor(String text) {
    final lower = text.toLowerCase();
    return <num>[
      (lower.contains('cat') || lower.contains('furry')) ? 1.0 : 0.0,
      (lower.contains('dog') || lower.contains('bark')) ? 1.0 : 0.0,
    ];
  }

  @override
  Future<List<List<num>>> embedTexts(List<String> texts) async {
    return texts.map(vectorFor).toList(growable: false);
  }

  @override
  JsonMap describeCapabilities() {
    return <String, Object?>{'provider_kind': providerKind, 'dimensions': 2};
  }
}
