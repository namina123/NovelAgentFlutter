import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'project_sqlite_path_service.dart';
import 'sqlite_rag_metadata_store.dart';

class SqliteRagIngestionBundlePersistenceRuntime {
  const SqliteRagIngestionBundlePersistenceRuntime();

  Future<void> persist({
    required String projectRootPath,
    required RagCorpusPackage corpusPackage,
    required RagSourceDocument sourceDocument,
    required List<RagChunk> chunks,
    required RagIndexHandle indexHandle,
    required JsonMap ingestionRun,
    int chunkBatchSize = 32,
    Future<void> Function(int completedChunks, int totalChunks)? onChunkBatchCommitted,
  }) async {
    final receivePort = ReceivePort();
    final request = _SqliteRagIngestionBundleWriteRequest(
      projectRootPath: projectRootPath,
      corpusPackageJson: corpusPackage.toJson(),
      sourceDocumentJson: sourceDocument.toJson(),
      chunkJsonList: chunks.map((entry) => entry.toJson()).toList(growable: false),
      indexHandleJson: indexHandle.toJson(),
      ingestionRunJson: ingestionRun,
      chunkBatchSize: chunkBatchSize,
    );
    final isolate = await Isolate.spawn<Map<String, Object?>>(
      _persistRagIngestionBundleInIsolate,
      <String, Object?>{
        'request': request.toJson(),
        'send_port': receivePort.sendPort,
      },
    );
    try {
      await for (final dynamic message in receivePort) {
        if (message is! Map) {
          continue;
        }
        final kind = message['kind']?.toString() ?? '';
        if (kind == 'progress') {
          if (onChunkBatchCommitted != null) {
            await onChunkBatchCommitted(
              _intValue(message['completed']),
              _intValue(message['total']),
            );
          }
          continue;
        }
        if (kind == 'done') {
          return;
        }
        if (kind == 'error') {
          final detail = message['message']?.toString().trim() ?? '未知错误';
          throw StateError('SQLite 语料写入失败：$detail');
        }
      }
      throw StateError('SQLite 语料写入提前结束。');
    } finally {
      receivePort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }
}

void _persistRagIngestionBundleInIsolate(
  Map<String, Object?> invocation,
) {
  try {
    final sendPort = invocation['send_port'] as SendPort;
    final request = _SqliteRagIngestionBundleWriteRequest.fromJson(
      (invocation['request'] as Map<Object?, Object?>).map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    final corpusPackage = RagCorpusPackage.fromJson(request.corpusPackageJson);
    final sourceDocument = RagSourceDocument.fromJson(
      request.sourceDocumentJson,
    );
    final chunks = request.chunkJsonList
        .map(RagChunk.fromJson)
        .toList(growable: false);
    final indexHandle = RagIndexHandle.fromJson(request.indexHandleJson);
    final sqlitePathService = ProjectSqlitePathService();
    final metadataStore = SqliteRagMetadataStore();
    final dbPath = sqlitePathService.databasePath(request.projectRootPath);
    File(dbPath).parent.createSync(recursive: true);
    final database = sqlite3.open(dbPath);
    try {
      metadataStore.ensureSchema(database);
      metadataStore.saveBootstrapMetadata(database);
      database.execute('BEGIN IMMEDIATE TRANSACTION;');
      _upsert(
        database,
        tableName: 'rag_corpus',
        keyColumns: const <String>['corpus_id'],
        values: <String, Object?>{
          'corpus_id': corpusPackage.corpusId,
          'title': corpusPackage.title,
          'source_kind': corpusPackage.sourceKind,
          'build_mode': corpusPackage.buildMode,
          'language': corpusPackage.language,
          'version': corpusPackage.version,
          'created_at': corpusPackage.createdAt,
          'updated_at': corpusPackage.updatedAt,
          'source_count': corpusPackage.sourceCount,
          'chapter_count': corpusPackage.chapterCount,
          'chunk_count': corpusPackage.chunkCount,
          'is_model_assisted': corpusPackage.isModelAssisted ? 1 : 0,
          'capability_flags_json': jsonEncode(corpusPackage.capabilityFlags),
          'payload_json': jsonEncode(corpusPackage.toJson()),
        },
      );
      _upsert(
        database,
        tableName: 'rag_source_document',
        keyColumns: const <String>['source_document_id'],
        values: <String, Object?>{
          'source_document_id': sourceDocument.sourceDocumentId,
          'corpus_id': sourceDocument.corpusId,
          'source_kind': sourceDocument.sourceKind,
          'display_name': sourceDocument.displayName,
          'origin_path': sourceDocument.originPath,
          'origin_format': sourceDocument.originFormat,
          'language': sourceDocument.language,
          'content_hash': sourceDocument.contentHash,
          'payload_json': jsonEncode(sourceDocument.toJson()),
        },
      );
      var completed = 0;
      for (final chunk in chunks) {
        final embedding = _embeddingBlob(
          chunk.metadata['embedding'],
        );
        _upsert(
          database,
          tableName: 'rag_chunk',
          keyColumns: const <String>['chunk_id'],
          values: <String, Object?>{
            'chunk_id': chunk.chunkId,
            'corpus_id': chunk.corpusId,
            'source_document_id': chunk.sourceDocumentId,
            'chapter_index': chunk.chapterIndex,
            'chapter_title': chunk.chapterTitle,
            'segment_index': chunk.segmentIndex,
            'range_start': chunk.rangeStart,
            'range_end': chunk.rangeEnd,
            'text_value': chunk.text,
            'normalized_text': chunk.normalizedText,
            'token_estimate': chunk.tokenEstimate,
            'payload_json': jsonEncode(chunk.toJson()),
            // 中文注释: 向量随 chunk 一起在同一事务写入，避免二次开库与跨批次不一致。
            'embedding_blob': embedding.blob,
            'embedding_dim': embedding.dimension,
            'embedding_model':
                ValueReaders.stringValue(chunk.metadata['embedding_model']),
          },
        );
        completed += 1;
        if (completed % request.chunkBatchSize == 0 || completed == chunks.length) {
          sendPort.send(<String, Object?>{
            'kind': 'progress',
            'completed': completed,
            'total': chunks.length,
          });
        }
      }
      _upsert(
        database,
        tableName: 'rag_index_handle',
        keyColumns: const <String>['index_handle_id'],
        values: <String, Object?>{
          'index_handle_id': indexHandle.indexHandleId,
          'corpus_id': indexHandle.corpusId,
          'backend_kind': indexHandle.backendKind,
          'backend_location': indexHandle.backendLocation,
          'embedding_dimension': indexHandle.embeddingDimension,
          'status': indexHandle.status,
          'version': indexHandle.version,
          'last_built_at': indexHandle.lastBuiltAt,
          'payload_json': jsonEncode(indexHandle.toJson()),
        },
      );
      _upsert(
        database,
        tableName: 'rag_ingestion_run',
        keyColumns: const <String>['ingestion_run_id'],
        values: <String, Object?>{
          'ingestion_run_id':
              request.ingestionRunJson['ingestion_run_id']?.toString() ?? '',
          'project_id': request.ingestionRunJson['project_id']?.toString() ?? '',
          'corpus_id': request.ingestionRunJson['corpus_id']?.toString() ?? '',
          'source_document_id':
              request.ingestionRunJson['source_document_id']?.toString() ?? '',
          'status': request.ingestionRunJson['status']?.toString() ?? '',
          'started_at': request.ingestionRunJson['started_at']?.toString() ?? '',
          'updated_at': request.ingestionRunJson['updated_at']?.toString() ?? '',
          'payload_json': jsonEncode(request.ingestionRunJson),
        },
      );
      database.execute('COMMIT;');
      sendPort.send(const <String, Object?>{'kind': 'done'});
    } catch (error) {
      database.execute('ROLLBACK;');
      rethrow;
    } finally {
      database.dispose();
    }
  } catch (error) {
    final sendPort = invocation['send_port'] as SendPort;
    sendPort.send(<String, Object?>{
      'kind': 'error',
      'message': error.toString(),
    });
  }
}

void _upsert(
  Database database, {
  required String tableName,
  required List<String> keyColumns,
  required Map<String, Object?> values,
}) {
  final columns = values.keys.toList(growable: false);
  final placeholders = List<String>.filled(columns.length, '?').join(', ');
  final assignments = columns
      .where((column) => !keyColumns.contains(column))
      .map((column) => '$column = excluded.$column')
      .join(', ');
  database.execute(
    '''
    INSERT INTO $tableName (${columns.join(', ')})
    VALUES ($placeholders)
    ON CONFLICT(${keyColumns.join(', ')}) DO UPDATE SET $assignments
    ''',
    values.values.toList(growable: false),
  );
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// 把 chunk.metadata['embedding']（JSON 往返后的 List<dynamic>）编码成 Float32 BLOB。
({Uint8List? blob, int dimension}) _embeddingBlob(Object? raw) {
  if (raw is! List || raw.isEmpty) {
    return (blob: null, dimension: 0);
  }
  final doubles = <double>[];
  for (final value in raw) {
    if (value is num) {
      doubles.add(value.toDouble());
    } else {
      return (blob: null, dimension: 0);
    }
  }
  final float32 = Float32List.fromList(doubles);
  return (blob: float32.buffer.asUint8List(), dimension: doubles.length);
}

class _SqliteRagIngestionBundleWriteRequest {
  const _SqliteRagIngestionBundleWriteRequest({
    required this.projectRootPath,
    required this.corpusPackageJson,
    required this.sourceDocumentJson,
    required this.chunkJsonList,
    required this.indexHandleJson,
    required this.ingestionRunJson,
    required this.chunkBatchSize,
  });

  final String projectRootPath;
  final JsonMap corpusPackageJson;
  final JsonMap sourceDocumentJson;
  final List<JsonMap> chunkJsonList;
  final JsonMap indexHandleJson;
  final JsonMap ingestionRunJson;
  final int chunkBatchSize;

  JsonMap toJson() {
    return <String, Object?>{
      'project_root_path': projectRootPath,
      'corpus_package_json': corpusPackageJson,
      'source_document_json': sourceDocumentJson,
      'chunk_json_list': chunkJsonList,
      'index_handle_json': indexHandleJson,
      'ingestion_run_json': ingestionRunJson,
      'chunk_batch_size': chunkBatchSize,
    };
  }

  factory _SqliteRagIngestionBundleWriteRequest.fromJson(JsonMap json) {
    return _SqliteRagIngestionBundleWriteRequest(
      projectRootPath: json['project_root_path']?.toString() ?? '',
      corpusPackageJson: _mapValue(json['corpus_package_json']),
      sourceDocumentJson: _mapValue(json['source_document_json']),
      chunkJsonList: _mapList(json['chunk_json_list']),
      indexHandleJson: _mapValue(json['index_handle_json']),
      ingestionRunJson: _mapValue(json['ingestion_run_json']),
      chunkBatchSize: _intValue(json['chunk_batch_size']),
    );
  }
}

JsonMap _mapValue(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>(
      (key, nested) => MapEntry(key.toString(), nested),
    );
  }
  return <String, Object?>{};
}

List<JsonMap> _mapList(Object? value) {
  if (value is! List) {
    return const <JsonMap>[];
  }
  return value.map(_mapValue).toList(growable: false);
}
