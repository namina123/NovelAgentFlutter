import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectRagRetrievalActivationBridgeService', () {
    test(
      'builds a formal retrieval activation package from raw retrieval result',
      () {
        const bridge = ProjectRagRetrievalActivationBridgeService();
        final project = ProjectDescriptor(
          id: 'project-rag-activation-1',
          name: 'RAG activation 项目',
          rootPath: 'project-rag-activation-root',
        );
        final activation = bridge.buildPackage(project, <String, Object?>{
          'display_text': '已召回语料证据片段：1 条',
          'retrieval_query': <String, Object?>{
            'query_id': 'query-001',
            'query_text': '镜潮回扣',
            'project_id': project.id,
            'corpus_filters': <Object?>['corpus-001'],
            'source_filters': <Object?>['source-001'],
            'top_k': 5,
            'query_mode': 'passage_retrieval',
            'rerank_policy': 'lexical',
            'evidence_budget': 120,
          },
          'retrieval_hits': <Object?>[
            <String, Object?>{
              'hit_id': 'chunk-001_hit',
              'corpus_id': 'corpus-001',
              'source_document_id': 'source-001',
              'score': 4.5,
              'rerank_score': 4.5,
              'excerpt': '镜潮回扣在这一章里反复出现。',
              'range_start': 0,
              'range_end': 16,
              'chapter_title': '第一章',
              'evidence_path': 'chapters/01.md#L0-L16',
            },
          ],
          'citation_paths': <Object?>['chapters/01.md#L0-L16'],
          'source_summaries': <Object?>['corpus-001:source-001'],
          'warning_notes': <Object?>['当前项目没有挂载语料，结果可能为空。'],
          'mount_summary': <String, Object?>{
            'project_id': project.id,
            'has_bindings': true,
          },
        });

        expect(
          activation.activationPackageId,
          'rag_activation:project-rag-activation-1:query-001',
        );
        expect(
          activation.querySummary,
          contains('project=project-rag-activation-1'),
        );
        expect(activation.querySummary, contains('query=镜潮回扣'));
        expect(activation.selectedHits, hasLength(1));
        expect(
          activation.selectedHits.single.evidencePath,
          'chapters/01.md#L0-L16',
        );
        expect(activation.sourceSummaries, ['corpus-001:source-001']);
        expect(activation.warningNotes, ['当前项目没有挂载语料，结果可能为空。']);
        expect(activation.citationPaths, ['chapters/01.md#L0-L16']);
        expect(
          ValueReaders.stringValue(activation.metadata['project_id']),
          project.id,
        );
        expect(
          ValueReaders.intValue(activation.metadata['retrieval_hit_count']),
          1,
        );
        expect(
          ValueReaders.intValue(activation.metadata['citation_path_count']),
          1,
        );
      },
    );

    test(
      'falls back to hit-derived summaries and warnings when raw summaries are absent',
      () {
        const bridge = ProjectRagRetrievalActivationBridgeService();
        final project = ProjectDescriptor(
          id: 'project-rag-activation-2',
          name: 'RAG activation fallback 项目',
          rootPath: 'project-rag-activation-root',
        );
        final activation = bridge.buildPackage(project, <String, Object?>{
          'retrieval_query': <String, Object?>{
            'query_id': 'query-002',
            'query_text': '钟楼回声',
          },
          'retrieval_hits': <Object?>[
            <String, Object?>{
              'hit_id': 'chunk-002_hit',
              'corpus_id': 'corpus-002',
              'source_document_id': 'source-002',
              'score': 2.0,
              'rerank_score': 2.0,
              'excerpt': '钟声提示轮回闭环。',
              'range_start': 20,
              'range_end': 36,
              'chapter_title': '第二章',
              'evidence_path': 'chapters/02.md#L20-L36',
            },
          ],
        });

        expect(activation.sourceSummaries, ['corpus-002:source-002']);
        expect(activation.warningNotes, isEmpty);
        expect(activation.citationPaths, ['chapters/02.md#L20-L36']);
      },
    );
  });
}
