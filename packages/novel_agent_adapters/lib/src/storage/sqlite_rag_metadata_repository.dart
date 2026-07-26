import 'dart:async';
import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_rag_ingestion_bundle_persistence_runtime.dart';
import 'sqlite_project_database_opener.dart';
import 'sqlite_rag_metadata_store.dart';

class SqliteRagMetadataRepository {
  SqliteRagMetadataRepository({
    SqliteProjectDatabaseOpener? databaseOpener,
    SqliteRagMetadataStore? metadataStore,
    SqliteRagIngestionBundlePersistenceRuntime?
    ingestionBundlePersistenceRuntime,
  }) : _databaseOpener = databaseOpener ?? SqliteProjectDatabaseOpener(),
       _metadataStore = metadataStore ?? SqliteRagMetadataStore(),
       _ingestionBundlePersistenceRuntime =
           ingestionBundlePersistenceRuntime ??
           SqliteRagIngestionBundlePersistenceRuntime();

  final SqliteProjectDatabaseOpener _databaseOpener;
  final SqliteRagMetadataStore _metadataStore;
  final SqliteRagIngestionBundlePersistenceRuntime
  _ingestionBundlePersistenceRuntime;

  Future<void> persistIngestionBundle({
    required ProjectDescriptor project,
    required RagCorpusPackage corpusPackage,
    required RagSourceDocument sourceDocument,
    required List<RagChunk> chunks,
    required RagIndexHandle indexHandle,
    required JsonMap ingestionRun,
    int chunkBatchSize = 32,
    FutureOr<void> Function(int completedChunks, int totalChunks)?
    onChunkBatchCommitted,
  }) async {
    // 中文注释: 大批量 RAG 写入搬到后台 isolate，避免 UI isolate 在 SQLite 事务期间持续卡死。
    await _ingestionBundlePersistenceRuntime.persist(
      projectRootPath: project.rootPath,
      corpusPackage: corpusPackage,
      sourceDocument: sourceDocument,
      chunks: chunks,
      indexHandle: indexHandle,
      ingestionRun: ingestionRun,
      chunkBatchSize: chunkBatchSize,
      onChunkBatchCommitted: onChunkBatchCommitted == null
          ? null
          : (completedChunks, totalChunks) async {
              await onChunkBatchCommitted(completedChunks, totalChunks);
            },
    );
  }

