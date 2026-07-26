import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('RagProjectMountSummaryService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late SqliteRagMetadataRepository repository;
    late RagProjectMountSummaryService summaryService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'rag_project_mount_summary_service_',
      );
      project = ProjectDescriptor(
        id: 'project-rag-mount-1',
        name: 'RAG mount 项目',
        rootPath: tempDirectory.path,
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      repository = SqliteRagMetadataRepository();
      summaryService = RagProjectMountSummaryService(
        metadataRepository: repository,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('summarizes project mounts across multiple corpora', () async {
      await repository.upsertCorpus(
        project,
        RagCorpusPackage(
          corpusId: 'corpus-001',
          title: '语料一',
          sourceKind: 'txt',
          buildMode: 'basic',
          language: 'zh-CN',
          version: 'v1',
        ),
      );
      await repository.upsertCorpus(
        project,
        RagCorpusPackage(
          corpusId: 'corpus-002',
          title: '语料二',
          sourceKind: 'txt',
          buildMode: 'basic',
          language: 'zh-CN',
          version: 'v1',
        ),
      );
      await repository.upsertMountBinding(
        project,
        RetrievalMountBinding.fromJson(<String, Object?>{
          'binding_id': 'binding-001',
          'project_id': project.id,
          'corpus_id': 'corpus-001',
          'mount_scope': 'project',
          'priority': 20,
          'usage_policy': 'reference_only',
          'activation_policy': 'required',
          'created_at': '2026-06-17T10:00:00Z',
        }),
      );
      await repository.upsertMountBinding(
        project,
        RetrievalMountBinding.fromJson(<String, Object?>{
          'binding_id': 'binding-002',
          'project_id': project.id,
          'corpus_id': 'corpus-002',
          'mount_scope': 'project',
          'priority': 10,
          'usage_policy': 'background_only',
          'activation_policy': 'optional',
          'created_at': '2026-06-17T10:05:00Z',
        }),
      );

      final projectMounts = await repository.listProjectMounts(
        project,
        projectId: project.id,
      );
      final hasProjectMounts = await repository.hasProjectMounts(
        project,
        projectId: project.id,
      );
      final summary = await summaryService.summarize(project);

      expect(projectMounts, hasLength(2));
      expect(hasProjectMounts, isTrue);
      expect(summary.bindingCount, 2);
      expect(
        summary.corpusIds,
        containsAll(<String>['corpus-001', 'corpus-002']),
      );
      expect(summary.topCorpusId, 'corpus-001');
      expect(summary.topBindingId, 'binding-001');
      expect(summary.topUsagePolicy, 'reference_only');
      expect(summary.toJson()['has_bindings'], isTrue);
    });
  });
}
