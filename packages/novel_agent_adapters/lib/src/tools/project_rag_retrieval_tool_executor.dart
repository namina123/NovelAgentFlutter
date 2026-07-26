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
    this.searchPortResolver,
  }) : _metadataRepository =
           metadataRepository ?? SqliteRagMetadataRepository(),
       _mountSummaryService =
           mountSummaryService ??
           RagProjectMountSummaryService(
             metadataRepository:
                 metadataRepository ?? SqliteRagMetadataRepository(),
           ),
       _searchPort = searchPort,
       _activationBridgeService =
           activationBridgeService ??
           const ProjectRagRetrievalActivationBridgeService();

  final SqliteRagMetadataRepository _metadataRepository;
  final RagProjectMountSummaryService _mountSummaryService;
  final RetrievalSearchPort? _searchPort;
  final ProjectRagRetrievalActivationBridgeService _activationBridgeService;

  /// 中文注释: 设置可能运行时变化（用户改 provider/embedding 模型），向量端口不能在装配期写死。
  /// 这里注入一个惰性解析闭包：每次检索时按当前设置解析出向量端口，解析失败或缺配置返回 null
  /// （由 _searchHits 如实降级到 lexical / lexical_fallback，不再造假）。异步以匹配
  /// SettingsRepository.load() 的异步读取。
  final Future<RetrievalSearchPort?> Function()? searchPortResolver;

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
      'rerank_policy': ValueReaders.stringValue(
        arguments['rerank_policy'],
      ).trim(),
      'evidence_budget': ValueReaders.intValue(arguments['evidence_budget']),
      'metadata': <String, Object?>{
        ...ValueReaders.mapValue(arguments['metadata']),
        // 中文注释: 把项目根路径随查询带下去，向量检索端口据此打开对应项目的 SQLite 库。
        'project_root_path': project.rootPath,
      },
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
    final searchOutcome = await _searchHits(project, query, usableBindings);
    final hits = searchOutcome.hits;
    // 中文注释: retrieval_mode 如实反映本次召回走的代码路径——vector=向量语义检索，
    // lexical=未注入向量端口时的关键词回退，lexical_fallback=注入了端口但嵌入不可用而降级。
    // 不再把关键词回退的结果冒充成语义检索，避免误导下游与用户。
    final retrievalMode = searchOutcome.mode;
    final isLexical = retrievalMode != 'vector';
    final selectedHits = hits.take(query.topK).toList(growable: false);
    final hitCountLabel = isLexical
        ? '已召回语料证据片段（关键词匹配）：${selectedHits.length} 条'
        : '已召回语料证据片段：${selectedHits.length} 条';
    final retrievalActivationPackage = _activationBridgeService
        .buildPackage(project, <String, Object?>{
          'ok': true,
          'display_text': hitCountLabel,
          'retrieval_query': query.toJson(),
          'mount_summary': mountSummary.toJson(),
          'retrieval_hits': selectedHits
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'citation_paths': selectedHits
              .map((entry) => entry.evidencePath)
              .where((entry) => entry.trim().isNotEmpty)
              .toList(growable: false),
          'source_summaries': selectedHits
              .map((entry) => '${entry.corpusId}:${entry.sourceDocumentId}')
              .toList(growable: false),
          'warning_notes': _warningNotesFor(
            mountSummary: mountSummary,
            selectedHits: selectedHits,
            retrievalMode: retrievalMode,
          ),
        });
    return <String, Object?>{
      'ok': true,
      'display_text': hitCountLabel,
      'retrieval_mode': retrievalMode,
      'changed_paths': const <String>[],
      'retrieval_query': query.toJson(),
      'mount_summary': mountSummary.toJson(),
      'retrieval_hits': selectedHits
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'citation_paths': selectedHits
          .map((entry) => entry.evidencePath)
          .where((entry) => entry.trim().isNotEmpty)
          .toList(growable: false),
      'source_summaries': selectedHits
          .map((entry) => '${entry.corpusId}:${entry.sourceDocumentId}')
          .toList(growable: false),
      'warning_notes': _warningNotesFor(
        mountSummary: mountSummary,
        selectedHits: selectedHits,
        retrievalMode: retrievalMode,
      ),
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

  Future<_SearchOutcome> _searchHits(
    ProjectDescriptor project,
    RetrievalQuery query,
    List<RetrievalMountBinding> bindings,
  ) async {
    RetrievalSearchPort? searchPort;
    try {
      // 中文注释: 优先用装配期注入的静态端口，否则惰性解析（读当前设置）。
      searchPort = _searchPort ?? (await searchPortResolver?.call());
    } catch (error) {
      // 中文注释: 解析闭包自身抛错（如读取设置失败）也如实降级，不让检索工具整体报错。
      return _SearchOutcome(
        hits: await _lexicalSearch(project, query, bindings),
        mode: 'lexical_fallback',
        fallbackReason: error.toString(),
      );
    }
    if (searchPort == null) {
      return _SearchOutcome(
        hits: await _lexicalSearch(project, query, bindings),
        mode: 'lexical',
      );
    }
    try {
      if (bindings.isNotEmpty) {
        return _SearchOutcome(
          hits: await searchPort.searchWithinMounts(query, bindings),
          mode: 'vector',
        );
      }
      if (query.corpusFilters.isNotEmpty) {
        final hits = <RetrievalHit>[];
        for (final corpusId in query.corpusFilters) {
          hits.addAll(await searchPort.searchByCorpus(query, corpusId));
        }
        return _SearchOutcome(hits: hits, mode: 'vector');
      }
      return _SearchOutcome(
        hits: await searchPort.search(query),
        mode: 'vector',
      );
    } catch (error) {
      // 中文注释: 向量端口已注入但本次嵌入/检索失败（嵌入模型不可用、网络错误等），
      // 如实降级到关键词匹配并标记 lexical_fallback——既不让整个检索工具报错，
      // 也不把降级结果冒充成语义检索。
      return _SearchOutcome(
        hits: await _lexicalSearch(project, query, bindings),
        mode: 'lexical_fallback',
        fallbackReason: error.toString(),
      );
    }
  }

  Future<List<RetrievalHit>> _lexicalSearch(
    ProjectDescriptor project,
    RetrievalQuery query,
    List<RetrievalMountBinding> bindings,
  ) {
    final allowedCorpusIds = bindings.isNotEmpty
        ? bindings.map((entry) => entry.corpusId).toSet()
        : query.corpusFilters.toSet();
    return _metadataRepository
        .listChunks(project)
        .then(
          (items) => _scoreChunks(
            query,
            allowedCorpusIds.isEmpty
                ? items
                : items
                      .where(
                        (chunk) => allowedCorpusIds.contains(chunk.corpusId),
                      )
                      .toList(growable: false),
          ),
        );
  }

  List<RetrievalHit> _scoreChunks(RetrievalQuery query, List<RagChunk> chunks) {
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
      final occurrences = RegExp(
        RegExp.escape(token),
        caseSensitive: false,
      ).allMatches(chunkText).length;
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
      return normalized.length <= 160
          ? normalized
          : normalized.substring(0, 160);
    }
    final start = index > 40 ? index - 40 : 0;
    final end = (index + queryText.length + 80) < normalized.length
        ? index + queryText.length + 80
        : normalized.length;
    return normalized.substring(start, end);
  }

  List<String> _warningNotesFor({
    required RagProjectMountSummary mountSummary,
    required List<RetrievalHit> selectedHits,
    required String retrievalMode,
  }) {
    // 中文注释: 把与召回模式相关的诚实提示集中在一处，避免词法回退被冒充语义。
    final notes = <String>[
      if (mountSummary.hasBindings == false) '当前项目没有挂载语料，结果可能为空。',
      if (selectedHits.isEmpty) '未召回任何检索命中。',
    ];
    if (retrievalMode == 'lexical') {
      notes.add('当前未注入向量检索端口，结果为关键词匹配（非语义检索）。');
    } else if (retrievalMode == 'lexical_fallback') {
      notes.add('向量检索不可用，已降级为关键词匹配（非语义检索）。');
    } else if (retrievalMode == 'vector' && selectedHits.isEmpty) {
      notes.add('已启用向量检索但未召回命中，可能语料尚未生成嵌入。');
    }
    return notes;
  }
}

/// 一次检索的命中与实际走通的代码路径。
class _SearchOutcome {
  const _SearchOutcome({
    required this.hits,
    required this.mode,
    this.fallbackReason,
  });

  final List<RetrievalHit> hits;
  final String mode;
  final String? fallbackReason;
}
