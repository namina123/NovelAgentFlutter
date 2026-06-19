import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/rag_project_mount_summary_service.dart';
import '../storage/sqlite_rag_metadata_repository.dart';
import '../workflow/project_rag_retrieval_activation_bridge_service.dart';

class ProjectRagRetrievalToolExecutor {
  ProjectRagRetrievalToolExecutor({
    SqliteRagMetadataRepository? metadataRepository,
    RagProjectMountSummaryService? mountSummaryService,
    RetrievalSearchPort? searchPort,
    ProjectRagRetrievalActivationBridgeService? activationBridgeService,
  }) : _metadataRepository =
           metadataRepository ?? SqliteRagMetadataRepository(),
       _mountSummaryService =
           mountSummaryService ?? RagProjectMountSummaryService(
             metadataRepository: metadataRepository ?? SqliteRagMetadataRepository(),
           ),
       _searchPort = searchPort,
       _activationBridgeService =
           activationBridgeService ??
           const ProjectRagRetrievalActivationBridgeService();

  final SqliteRagMetadataRepository _metadataRepository;
  final RagProjectMountSummaryService _mountSummaryService;
  final RetrievalSearchPort? _searchPort;
  final ProjectRagRetrievalActivationBridgeService
  _activationBridgeService;

  Future<JsonMap> retrievePassages(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 这里把 retrieval 工具做成 adapter 薄层，真正检索走注入的 search port，SQLite 只做元数据和挂载约束。
    final query = RetrievalQuery.fromJson(<String, Object?>{
      'query_id': ValueReaders.stringValue(arguments['query_id']).trim(),
      'query_text': ValueReaders.stringValue(arguments['query_text']).trim(),
      'project_id': ValueReaders.stringValue(arguments['project_id']).trim(),
      'corpus_filters': ValueReaders.stringList(arguments['corpus_filters']),
      'source_filters': ValueReaders.stringList(arguments['source_filters']),
      'language': ValueReaders.stringValue(arguments['language']).trim(),
      'top_k': ValueReaders.intValue(arguments['top_k'], 12),
      'query_mode': ValueReaders.stringValue(arguments['query_mode']).trim(),
      'rerank_policy': ValueReaders.stringValue(arguments['rerank_policy']).trim(),
      'evidence_budget': ValueReaders.intValue(arguments['evidence_budget']),
      'metadata': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(arguments['metadata']),
      ),
    });
    final validationErrors = query.validateBasics();
    if (validationErrors.isNotEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '语料检索查询参数不合法。',
        'display_text': '语料检索查询参数不合法。',
        'changed_paths': const <String>[],
        'validation_errors': validationErrors,
      };
    }

    final mountSummary = await _mountSummaryService.summarize(project);
    final mountBindings = await _metadataRepository.listProjectMounts(
      project,
      projectId: project.id,
    );
    final usableBindings = _filterBindings(mountBindings, query);
    final hits = await _searchHits(project, query, usableBindings);
    final selectedHits = hits.take(query.topK).toList(growable: false);
    final retrievalActivationPackage = _activationBridgeService.buildPackage(
      project,
      <String, Object?>{
        'ok': true,
        'display_text': '已召回语料证据片段：${selectedHits.length} 条',
        'retrieval_query': query.toJson(),
        'mount_summary': mountSummary.toJson(),
        'retrieval_hits': selectedHits.map((entry) => entry.toJson()).toList(
          growable: false,
        ),
        'citation_paths': selectedHits
            .map((entry) => entry.evidencePath)
            .where((entry) => entry.trim().isNotEmpty)
            .toList(growable: false),
        'source_summaries': selectedHits
            .map((entry) => '${entry.corpusId}:${entry.sourceDocumentId}')
            .toList(growable: false),
        'warning_notes': <String>[
          if (mountSummary.hasBindings == false)
            '当前项目没有挂载语料，结果可能为空。',
          if (selectedHits.isEmpty) '未召回任何检索命中。',
        ],
      },
    );
    return <String, Object?>{
      'ok': true,
      'display_text': '已召回语料证据片段：${selectedHits.length} 条',
      'changed_paths': const <String>[],
      'retrieval_query': query.toJson(),
      'mount_summary': mountSummary.toJson(),
      'retrieval_hits': selectedHits.map((entry) => entry.toJson()).toList(
        growable: false,
      ),
      'citation_paths': selectedHits
          .map((entry) => entry.evidencePath)
          .where((entry) => entry.trim().isNotEmpty)
          .toList(growable: false),
      'source_summaries': selectedHits
          .map((entry) => '${entry.corpusId}:${entry.sourceDocumentId}')
          .toList(growable: false),
      'warning_notes': <String>[
        if (mountSummary.hasBindings == false)
          '当前项目没有挂载语料，结果可能为空。',
        if (selectedHits.isEmpty) '未召回任何检索命中。',
      ],
      'retrieval_activation_package': retrievalActivationPackage.toJson(),
    };
  }

  List<RetrievalMountBinding> _filterBindings(
    List<RetrievalMountBinding> bindings,
    RetrievalQuery query,
  ) {
    if (query.corpusFilters.isEmpty) {
      return bindings;
    }
    final filters = query.corpusFilters.toSet();
    return bindings
        .where((entry) => filters.contains(entry.corpusId))
        .toList(growable: false);
  }

  Future<List<RetrievalHit>> _searchHits(
    ProjectDescriptor project,
    RetrievalQuery query,
    List<RetrievalMountBinding> bindings,
  ) {
    final searchPort = _searchPort;
    if (searchPort == null) {
      return _lexicalSearch(project, query, bindings);
    }
    if (bindings.isNotEmpty) {
      return Future.value(searchPort.searchWithinMounts(query, bindings));
    }
    if (query.corpusFilters.isNotEmpty) {
      final hits = <RetrievalHit>[];
      for (final corpusId in query.corpusFilters) {
        hits.addAll(searchPort.searchByCorpus(query, corpusId));
      }
      return Future.value(hits);
    }
    return Future.value(searchPort.search(query));
  }

  Future<List<RetrievalHit>> _lexicalSearch(
    ProjectDescriptor project,
    RetrievalQuery query,
    List<RetrievalMountBinding> bindings,
  ) {
    final allowedCorpusIds = bindings.isNotEmpty
        ? bindings.map((entry) => entry.corpusId).toSet()
        : query.corpusFilters.toSet();
    return _metadataRepository.listChunks(project).then(
      (items) => _scoreChunks(
        query,
        allowedCorpusIds.isEmpty
            ? items
            : items
                .where((chunk) => allowedCorpusIds.contains(chunk.corpusId))
                .toList(growable: false),
      ),
    );
  }

  List<RetrievalHit> _scoreChunks(
    RetrievalQuery query,
    List<RagChunk> chunks,
  ) {
    final queryTokens = _queryTokens(query.queryText);
    final hits = <RetrievalHit>[];
    for (final chunk in chunks) {
      final score = _scoreChunk(chunk.text, query.queryText, queryTokens);
      if (score <= 0) {
        continue;
      }
      hits.add(
        RetrievalHit(
          hitId: '${chunk.chunkId}_hit',
          corpusId: chunk.corpusId,
          sourceDocumentId: chunk.sourceDocumentId,
          score: score,
          rerankScore: score,
          excerpt: _excerpt(chunk.text, query.queryText),
          rangeStart: chunk.rangeStart,
          rangeEnd: chunk.rangeEnd,
          chapterTitle: chunk.chapterTitle,
          evidencePath:
              '${chunk.sourceDocumentId}#L${chunk.rangeStart}-L${chunk.rangeEnd}',
          metadata: <String, Object?>{
            'chunk_id': chunk.chunkId,
            'segment_index': chunk.segmentIndex,
            'chapter_index': chunk.chapterIndex,
            ...chunk.metadata,
          },
        ),
      );
    }
    hits.sort((left, right) => right.score.compareTo(left.score));
    return hits;
  }

  List<String> _queryTokens(String queryText) {
    final trimmed = queryText.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }
    final split = trimmed
        .split(RegExp(r'\s+'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (split.isNotEmpty) {
      return split;
    }
    if (trimmed.length < 3) {
      return <String>[trimmed];
    }
    final result = <String>{trimmed};
    for (var index = 0; index < trimmed.length - 1; index += 1) {
      result.add(trimmed.substring(index, index + 2));
    }
    return result.toList(growable: false);
  }

  double _scoreChunk(
    String chunkText,
    String queryText,
    List<String> queryTokens,
  ) {
    final normalizedChunk = chunkText.toLowerCase();
    var score = 0.0;
    if (normalizedChunk.contains(queryText.toLowerCase())) {
      score += 3.0;
    }
    for (final token in queryTokens) {
      if (token.isEmpty) {
        continue;
      }
      final occurrences = RegExp(RegExp.escape(token), caseSensitive: false)
          .allMatches(chunkText)
          .length;
      if (occurrences > 0) {
        score += 1.0 + occurrences * 0.5;
      }
    }
    return score;
  }

  String _excerpt(String chunkText, String queryText) {
    final normalized = chunkText.trim();
    if (normalized.isEmpty) {
      return '';
    }
    final index = normalized.toLowerCase().indexOf(queryText.toLowerCase());
    if (index < 0) {
      return normalized.length <= 160 ? normalized : normalized.substring(0, 160);
    }
    final start = index > 40 ? index - 40 : 0;
    final end = (index + queryText.length + 80) < normalized.length
        ? index + queryText.length + 80
        : normalized.length;
    return normalized.substring(start, end);
  }
}
