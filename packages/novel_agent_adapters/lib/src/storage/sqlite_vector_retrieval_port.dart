import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'project_sqlite_path_service.dart';
import 'sqlite_rag_metadata_store.dart';

/// 本地 SQLite 暴力 cosine 向量检索端口（纯 Dart，跨端，无原生向量扩展依赖）。
///
/// 中文注释: 写入由语料 ingestion 在同一事务里把 embedding_blob 落进 rag_chunk；
/// 这里只负责检索：embed 查询 -> 取候选 chunk 的向量 -> 算 cosine -> 取 topK。
/// 规模在小说级语料（< 数万 chunk）下足够，无需引入 sqlite-vss 等原生扩展。
class SqliteVectorRetrievalPort implements RetrievalSearchPort {
  SqliteVectorRetrievalPort({
    required EmbeddingProviderPort embeddingProvider,
    this.defaultTopK = 12,
    this.excerptLength = 160,
  }) : _embeddingProvider = embeddingProvider;

  final EmbeddingProviderPort _embeddingProvider;
  final int defaultTopK;
  final int excerptLength;

  @override
  Future<List<RetrievalHit>> search(RetrievalQuery query) {
    return _searchInCorpora(query, query.corpusFilters.toSet());
  }

  @override
  Future<List<RetrievalHit>> searchWithinMounts(
    RetrievalQuery query,
    List<RetrievalMountBinding> bindings,
  ) {
    final corpusIds = bindings.map((entry) => entry.corpusId).toSet();
    return _searchInCorpora(query, corpusIds);
  }

  @override
  Future<List<RetrievalHit>> searchByCorpus(
    RetrievalQuery query,
    RagCorpusId corpusId,
  ) {
    return _searchInCorpora(query, <String>{corpusId});
  }

  Future<List<RetrievalHit>> _searchInCorpora(
    RetrievalQuery query,
    Set<String> corpusIds,
  ) async {
    final rootPath = ValueReaders.stringValue(
      query.metadata['project_root_path'],
    );
    if (rootPath.isEmpty || query.queryText.trim().isEmpty) {
      return const <RetrievalHit>[];
    }
    final queryVectors = await _embeddingProvider.embedTexts(<String>[
      query.queryText,
    ]);
    if (queryVectors.isEmpty || queryVectors.first.isEmpty) {
      return const <RetrievalHit>[];
    }
    final queryVector = queryVectors.first;
    final topK = query.topK > 0 ? query.topK : defaultTopK;

    final dbPath = ProjectSqlitePathService().databasePath(rootPath);
    final file = File(dbPath);
    if (!file.existsSync()) {
      return const <RetrievalHit>[];
    }
    final database = sqlite3.open(dbPath);
    try {
      SqliteRagMetadataStore().ensureSchema(database);
      final where = _buildWhereClause(corpusIds);
      final rows = database.select('''
        SELECT chunk_id, corpus_id, source_document_id, chapter_title,
               range_start, range_end, text_value, embedding_blob, embedding_dim
        FROM rag_chunk
        WHERE embedding_dim > 0 AND embedding_blob IS NOT NULL $where
        ''');
      final scored = <_ScoredChunk>[];
      for (final row in rows) {
        final blob = row['embedding_blob'];
        if (blob is! Uint8List) {
          continue;
        }
        final vector = _float32Vector(blob);
        final score = _cosine(queryVector, vector);
        if (!score.isFinite) {
          continue;
        }
        scored.add(_ScoredChunk(row: row, score: score));
      }
      scored.sort((a, b) => b.score.compareTo(a.score));
      return scored
          .take(topK)
          .map((entry) => entry.toHit(this))
          .toList(growable: false);
    } finally {
      database.dispose();
    }
  }

  String _buildWhereClause(Set<String> corpusIds) {
    if (corpusIds.isEmpty) {
      return '';
    }
    final quoted = corpusIds
        .where((id) => id.isNotEmpty)
        .map((id) => "'${id.replaceAll("'", "''")}'")
        .join(', ');
    if (quoted.isEmpty) {
      return '';
    }
    return 'AND corpus_id IN ($quoted)';
  }

  List<double> _float32Vector(Uint8List blob) {
    if (blob.lengthInBytes < 4) {
      return const <double>[];
    }
    final floats = Float32List.view(
      blob.buffer,
      blob.offsetInBytes,
      blob.lengthInBytes ~/ 4,
    );
    return List<double>.generate(floats.length, (i) => floats[i].toDouble());
  }

  double _cosine(List<num> a, List<double> b) {
    final length = a.length < b.length ? a.length : b.length;
    if (length == 0) {
      return 0;
    }
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < length; i++) {
      final ai = a[i].toDouble();
      final bi = b[i];
      dot += ai * bi;
      normA += ai * ai;
      normB += bi * bi;
    }
    if (normA == 0 || normB == 0) {
      return 0;
    }
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  String excerpt(String text) {
    final trimmed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.length <= excerptLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, excerptLength)}…';
  }
}

class _ScoredChunk {
  _ScoredChunk({required this.row, required this.score});

  final Row row;
  final double score;

  RetrievalHit toHit(SqliteVectorRetrievalPort port) {
    final text = row['text_value']?.toString() ?? '';
    return RetrievalHit(
      hitId: '${row['chunk_id']}_vector_hit',
      corpusId: row['corpus_id']?.toString() ?? '',
      sourceDocumentId: row['source_document_id']?.toString() ?? '',
      score: score,
      rerankScore: score,
      excerpt: port.excerpt(text),
      rangeStart: ValueReaders.intValue(row['range_start'], 0),
      rangeEnd: ValueReaders.intValue(row['range_end'], 0),
      chapterTitle: row['chapter_title']?.toString() ?? '',
      metadata: <String, Object?>{
        'retrieval_mode': 'vector_sqlite_cosine',
        'text_value': text,
      },
    );
  }
}
