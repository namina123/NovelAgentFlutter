import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteRagMetadataRepository', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late SqliteRagMetadataRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-rag-metadata-repository-',
      );
      project = ProjectDescriptor(
        id: 'project_rag_1',
        name: 'RAG SQLite 项目',
        rootPath: tempDirectory.path,
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      repository = SqliteRagMetadataRepository();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('persists corpus, source, chunk, mount and index metadata', () async {
      final corpus = RagCorpusPackage.fromJson(<String, Object?>{
        'corpus_id': 'corpus-001',
        'title': '基础 txt 语料包',
        'source_kind': 'txt',
        'build_mode': 'basic',
        'language': 'zh-CN',
        'version': 'v1',
        'created_at': '2026-06-17T00:00:00Z',
        'updated_at': '2026-06-17T00:00:00Z',
        'source_count': 1,
        'chapter_count': 3,
        'chunk_count': 12,
        'capability_flags': <Object?>['mountable'],
      });
      final source = RagSourceDocument.fromJson(<String, Object?>{
        'source_document_id': 'source-001',
        'corpus_id': 'corpus-001',
        'source_kind': 'txt',
        'display_name': '样本文本',
        'origin_path': 'inputs/sample.txt',
        'origin_format': 'txt',
        'language': 'zh-CN',
        'content_hash': 'hash-001',
      });
      final chunk = RagChunk.fromJson(<String, Object?>{
        'chunk_id': 'chunk-001',
        'corpus_id': 'corpus-001',
        'source_document_id': 'source-001',
        'chapter_index': 1,
        'chapter_title': '第一章',
        'segment_index': 2,
        'text': '第一段原文。',
        'normalized_text': '第一段原文。',
        'token_estimate': 18,
        'range_start': 0,
        'range_end': 18,
      });
      final binding = RetrievalMountBinding.fromJson(<String, Object?>{
        'binding_id': 'binding-001',
        'project_id': 'project_rag_1',
        'corpus_id': 'corpus-001',
        'mount_scope': 'project',
        'priority': 10,
        'usage_policy': 'reference_only',
        'activation_policy': 'required',
        'created_at': '2026-06-17T00:00:00Z',
      });
      final indexHandle = RagIndexHandle.fromJson(<String, Object?>{
        'index_handle_id': 'index-001',
        'corpus_id': 'corpus-001',
        'backend_kind': 'placeholder-local',
        'backend_location': 'local/index.db',
        'embedding_dimension': 768,
        'status': 'ready',
        'version': 'v1',
        'last_built_at': '2026-06-17T00:00:00Z',
      });
      final ingestionRun = <String, Object?>{
        'ingestion_run_id': 'ingestion-001',
        'project_id': 'project_rag_1',
        'corpus_id': 'corpus-001',
        'source_document_id': 'source-001',
        'status': 'completed',
        'started_at': '2026-06-17T00:00:00Z',
        'updated_at': '2026-06-17T00:01:00Z',
      };

      await repository.upsertCorpus(project, corpus);
      await repository.upsertSourceDocument(project, source);
      await repository.upsertChunk(project, chunk);
      await repository.upsertMountBinding(project, binding);
      await repository.upsertIndexHandle(project, indexHandle);
      await repository.upsertIngestionRun(project, ingestionRun);

      final loadedCorpus = await repository.readCorpus(
        project,
        corpusId: 'corpus-001',
      );
      final loadedSource = await repository.readSourceDocument(
        project,
        sourceDocumentId: 'source-001',
      );
      final loadedChunk = await repository.readChunk(
        project,
        chunkId: 'chunk-001',
      );
      final loadedBinding = await repository.readMountBinding(
        project,
        bindingId: 'binding-001',
      );
      final loadedIndexHandle = await repository.readIndexHandle(
        project,
        indexHandleId: 'index-001',
      );
      final loadedIngestionRun = await repository.readIngestionRun(
        project,
        ingestionRunId: 'ingestion-001',
      );
      final listedCorpora = await repository.listCorpora(project);
      final listedSources = await repository.listSourceDocuments(
        project,
        corpusId: 'corpus-001',
      );
      final listedChunks = await repository.listChunks(
        project,
        corpusId: 'corpus-001',
      );
      final listedBindings = await repository.listMountBindings(
        project,
        corpusId: 'corpus-001',
      );
      final listedHandles = await repository.listIndexHandles(
        project,
        corpusId: 'corpus-001',
      );
      final listedRuns = await repository.listIngestionRuns(
        project,
        corpusId: 'corpus-001',
      );

      expect(loadedCorpus, isNotNull);
      expect(loadedCorpus!.title, '基础 txt 语料包');
      expect(loadedSource, isNotNull);
      expect(loadedSource!.displayName, '样本文本');
      expect(loadedChunk, isNotNull);
      expect(loadedChunk!.chapterTitle, '第一章');
      expect(loadedBinding, isNotNull);
      expect(loadedBinding!.projectId, 'project_rag_1');
      expect(loadedIndexHandle, isNotNull);
      expect(loadedIndexHandle!.backendKind, 'placeholder-local');
      expect(loadedIngestionRun, isNotNull);
      expect(loadedIngestionRun!['status'], 'completed');
      expect(listedCorpora, hasLength(1));
      expect(listedSources, hasLength(1));
      expect(listedChunks, hasLength(1));
      expect(listedBindings, hasLength(1));
      expect(listedHandles, hasLength(1));
      expect(listedRuns, hasLength(1));
    });
  });
}
