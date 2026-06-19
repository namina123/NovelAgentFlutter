import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectRagRetrievalActivationBridgeService {
  const ProjectRagRetrievalActivationBridgeService();

  RetrievalActivationPackage buildPackage(
    ProjectDescriptor project,
    JsonMap retrievalResult,
  ) {
    // 中文注释: 这里把 RAG 检索结果收束成共享 activation package，方便上层消费正式证据包而不是裸 hits。
    final query = ValueReaders.mapValue(retrievalResult['retrieval_query']);
    final selectedHits = _selectedHits(retrievalResult);
    final sourceSummaries = _stringListOrFallback(
      retrievalResult['source_summaries'],
      selectedHits.map(_sourceSummaryFromHit),
    );
    final warningNotes = _stringListOrFallback(
      retrievalResult['warning_notes'],
      _warningNotes(retrievalResult),
    );
    final citationPaths = _dedupeStrings(
      _stringListOrFallback(
        retrievalResult['citation_paths'],
        selectedHits.map((hit) => hit.evidencePath),
      ),
    );
    final querySummary = _querySummary(project, retrievalResult, query);
    final packageId = _activationPackageId(project, query);
    return RetrievalActivationPackage(
      activationPackageId: packageId,
      querySummary: querySummary,
      selectedHits: selectedHits,
      sourceSummaries: sourceSummaries,
      warningNotes: warningNotes,
      citationPaths: citationPaths,
      metadata: <String, Object?>{
        'project_id': project.id,
        'project_name': project.name,
        'retrieval_query': ValueReaders.deepCopyMap(query),
        'retrieval_hit_count': selectedHits.length,
        'retrieval_activation_origin': ValueReaders.stringValue(
          retrievalResult['display_text'],
        ).trim(),
        'mount_summary': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(retrievalResult['mount_summary']),
        ),
        'warning_note_count': warningNotes.length,
        'source_summary_count': sourceSummaries.length,
        'citation_path_count': citationPaths.length,
      },
    );
  }

  JsonMap buildPackageJson(
    ProjectDescriptor project,
    JsonMap retrievalResult,
  ) {
    // 中文注释: 上层有时只需要 JSON 结果，因此这里提供一个薄投影，不强迫调用方提前关心对象实例。
    return buildPackage(project, retrievalResult).toJson();
  }

  List<RetrievalHit> _selectedHits(JsonMap retrievalResult) {
    // 中文注释: hits 只从检索结果投影，不回读宿主私有结构，也不在桥接层重排底层语义。
    final result = <RetrievalHit>[];
    for (final rawHit in ValueReaders.mapList(retrievalResult['retrieval_hits'])) {
      final hit = RetrievalHit.fromJson(ValueReaders.deepCopyMap(rawHit));
      if (hit.validateBasics().isEmpty) {
        result.add(hit);
      }
    }
    return result;
  }

  List<String> _stringListOrFallback(
    Object? value,
    Iterable<String> fallback,
  ) {
    // 中文注释: 这里优先使用检索结果自带的稳定摘要，缺失时再从 hits 推导，避免桥接层吞掉 traceability。
    final direct = ValueReaders.stringList(value)
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (direct.isNotEmpty) {
      return _dedupeStrings(direct);
    }
    return _dedupeStrings(
      fallback
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
    );
  }

  List<String> _warningNotes(JsonMap retrievalResult) {
    // 中文注释: warning notes 至少要保留失败原因或状态摘要，避免 activation package 变成没有解释的空壳。
    final notes = <String>[
      ValueReaders.stringValue(retrievalResult['error']).trim(),
      ValueReaders.stringValue(retrievalResult['display_text']).trim(),
    ].where((entry) => entry.isNotEmpty).toList(growable: false);
    if (notes.isNotEmpty) {
      return _dedupeStrings(notes);
    }
    if (_selectedHits(retrievalResult).isEmpty) {
      return const <String>['未召回任何检索命中。'];
    }
    return const <String>[];
  }

  String _querySummary(
    ProjectDescriptor project,
    JsonMap retrievalResult,
    JsonMap query,
  ) {
    // 中文注释: querySummary 负责把检索意图压成可读短句，不把原始 hits 当成正式摘要。
    final queryText = ValueReaders.stringValue(query['query_text']).trim();
    final queryId = ValueReaders.stringValue(query['query_id']).trim();
    final parts = <String>[];
    if (project.id.trim().isNotEmpty) {
      parts.add('project=${project.id}');
    }
    if (queryText.isNotEmpty) {
      parts.add('query=$queryText');
    }
    if (queryId.isNotEmpty) {
      parts.add('query_id=$queryId');
    }
    final topK = ValueReaders.intValue(query['top_k']);
    if (topK > 0) {
      parts.add('top_k=$topK');
    }
    final corpusFilters = ValueReaders.stringList(query['corpus_filters']);
    if (corpusFilters.isNotEmpty) {
      parts.add('corpora=${corpusFilters.join(",")}');
    }
    final sourceFilters = ValueReaders.stringList(query['source_filters']);
    if (sourceFilters.isNotEmpty) {
      parts.add('sources=${sourceFilters.join(",")}');
    }
    final queryMode = ValueReaders.stringValue(query['query_mode']).trim();
    if (queryMode.isNotEmpty) {
      parts.add('mode=$queryMode');
    }
    final rerankPolicy = ValueReaders.stringValue(query['rerank_policy']).trim();
    if (rerankPolicy.isNotEmpty) {
      parts.add('rerank=$rerankPolicy');
    }
    final evidenceBudget = ValueReaders.intValue(query['evidence_budget']);
    if (evidenceBudget > 0) {
      parts.add('evidence_budget=$evidenceBudget');
    }
    if (parts.isNotEmpty) {
      return parts.join('；');
    }
    final displayText = ValueReaders.stringValue(retrievalResult['display_text'])
        .trim();
    if (displayText.isNotEmpty) {
      return displayText;
    }
    final errorText = ValueReaders.stringValue(retrievalResult['error']).trim();
    if (errorText.isNotEmpty) {
      return errorText;
    }
    return 'RAG retrieval activation';
  }

  String _activationPackageId(
    ProjectDescriptor project,
    JsonMap query,
  ) {
    // 中文注释: activation package id 需要跨宿主稳定且可回指，所以优先组合 project 与 query_id。
    final queryId = ValueReaders.stringValue(query['query_id']).trim();
    final projectId = project.id.trim().isEmpty ? 'project' : project.id.trim();
    final safeQueryId = queryId.isEmpty ? 'unknown_query' : queryId;
    return 'rag_activation:$projectId:$safeQueryId';
  }

  String _sourceSummaryFromHit(RetrievalHit hit) {
    // 中文注释: 当检索结果没有显式 source summary 时，这里只回退到 corpus/source document 组合，不去推断更高层语义。
    final corpusId = hit.corpusId.trim();
    final sourceDocumentId = hit.sourceDocumentId.trim();
    if (corpusId.isEmpty && sourceDocumentId.isEmpty) {
      return '';
    }
    if (corpusId.isEmpty) {
      return sourceDocumentId;
    }
    if (sourceDocumentId.isEmpty) {
      return corpusId;
    }
    return '$corpusId:$sourceDocumentId';
  }

  List<String> _dedupeStrings(List<String> values) {
    // 中文注释: 去重只服务于稳定投影，不改变原始命中顺序。
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final clean = value.trim();
      if (clean.isEmpty || !seen.add(clean)) {
        continue;
      }
      result.add(clean);
    }
    return result;
  }
}