  Future<void> upsertCorpus(
    ProjectDescriptor project,
    RagCorpusPackage corpusPackage,
  ) async {
    // 中文注释: 语料包写入只落元数据与稳定索引字段，不在这里接任何检索后端实现。
    await _runWrite(project, () async {
      _upsert(
        tableName: 'rag_corpus',
        keyColumns: <String>['corpus_id'],
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
    });
  }

  Future<RagCorpusPackage?> readCorpus(
    ProjectDescriptor project, {
    required String corpusId,
  }) async {
    // 中文注释: 读取语料包只恢复保存的正式合同，不做任何派生推断。
    final row = await _readSingle(
      project,
      tableName: 'rag_corpus',
      whereClause: 'corpus_id = ?',
      parameters: <Object?>[corpusId],
    );
    if (row == null) {
      return null;
    }
    return RagCorpusPackage.fromJson(_payloadFromRow(row));
  }

  Future<List<RagCorpusPackage>> listCorpora(
    ProjectDescriptor project, {
    String? sourceKind,
  }) async {
    // 中文注释: 列表接口只做轻量过滤，供后续挂载与摘要层消费。
    final rows = await _readMany(
      project,
      tableName: 'rag_corpus',
      whereClause: sourceKind == null || sourceKind.trim().isEmpty
          ? ''
          : 'source_kind = ?',
      parameters: sourceKind == null || sourceKind.trim().isEmpty
          ? const <Object?>[]
          : <Object?>[sourceKind],
      orderBy: 'source_kind, title, corpus_id',
    );
    return rows
        .map((row) => RagCorpusPackage.fromJson(_payloadFromRow(row)))
        .toList(growable: false);
  }

  Future<void> upsertSourceDocument(
    ProjectDescriptor project,
    RagSourceDocument sourceDocument,
  ) async {
    // 中文注释: 源文稿写入保存来源边界与正文来源锚点，不在这里做分章。
    await _runWrite(project, () async {
      _upsert(
        tableName: 'rag_source_document',
        keyColumns: <String>['source_document_id'],
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
    });
  }

  Future<RagSourceDocument?> readSourceDocument(
    ProjectDescriptor project, {
    required String sourceDocumentId,
  }) async {
    // 中文注释: 单个源文稿读取走稳定 id，不引入额外检索语义。
    final row = await _readSingle(
      project,
      tableName: 'rag_source_document',
      whereClause: 'source_document_id = ?',
      parameters: <Object?>[sourceDocumentId],
    );
    if (row == null) {
      return null;
    }
    return RagSourceDocument.fromJson(_payloadFromRow(row));
  }

  Future<List<RagSourceDocument>> listSourceDocuments(
    ProjectDescriptor project, {
    String? corpusId,
  }) async {
    // 中文注释: 源文稿列表只按 corpus 轻量过滤，后续 ingestion runtime 可以直接复用。
    final rows = await _readMany(
      project,
      tableName: 'rag_source_document',
      whereClause: corpusId == null || corpusId.trim().isEmpty
          ? ''
          : 'corpus_id = ?',
      parameters: corpusId == null || corpusId.trim().isEmpty
          ? const <Object?>[]
          : <Object?>[corpusId],
      orderBy: 'corpus_id, source_kind, source_document_id',
    );
    return rows
        .map((row) => RagSourceDocument.fromJson(_payloadFromRow(row)))
        .toList(growable: false);
  }

  Future<void> upsertChunk(ProjectDescriptor project, RagChunk chunk) async {
    // 中文注释: chunk 记录只保存可检索文本单元与范围信息，不把向量索引实现写死进表层。
    await _runWrite(project, () async {
      _upsert(
        tableName: 'rag_chunk',
        keyColumns: <String>['chunk_id'],
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
        },
      );
    });
  }

  Future<RagChunk?> readChunk(
    ProjectDescriptor project, {
    required String chunkId,
  }) async {
    // 中文注释: chunk 读取保持简单的 id 定位，方便后续挂载或证据注入复用。
    final row = await _readSingle(
      project,
      tableName: 'rag_chunk',
      whereClause: 'chunk_id = ?',
      parameters: <Object?>[chunkId],
    );
    if (row == null) {
      return null;
    }
    return RagChunk.fromJson(_payloadFromRow(row));
  }

  Future<List<RagChunk>> listChunks(
    ProjectDescriptor project, {
    String? corpusId,
    String? sourceDocumentId,
  }) async {
    // 中文注释: chunk 列表只支持 corpus/source 两级过滤，避免 repository 变成新的检索引擎。
    final clauses = <String>[];
    final parameters = <Object?>[];
    if (corpusId != null && corpusId.trim().isNotEmpty) {
      clauses.add('corpus_id = ?');
      parameters.add(corpusId);
    }
    if (sourceDocumentId != null && sourceDocumentId.trim().isNotEmpty) {
      clauses.add('source_document_id = ?');
      parameters.add(sourceDocumentId);
    }
    final rows = await _readMany(
      project,
      tableName: 'rag_chunk',
      whereClause: clauses.join(' AND '),
      parameters: parameters,
      orderBy:
          'corpus_id, source_document_id, chapter_index, segment_index, chunk_id',
    );
    return rows
        .map((row) => RagChunk.fromJson(_payloadFromRow(row)))
        .toList(growable: false);
  }

  Future<void> upsertMountBinding(
    ProjectDescriptor project,
    RetrievalMountBinding binding,
  ) async {
    // 中文注释: 挂载绑定只记录项目与语料之间的正式关系，不在这里决定挂载策略。
    await _runWrite(project, () async {
      _upsert(
        tableName: 'rag_mount_binding',
        keyColumns: <String>['binding_id'],
        values: <String, Object?>{
          'binding_id': binding.bindingId,
          'project_id': binding.projectId,
          'corpus_id': binding.corpusId,
          'mount_scope': binding.mountScope,
          'priority': binding.priority,
          'usage_policy': binding.usagePolicy,
          'activation_policy': binding.activationPolicy,
          'created_at': binding.createdAt,
          'payload_json': jsonEncode(binding.toJson()),
        },
      );
    });
  }

  Future<RetrievalMountBinding?> readMountBinding(
    ProjectDescriptor project, {
    required String bindingId,
  }) async {
    // 中文注释: 绑定读取保留 id 级入口，后续 GUI/CLI 只需消费正式挂载状态。
    final row = await _readSingle(
      project,
      tableName: 'rag_mount_binding',
      whereClause: 'binding_id = ?',
      parameters: <Object?>[bindingId],
    );
    if (row == null) {
      return null;
    }
    return RetrievalMountBinding.fromJson(_payloadFromRow(row));
  }

  Future<List<RetrievalMountBinding>> listMountBindings(
    ProjectDescriptor project, {
    String? projectId,
    String? corpusId,
  }) async {
    // 中文注释: 挂载绑定列表默认按项目根下的正式关系返回，可选过滤到单个 corpus。
    final clauses = <String>[];
    final parameters = <Object?>[];
    if (projectId != null && projectId.trim().isNotEmpty) {
      clauses.add('project_id = ?');
      parameters.add(projectId);
    }
    if (corpusId != null && corpusId.trim().isNotEmpty) {
      clauses.add('corpus_id = ?');
      parameters.add(corpusId);
    }
    final rows = await _readMany(
      project,
      tableName: 'rag_mount_binding',
      whereClause: clauses.join(' AND '),
      parameters: parameters,
      orderBy: 'project_id, priority DESC, corpus_id, binding_id',
    );
    return rows
        .map((row) => RetrievalMountBinding.fromJson(_payloadFromRow(row)))
        .toList(growable: false);
  }

  Future<List<RetrievalMountBinding>> listProjectMounts(
    ProjectDescriptor project, {
    required String projectId,
  }) {
    // 中文注释: 项目挂载查询只是一层 project 过滤，不把 mount 语义扩展成新的查询中心。
    return listMountBindings(project, projectId: projectId);
  }

  Future<bool> hasProjectMounts(
    ProjectDescriptor project, {
    required String projectId,
  }) async {
    // 中文注释: 这里返回轻量布尔值给摘要层，避免上层为了判断挂载状态去拉整批对象。
    final rows = await _readMany(
      project,
      tableName: 'rag_mount_binding',
      whereClause: 'project_id = ?',
      parameters: <Object?>[projectId],
      orderBy: 'priority DESC, corpus_id, binding_id',
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> upsertIndexHandle(
    ProjectDescriptor project,
    RagIndexHandle indexHandle,
  ) async {
    // 中文注释: 索引句柄只描述 backend 身份与构建状态，不把 backend 本体绑死在 SQLite 里。
    await _runWrite(project, () async {
      _upsert(
        tableName: 'rag_index_handle',
        keyColumns: <String>['index_handle_id'],
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
    });
  }

  Future<RagIndexHandle?> readIndexHandle(
    ProjectDescriptor project, {
    required String indexHandleId,
  }) async {
    // 中文注释: 索引句柄读取只通过稳定 id 定位，方便将来更换 backend 时保持上层不动。
    final row = await _readSingle(
      project,
      tableName: 'rag_index_handle',
      whereClause: 'index_handle_id = ?',
      parameters: <Object?>[indexHandleId],
    );
    if (row == null) {
      return null;
    }
    return RagIndexHandle.fromJson(_payloadFromRow(row));
  }

  Future<List<RagIndexHandle>> listIndexHandles(
    ProjectDescriptor project, {
    String? corpusId,
  }) async {
    // 中文注释: 索引句柄列表只按 corpus 做轻量过滤，不接任何向量检索职责。
    final clauses = <String>[];
    final parameters = <Object?>[];
    if (corpusId != null && corpusId.trim().isNotEmpty) {
      clauses.add('corpus_id = ?');
      parameters.add(corpusId);
    }
    final rows = await _readMany(
      project,
      tableName: 'rag_index_handle',
      whereClause: clauses.join(' AND '),
      parameters: parameters,
      orderBy: 'corpus_id, status, index_handle_id',
    );
    return rows
        .map((row) => RagIndexHandle.fromJson(_payloadFromRow(row)))
        .toList(growable: false);
  }

  Future<void> upsertIngestionRun(
    ProjectDescriptor project,
    JsonMap ingestionRun,
  ) async {
    // 中文注释: ingestion run 先作为 JSON 化的元数据记录落盘，后续再视需要提升为正式 core 模型。
    await _runWrite(project, () async {
      _upsert(
        tableName: 'rag_ingestion_run',
        keyColumns: <String>['ingestion_run_id'],
        values: <String, Object?>{
          'ingestion_run_id':
              ingestionRun['ingestion_run_id']?.toString() ?? '',
          'project_id': ingestionRun['project_id']?.toString() ?? '',
          'corpus_id': ingestionRun['corpus_id']?.toString() ?? '',
          'source_document_id':
              ingestionRun['source_document_id']?.toString() ?? '',
          'status': ingestionRun['status']?.toString() ?? '',
          'started_at': ingestionRun['started_at']?.toString() ?? '',
          'updated_at': ingestionRun['updated_at']?.toString() ?? '',
          'payload_json': jsonEncode(ingestionRun),
        },
      );
    });
  }

  Future<JsonMap?> readIngestionRun(
    ProjectDescriptor project, {
    required String ingestionRunId,
  }) async {
    // 中文注释: ingestion run 读取保留 JSON 形态，避免在本轮额外引入新的 core 运行模型。
    final row = await _readSingle(
      project,
      tableName: 'rag_ingestion_run',
      whereClause: 'ingestion_run_id = ?',
      parameters: <Object?>[ingestionRunId],
    );
    if (row == null) {
      return null;
    }
    return _payloadFromRow(row);
  }

  Future<List<JsonMap>> listIngestionRuns(
    ProjectDescriptor project, {
    String? corpusId,
    String? sourceDocumentId,
  }) async {
    // 中文注释: ingestion run 列表只做 corpus/source 文档的基础过滤，保持元数据层职责干净。
    final clauses = <String>[];
    final parameters = <Object?>[];
    if (corpusId != null && corpusId.trim().isNotEmpty) {
      clauses.add('corpus_id = ?');
      parameters.add(corpusId);
    }
    if (sourceDocumentId != null && sourceDocumentId.trim().isNotEmpty) {
      clauses.add('source_document_id = ?');
      parameters.add(sourceDocumentId);
    }
    final rows = await _readMany(
      project,
      tableName: 'rag_ingestion_run',
      whereClause: clauses.join(' AND '),
      parameters: parameters,
      orderBy: 'updated_at DESC, ingestion_run_id',
    );
    return rows.map(_payloadFromRow).toList(growable: false);
  }

  Future<void> _runWrite(
    ProjectDescriptor project,
    Future<void> Function() operation,
  ) async {
    // 中文注释: 所有写入统一打开同一个 SQLite 文件，先确保 schema，再在事务里完成原子更新。
    final database = _databaseOpener.open(project.rootPath);
    try {
      _metadataStore.ensureSchema(database);
      _metadataStore.saveBootstrapMetadata(database);
      database.execute('BEGIN IMMEDIATE TRANSACTION;');
      _activeDatabase = database;
      await operation();
      database.execute('COMMIT;');
    } catch (_) {
      database.execute('ROLLBACK;');
      rethrow;
    } finally {
      _activeDatabase = null;
      database.dispose();
    }
  }

  Future<Row?> _readSingle(
    ProjectDescriptor project, {
    required String tableName,
    required String whereClause,
    required List<Object?> parameters,
  }) async {
    // 中文注释: 单条读取只负责把 record 从 SQLite 恢复成 JSON，再由 core model 进行合同化解析。
    final rows = await _readMany(
      project,
      tableName: tableName,
      whereClause: whereClause,
      parameters: parameters,
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<List<Row>> _readMany(
    ProjectDescriptor project, {
    required String tableName,
    required String whereClause,
    required List<Object?> parameters,
    String? orderBy,
    int? limit,
  }) async {
    // 中文注释: 只在这里集中拼查询，避免每个 repository 方法都自己重复 SQLite 字符串模板。
    final database = _databaseOpener.open(project.rootPath);
    try {
      _metadataStore.ensureSchema(database);
      final sql = StringBuffer()..write('SELECT * FROM $tableName');
      if (whereClause.trim().isNotEmpty) {
        sql
          ..write(' WHERE ')
          ..write(whereClause);
      }
      if (orderBy != null && orderBy.trim().isNotEmpty) {
        sql
          ..write(' ORDER BY ')
          ..write(orderBy);
      }
      if (limit != null) {
        sql.write(' LIMIT ?');
        final rows = database.select(sql.toString(), <Object?>[
          ...parameters,
          limit,
        ]);
        return rows;
      }
      return database.select(sql.toString(), parameters);
    } finally {
      database.dispose();
    }
  }

  void _upsert({
    required String tableName,
    required List<String> keyColumns,
    required Map<String, Object?> values,
  }) {
    // 中文注释: 通用 upsert 保持表族写入口径一致，避免每张表单独写一套容易漂移的 SQL。
    final columns = values.keys.toList(growable: false);
    final placeholders = List.filled(columns.length, '?').join(', ');
    final assignments = columns
        .where((column) => !keyColumns.contains(column))
        .map((column) => '$column = excluded.$column')
        .join(', ');
    final database = _activeDatabase;
    if (database == null) {
      throw StateError('sqlite rag metadata database is not open');
    }
    database.execute('''
      INSERT INTO $tableName (${columns.join(', ')})
      VALUES ($placeholders)
      ON CONFLICT(${keyColumns.join(', ')}) DO UPDATE SET $assignments
      ''', values.values.toList(growable: false));
  }

  Database? _activeDatabase;

  JsonMap _payloadFromRow(Row row) {
    // 中文注释: payload_json 是唯一用于恢复完整合同的 JSON 入口，避免底层列和上层合同再分叉。
    final raw = row['payload_json']?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return <String, Object?>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return <String, Object?>{};
    }
    return decoded.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
}
