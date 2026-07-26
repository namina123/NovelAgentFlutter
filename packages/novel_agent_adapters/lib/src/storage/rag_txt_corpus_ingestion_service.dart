import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'reference_source_document_file_reader_service.dart';
import 'rag_source_analysis_summary_builder.dart';
import 'sqlite_rag_metadata_repository.dart';

class RagTxtCorpusIngestionProgress {
  const RagTxtCorpusIngestionProgress({
    required this.phaseId,
    required this.message,
    this.completedChunks = 0,
    this.totalChunks = 0,
  });

  final String phaseId;
  final String message;
  final int completedChunks;
  final int totalChunks;
}

typedef RagTxtCorpusIngestionProgressCallback =
    FutureOr<void> Function(RagTxtCorpusIngestionProgress progress);

/// ingestion 给 chunk 批量 embedding 的结果：带向量的 chunk + 向量维度 + 后端类型。
class RagTxtEmbeddingResult {
  const RagTxtEmbeddingResult({
    required this.chunks,
    required this.dimension,
    required this.backendKind,
    this.degradedReason = '',
  });

  final List<RagChunk> chunks;
  final int dimension;
  final String backendKind;

  /// 为空表示成功生成了向量；否则给出降级原因，供调用方诚实提示，避免
  /// "embedding 失败/未配置却照常报成功"（与检索侧 lexical_fallback 标注同源）。
  /// 取值：`no_provider`（未配置 provider，预期降级）/ `embedding_empty`（provider 返回空或数量不匹配）/
  /// `embedding_failed`（provider 抛错——bad key / 404 / 网络等，属静默失败，必须提示）。
  final String degradedReason;
}

class RagTxtCorpusIngestionService {
  RagTxtCorpusIngestionService({
    SqliteRagMetadataRepository? metadataRepository,
    ReferenceSourceDocumentFileReaderService? fileReaderService,
    ReferenceSourceDocumentStructureService? structureService,
    BundleChecksumService? checksumService,
    RagSourceAnalysisSummaryBuilder? sourceAnalysisSummaryBuilder,
    EmbeddingProviderPort? embeddingProvider,
    this.embeddingProviderResolver,
  }) : _metadataRepository =
           metadataRepository ?? SqliteRagMetadataRepository(),
       _fileReaderService =
           fileReaderService ??
           const ReferenceSourceDocumentFileReaderService(),
       _structureService =
           structureService ?? const ReferenceSourceDocumentStructureService(),
       _checksumService = checksumService ?? const BundleChecksumService(),
       _sourceAnalysisSummaryBuilder =
           sourceAnalysisSummaryBuilder ??
           const RagSourceAnalysisSummaryBuilder(),
       _embeddingProvider = embeddingProvider;

  final SqliteRagMetadataRepository _metadataRepository;
  final ReferenceSourceDocumentFileReaderService _fileReaderService;
  final ReferenceSourceDocumentStructureService _structureService;
  final BundleChecksumService _checksumService;
  final RagSourceAnalysisSummaryBuilder _sourceAnalysisSummaryBuilder;
  final EmbeddingProviderPort? _embeddingProvider;

  /// 中文注释: 设置可能运行时变化，embedding provider 不能在装配期写死。这里注入惰性解析闭包：
  /// 入库时按当前设置解析 provider，解析失败或缺配置返回 null（_embedChunks 如实回退到纯元数据）。
  final Future<EmbeddingProviderPort?> Function()? embeddingProviderResolver;

  Future<RagCorpusPackage> ingestFile({
    required ProjectDescriptor project,
    required String sourceFilePath,
    required RagCorpusPackage corpusPackage,
    String? ingestedAt,
    int maxChunkChars = 2400,
    int minChunkChars = 600,
    RagTxtCorpusIngestionProgressCallback? onProgress,
  }) async {
    // 中文注释: 这里把第一阶段 txt 语料构建收口成一个薄编排入口，只做读取、分段、chunk 化和元数据落库。
    final normalizedPath = sourceFilePath.trim();
    if (!_isTxtPath(normalizedPath)) {
      throw StateError('语料提取仅支持 .txt 文件：$sourceFilePath');
    }
    await _emitProgress(
      onProgress,
      const RagTxtCorpusIngestionProgress(
        phaseId: 'reading_source',
        message: '正在读取 txt 源文...',
      ),
    );
    final sourceDocumentFile = await _fileReaderService.read(
      sourceFilePath: normalizedPath,
    );
    final normalizedText = _normalizeText(sourceDocumentFile.sourceText);
    if (normalizedText.isEmpty) {
      throw StateError('语料提取源文本为空：$sourceFilePath');
    }

    final timestamp = _resolveTimestamp(ingestedAt);
    final normalizedCorpus = _normalizeCorpusPackage(
      corpusPackage,
      sourceText: normalizedText,
      timestamp: timestamp,
    );
    await _emitProgress(
      onProgress,
      const RagTxtCorpusIngestionProgress(
        phaseId: 'analyzing_structure',
        message: '正在分析章节结构...',
      ),
    );
    final structure = _structureService.analyze(normalizedText);
    await _yieldToUi();
    await _emitProgress(
      onProgress,
      RagTxtCorpusIngestionProgress(
        phaseId: 'splitting_sections',
        message: '正在切分章节片段...',
      ),
    );
    final sections = await _splitSections(
      structure.sections,
      maxChunkChars: maxChunkChars,
      minChunkChars: minChunkChars,
    );
    if (sections.isEmpty) {
      throw StateError('语料提取未生成任何分段：$sourceFilePath');
    }

    final sourceLanguage = _inferLanguage(
      preferredLanguage: normalizedCorpus.language,
      sourceText: normalizedText,
    );
    final sourceAnalysisSummary = _sourceAnalysisSummaryBuilder.build(
      normalizedText: normalizedText,
      sections: structure.sections,
      targetLanguage: sourceLanguage,
    );
    final contentHash = _checksumService.checksumOf(<String, Object?>{
      'source_file_path': sourceDocumentFile.sourceFilePath,
      'source_title': sourceDocumentFile.sourceTitle,
      'source_text': normalizedText,
    });
    final sourceDocumentId = _buildSourceDocumentId(
      corpusId: normalizedCorpus.corpusId,
      sourceTitle: sourceDocumentFile.sourceTitle,
      contentHash: contentHash,
    );
    final sourceDocument = RagSourceDocument(
      sourceDocumentId: sourceDocumentId,
      corpusId: normalizedCorpus.corpusId,
      sourceKind: 'txt',
      displayName: sourceDocumentFile.sourceTitle,
      originPath: sourceDocumentFile.sourceFilePath,
      originFormat: 'txt',
      language: sourceLanguage,
      contentHash: contentHash,
      metadata: <String, Object?>{
        'source_text_length': normalizedText.length,
        'structure_kind': structure.structureKind,
        'source_analysis_summary': sourceAnalysisSummary,
      },
    );
    await _emitProgress(
      onProgress,
      RagTxtCorpusIngestionProgress(
        phaseId: 'building_chunks',
        message: '正在构建语料分片...',
      ),
    );
    final chunks = await _buildChunks(
      sourceDocument: sourceDocument,
      sections: sections,
      onProgress: onProgress,
    );
    var updatedCorpus = normalizedCorpus.copyWith(
      sourceKind: 'txt',
      language: sourceLanguage,
      buildMode: normalizedCorpus.buildMode.trim().isEmpty
          ? 'basic'
          : normalizedCorpus.buildMode.trim(),
      segmentationStrategy: normalizedCorpus.segmentationStrategy.trim().isEmpty
          ? _defaultSegmentationStrategyId(structure.structureKind)
          : normalizedCorpus.segmentationStrategy.trim(),
      chunkStrategy: normalizedCorpus.chunkStrategy.trim().isEmpty
          ? 'section_split'
          : normalizedCorpus.chunkStrategy.trim(),
      embeddingBackend: normalizedCorpus.embeddingBackend.trim().isEmpty
          ? 'none'
          : normalizedCorpus.embeddingBackend.trim(),
      indexBackend: normalizedCorpus.indexBackend.trim().isEmpty
          ? 'sqlite-meta'
          : normalizedCorpus.indexBackend.trim(),
      createdAt: normalizedCorpus.createdAt.trim().isEmpty
          ? timestamp
          : normalizedCorpus.createdAt,
      updatedAt: timestamp,
      sourceCount: 1,
      chapterCount: structure.sections.length,
      chunkCount: chunks.length,
      isModelAssisted: false,
      capabilityFlags: _mergeCapabilityFlags(normalizedCorpus.capabilityFlags),
      metadata: <String, Object?>{
        ...normalizedCorpus.metadata,
        'source_document_id': sourceDocumentId,
        'source_file_path': sourceDocument.originPath,
        'content_hash': contentHash,
        'structure_kind': structure.structureKind,
        'section_count': structure.sections.length,
        'chunk_count': chunks.length,
        'ingestion_mode': 'txt_basic',
        'source_analysis_summary': sourceAnalysisSummary,
      },
    );
    final embedded = await _embedChunks(chunks);
    // 中文注释: 把 embedding 实际结果（backend/dimension/降级原因）写回 corpus 元数据，
    // 让上层能据实提示用户向量是否真的生成，避免"provider 抛错却照常报成功"。
    updatedCorpus = updatedCorpus.copyWith(
      metadata: <String, Object?>{
        ...updatedCorpus.metadata,
        'embedding_backend': embedded.backendKind,
        'embedding_dimension': embedded.dimension,
        if (embedded.degradedReason.isNotEmpty)
          'embedding_degraded_reason': embedded.degradedReason,
      },
    );
    final indexHandle = _buildIndexHandle(
      corpusPackage: updatedCorpus,
      timestamp: timestamp,
      embeddingDimension: embedded.dimension,
      backendKind: embedded.backendKind,
    );
    final ingestionRun = _buildIngestionRun(
      project: project,
      corpusPackage: updatedCorpus,
      sourceDocument: sourceDocument,
      sectionCount: structure.sections.length,
      chunkCount: chunks.length,
      timestamp: timestamp,
      sourceAnalysisSummary: sourceAnalysisSummary,
    );

    await _emitProgress(
      onProgress,
      RagTxtCorpusIngestionProgress(
        phaseId: 'persisting',
        message: '正在写入语料元数据...',
        completedChunks: 0,
        totalChunks: chunks.length,
      ),
    );
    await _metadataRepository.persistIngestionBundle(
      project: project,
      corpusPackage: updatedCorpus,
      sourceDocument: sourceDocument,
      chunks: embedded.chunks,
      indexHandle: indexHandle,
      ingestionRun: ingestionRun,
      onChunkBatchCommitted: (completed, total) async {
        await _emitProgress(
          onProgress,
          RagTxtCorpusIngestionProgress(
            phaseId: 'persisting',
            message: '正在写入语料元数据... $completed / $total 分片',
            completedChunks: completed,
            totalChunks: total,
          ),
        );
      },
    );
    await _emitProgress(
      onProgress,
      RagTxtCorpusIngestionProgress(
        phaseId: 'completed',
        message: '语料构建完成：${updatedCorpus.chunkCount} 个分片。',
        completedChunks: updatedCorpus.chunkCount,
        totalChunks: updatedCorpus.chunkCount,
      ),
    );
    return updatedCorpus;
  }

  Future<RagCorpusPackage> ingestNormalizedText({
    required ProjectDescriptor project,
    required String sourceDisplayName,
    required String sourceIdentityPath,
    required String normalizedText,
    required RagCorpusPackage corpusPackage,
    String? ingestedAt,
    int maxChunkChars = 2400,
    int minChunkChars = 600,
    RagTxtCorpusIngestionProgressCallback? onProgress,
  }) async {
    final normalizedPath = sourceIdentityPath.trim();
    final cleanText = _normalizeText(normalizedText);
    if (cleanText.isEmpty) {
      throw StateError('语料提取源文本为空：$sourceIdentityPath');
    }
    final timestamp = _resolveTimestamp(ingestedAt);
    final normalizedCorpus = _normalizeCorpusPackage(
      corpusPackage,
      sourceText: cleanText,
      timestamp: timestamp,
    );
    await _emitProgress(
      onProgress,
      const RagTxtCorpusIngestionProgress(
        phaseId: 'analyzing_structure',
        message: '正在分析整理后的纯文本结构...',
      ),
    );
    final structure = _structureService.analyze(cleanText);
    await _yieldToUi();
    await _emitProgress(
      onProgress,
      const RagTxtCorpusIngestionProgress(
        phaseId: 'splitting_sections',
        message: '正在切分整理后的章节片段...',
      ),
    );
    final sections = await _splitSections(
      structure.sections,
      maxChunkChars: maxChunkChars,
      minChunkChars: minChunkChars,
    );
    if (sections.isEmpty) {
      throw StateError('语料提取未生成任何分段：$sourceIdentityPath');
    }
    final sourceLanguage = _inferLanguage(
      preferredLanguage: normalizedCorpus.language,
      sourceText: cleanText,
    );
    final sourceAnalysisSummary = _sourceAnalysisSummaryBuilder.build(
      normalizedText: cleanText,
      sections: structure.sections,
      targetLanguage: sourceLanguage,
    );
    final contentHash = _checksumService.checksumOf(<String, Object?>{
      'source_file_path': normalizedPath,
      'source_title': sourceDisplayName,
      'source_text': cleanText,
    });
    final sourceDocumentId = _buildSourceDocumentId(
      corpusId: normalizedCorpus.corpusId,
      sourceTitle: sourceDisplayName,
      contentHash: contentHash,
    );
    final sourceDocument = RagSourceDocument(
      sourceDocumentId: sourceDocumentId,
      corpusId: normalizedCorpus.corpusId,
      sourceKind: 'txt',
      displayName: sourceDisplayName,
      originPath: normalizedPath,
      originFormat: 'txt',
      language: sourceLanguage,
      contentHash: contentHash,
      metadata: <String, Object?>{
        'source_text_length': cleanText.length,
        'structure_kind': structure.structureKind,
        'source_analysis_summary': sourceAnalysisSummary,
        'normalization_stage': 'book_deconstruction_preprocessed',
      },
    );
    await _emitProgress(
      onProgress,
      const RagTxtCorpusIngestionProgress(
        phaseId: 'building_chunks',
        message: '正在构建语料分片...',
      ),
    );
    final chunks = await _buildChunks(
      sourceDocument: sourceDocument,
      sections: sections,
      onProgress: onProgress,
    );
    var updatedCorpus = normalizedCorpus.copyWith(
      sourceKind: 'txt',
      language: sourceLanguage,
      buildMode: normalizedCorpus.buildMode.trim().isEmpty
          ? 'basic'
          : normalizedCorpus.buildMode.trim(),
      segmentationStrategy: normalizedCorpus.segmentationStrategy.trim().isEmpty
          ? _defaultSegmentationStrategyId(structure.structureKind)
          : normalizedCorpus.segmentationStrategy.trim(),
      chunkStrategy: normalizedCorpus.chunkStrategy.trim().isEmpty
          ? 'section_split'
          : normalizedCorpus.chunkStrategy.trim(),
      embeddingBackend: normalizedCorpus.embeddingBackend.trim().isEmpty
          ? 'none'
          : normalizedCorpus.embeddingBackend.trim(),
      indexBackend: normalizedCorpus.indexBackend.trim().isEmpty
          ? 'sqlite-meta'
          : normalizedCorpus.indexBackend.trim(),
      createdAt: normalizedCorpus.createdAt.trim().isEmpty
          ? timestamp
          : normalizedCorpus.createdAt,
      updatedAt: timestamp,
      sourceCount: 1,
      chapterCount: structure.sections.length,
      chunkCount: chunks.length,
      isModelAssisted: false,
      capabilityFlags: _mergeCapabilityFlags(normalizedCorpus.capabilityFlags),
      metadata: <String, Object?>{
        ...normalizedCorpus.metadata,
        'source_document_id': sourceDocumentId,
        'source_file_path': sourceDocument.originPath,
        'content_hash': contentHash,
        'structure_kind': structure.structureKind,
        'section_count': structure.sections.length,
        'chunk_count': chunks.length,
        'ingestion_mode': 'preprocessed_text',
        'source_analysis_summary': sourceAnalysisSummary,
        'normalization_stage': 'book_deconstruction_preprocessed',
      },
    );
    final embedded = await _embedChunks(chunks);
    // 中文注释: 把 embedding 实际结果（backend/dimension/降级原因）写回 corpus 元数据，
    // 让上层能据实提示用户向量是否真的生成，避免"provider 抛错却照常报成功"。
    updatedCorpus = updatedCorpus.copyWith(
      metadata: <String, Object?>{
        ...updatedCorpus.metadata,
        'embedding_backend': embedded.backendKind,
        'embedding_dimension': embedded.dimension,
        if (embedded.degradedReason.isNotEmpty)
          'embedding_degraded_reason': embedded.degradedReason,
      },
    );
    final indexHandle = _buildIndexHandle(
      corpusPackage: updatedCorpus,
      timestamp: timestamp,
      embeddingDimension: embedded.dimension,
      backendKind: embedded.backendKind,
    );
    final ingestionRun = _buildIngestionRun(
      project: project,
      corpusPackage: updatedCorpus,
      sourceDocument: sourceDocument,
      sectionCount: structure.sections.length,
      chunkCount: chunks.length,
      timestamp: timestamp,
      sourceAnalysisSummary: sourceAnalysisSummary,
    );
    await _emitProgress(
      onProgress,
      RagTxtCorpusIngestionProgress(
        phaseId: 'persisting',
        message: '正在写入语料元数据...',
        completedChunks: 0,
        totalChunks: chunks.length,
      ),
    );
    await _metadataRepository.persistIngestionBundle(
      project: project,
      corpusPackage: updatedCorpus,
      sourceDocument: sourceDocument,
      chunks: embedded.chunks,
      indexHandle: indexHandle,
      ingestionRun: ingestionRun,
      onChunkBatchCommitted: (completed, total) async {
        await _emitProgress(
          onProgress,
          RagTxtCorpusIngestionProgress(
            phaseId: 'persisting',
            message: '正在写入语料元数据... $completed / $total 分片',
            completedChunks: completed,
            totalChunks: total,
          ),
        );
      },
    );
    await _emitProgress(
      onProgress,
      RagTxtCorpusIngestionProgress(
        phaseId: 'completed',
        message: '语料构建完成：${updatedCorpus.chunkCount} 个分片。',
        completedChunks: updatedCorpus.chunkCount,
        totalChunks: updatedCorpus.chunkCount,
      ),
    );
    return updatedCorpus;
  }

  bool _isTxtPath(String sourceFilePath) {
    // 中文注释: 第一阶段只开放纯 txt 输入，避免 md / epub 先行混入这条基础流水线。
    return sourceFilePath.toLowerCase().endsWith('.txt');
  }

  String _resolveTimestamp(String? timestamp) {
    // 中文注释: 运行时时间戳作为审计字段统一在这里收口，方便测试和回放时注入固定值。
    final trimmed = timestamp?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed : DateTime.now().toIso8601String();
  }

  RagCorpusPackage _normalizeCorpusPackage(
    RagCorpusPackage corpusPackage, {
    required String sourceText,
    required String timestamp,
  }) {
    // 中文注释: 这里只补第一阶段 txt ingest 所需的默认字段，不把后续 backend 形状写死。
    final baseSourceKind = corpusPackage.sourceKind.trim().isEmpty
        ? 'txt'
        : corpusPackage.sourceKind.trim().toLowerCase();
    if (baseSourceKind != 'txt') {
      throw StateError('语料提取仅接受 txt 语料包：${corpusPackage.sourceKind}');
    }
    final normalizedLanguage = _inferLanguage(
      preferredLanguage: corpusPackage.language,
      sourceText: sourceText,
    );
    final normalizedTitle = corpusPackage.title.trim().isEmpty
        ? 'txt 语料包'
        : corpusPackage.title.trim();
    final normalizedBuildMode = corpusPackage.buildMode.trim().isEmpty
        ? 'basic'
        : corpusPackage.buildMode.trim();
    final normalizedCorpus = corpusPackage.copyWith(
      sourceKind: 'txt',
      title: normalizedTitle,
      language: normalizedLanguage,
      buildMode: normalizedBuildMode,
      createdAt: corpusPackage.createdAt.trim().isEmpty
          ? timestamp
          : corpusPackage.createdAt,
      updatedAt: timestamp,
    );
    final validationIssues = normalizedCorpus.validateBasics();
    if (validationIssues.isNotEmpty) {
      throw StateError('无效的语料包：${validationIssues.join(', ')}');
    }
    return normalizedCorpus;
  }

  Future<List<ReferenceSourceDocumentSection>> _splitSections(
    List<ReferenceSourceDocumentSection> sections, {
    required int maxChunkChars,
    required int minChunkChars,
  }) async {
    // 中文注释: 先用已有结构服务做章节/段落识别，再按统一阈值拆成可落库 chunk 单元。
    final resolved = <ReferenceSourceDocumentSection>[];
    for (final section in sections) {
      if (section.charCount <= maxChunkChars) {
        resolved.add(section);
      } else {
        resolved.addAll(
          _structureService.splitOversizedSection(
            section: section,
            maxChars: maxChunkChars,
            minChars: minChunkChars,
          ),
        );
      }
      if (resolved.length % 12 == 0) {
        await _yieldToUi();
      }
    }
    return resolved;
  }

  Future<List<RagChunk>> _buildChunks({
    required RagSourceDocument sourceDocument,
    required List<ReferenceSourceDocumentSection> sections,
    RagTxtCorpusIngestionProgressCallback? onProgress,
  }) async {
    // 中文注释: chunk 构建只负责把结构化 section 转成可检索文本单元，不引入任何 embedding 逻辑。
    final chunks = <RagChunk>[];
    for (var index = 0; index < sections.length; index += 1) {
      final section = sections[index];
      final chunkIndex = index + 1;
      final text = section.content.trim();
      if (text.isEmpty) {
        continue;
      }
      chunks.add(
        RagChunk(
          chunkId: _buildChunkId(
            sourceDocumentId: sourceDocument.sourceDocumentId,
            chunkIndex: chunkIndex,
            sectionId: section.sectionId,
          ),
          corpusId: sourceDocument.corpusId,
          sourceDocumentId: sourceDocument.sourceDocumentId,
          chapterIndex: section.sectionIndex,
          chapterTitle: section.heading.trim().isEmpty
              ? sourceDocument.displayName
              : section.heading.trim(),
          segmentIndex: chunkIndex,
          text: text,
          normalizedText: text,
          tokenEstimate: _estimateTokenCount(text),
          rangeStart: section.startOffset,
          rangeEnd: section.endOffset,
          metadata: <String, Object?>{
            'section_id': section.sectionId,
            'section_index': section.sectionIndex,
            'structure_kind': section.structureKind,
            'synthetic': section.synthetic,
            'parent_section_id': section.parentSectionId,
          },
        ),
      );
      if ((index + 1) % 16 == 0 || index == sections.length - 1) {
        await _emitProgress(
          onProgress,
          RagTxtCorpusIngestionProgress(
            phaseId: 'building_chunks',
            message: '正在构建语料分片... ${index + 1} / ${sections.length}',
            completedChunks: index + 1,
            totalChunks: sections.length,
          ),
        );
        await _yieldToUi();
      }
    }
    return chunks;
  }

  RagIndexHandle _buildIndexHandle({
    required RagCorpusPackage corpusPackage,
    required String timestamp,
    int embeddingDimension = 0,
    String backendKind = 'sqlite-meta',
  }) {
    // 中文注释: 索引句柄如实登记后端类型与向量维度：接了 embedding provider 就写真实维度，
    // 没接就保持 metadata-only，不再把任何状态假装成向量已落地。
    final vectorBacked = embeddingDimension > 0;
    return RagIndexHandle(
      indexHandleId: '${corpusPackage.corpusId}_index',
      corpusId: corpusPackage.corpusId,
      backendKind: backendKind,
      backendLocation: '.novel_agent/sqlite/novel_agent.db',
      embeddingDimension: embeddingDimension,
      status: 'ready',
      version: corpusPackage.version.trim().isEmpty
          ? 'v1'
          : corpusPackage.version,
      lastBuiltAt: timestamp,
      metadata: <String, Object?>{
        'backend_policy': vectorBacked ? 'sqlite_vector' : 'metadata_only',
        'source_kind': corpusPackage.sourceKind,
        'build_mode': corpusPackage.buildMode,
      },
    );
  }

  /// 用注入的 embedding provider 批量给 chunk 生成向量，写到 chunk.metadata 里，
  /// 随 chunk 一起在同一事务落库；没有 provider 或失败时如实回退到纯元数据。
  Future<RagTxtEmbeddingResult> _embedChunks(List<RagChunk> chunks) async {
    final provider =
        _embeddingProvider ?? (await embeddingProviderResolver?.call());
    if (provider == null || chunks.isEmpty) {
      return RagTxtEmbeddingResult(
        chunks: chunks,
        dimension: 0,
        backendKind: 'sqlite-meta',
        degradedReason: provider == null ? 'no_provider' : '',
      );
    }
    try {
      final texts = chunks.map((chunk) => chunk.text).toList(growable: false);
      final vectors = await provider.embedTexts(texts);
      if (vectors.length != chunks.length ||
          vectors.isEmpty ||
          vectors.first.isEmpty) {
        return RagTxtEmbeddingResult(
          chunks: chunks,
          dimension: 0,
          backendKind: 'sqlite-meta',
          degradedReason: 'embedding_empty',
        );
      }
      final dimension = vectors.first.length;
      final embedded = <RagChunk>[];
      for (var i = 0; i < chunks.length; i++) {
        embedded.add(
          chunks[i].copyWith(
            metadata: <String, Object?>{
              ...chunks[i].metadata,
              'embedding': vectors[i],
              'embedding_model': provider.providerId,
            },
          ),
        );
      }
      return RagTxtEmbeddingResult(
        chunks: embedded,
        dimension: dimension,
        backendKind: provider.providerKind,
      );
    } catch (_) {
      // 中文注释: embedding 失败不阻断 ingestion；检索端口仍可走，只是没有向量可用。
      // 但必须如实记录降级原因（embedding_failed），让调用方能给用户诚实提示，而非静默成功。
      return RagTxtEmbeddingResult(
        chunks: chunks,
        dimension: 0,
        backendKind: 'sqlite-meta',
        degradedReason: 'embedding_failed',
      );
    }
  }

  JsonMap _buildIngestionRun({
    required ProjectDescriptor project,
    required RagCorpusPackage corpusPackage,
    required RagSourceDocument sourceDocument,
    required int sectionCount,
    required int chunkCount,
    required String timestamp,
    required JsonMap sourceAnalysisSummary,
  }) {
    // 中文注释: ingestion run 记录只保存运行摘要与稳定 id，方便后续诊断和回放，不承载业务规则。
    return <String, Object?>{
      'ingestion_run_id':
          '${corpusPackage.corpusId}_${sourceDocument.sourceDocumentId}_run',
      'project_id': project.id,
      'corpus_id': corpusPackage.corpusId,
      'source_document_id': sourceDocument.sourceDocumentId,
      'source_file_path': sourceDocument.originPath,
      'source_language': sourceDocument.language,
      'status': 'completed',
      'started_at': timestamp,
      'updated_at': timestamp,
      'section_count': sectionCount,
      'chunk_count': chunkCount,
      'content_hash': sourceDocument.contentHash,
      'payload_json': <String, Object?>{
        'ingestion_mode': 'txt_basic',
        'source_kind': sourceDocument.sourceKind,
        'build_mode': corpusPackage.buildMode,
        'segmentation_strategy': corpusPackage.segmentationStrategy,
        'chunk_strategy': corpusPackage.chunkStrategy,
        'source_analysis_summary': sourceAnalysisSummary,
      },
    };
  }

  List<String> _mergeCapabilityFlags(List<String> capabilityFlags) {
    // 中文注释: 能力标记只保留少量可读值，避免 corpus metadata 变成不受控的状态垃圾场。
    final result = <String>{
      'txt',
      'rule_based',
      'metadata_only',
      ...capabilityFlags
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty),
    };
    return result.toList(growable: false);
  }

  String _buildSourceDocumentId({
    required String corpusId,
    required String sourceTitle,
    required String contentHash,
  }) {
    // 中文注释: 源文稿 id 由 corpus 和内容指纹共同决定，确保同一文件重复导入时具备稳定定位能力。
    final titleId = _safeId(sourceTitle, fallback: 'source_document');
    final hashSuffix = contentHash.length >= 12
        ? contentHash.substring(0, 12)
        : contentHash;
    return '${_safeId(corpusId, fallback: 'corpus')}_${titleId}_$hashSuffix';
  }

  String _buildChunkId({
    required String sourceDocumentId,
    required int chunkIndex,
    required String sectionId,
  }) {
    // 中文注释: chunk id 只依赖稳定来源与局部顺序，方便后续重建和对照，不把运行时随机数带进主键。
    return '${_safeId(sourceDocumentId, fallback: 'source')}_${_safeId(sectionId, fallback: 'section')}_${chunkIndex.toString().padLeft(3, '0')}';
  }

  String _defaultSegmentationStrategyId(String structureKind) {
    // 中文注释: 第一阶段的分段策略先保留为可读描述，后续有更细策略时再替换成正式策略 id。
    return structureKind ==
            ReferenceSourceDocumentStructureKinds.explicitChapter
        ? 'rule_chapter'
        : 'rule_paragraph';
  }

  String _inferLanguage({
    required String preferredLanguage,
    required String sourceText,
  }) {
    // 中文注释: 语言只在缺省时做轻量推断，不把语言识别做成额外分析中心。
    final trimmedPreferred = preferredLanguage.trim();
    if (trimmedPreferred.isNotEmpty) {
      return trimmedPreferred;
    }
    final cjkMatches = RegExp(r'[\u4E00-\u9FFF]').allMatches(sourceText).length;
    final latinMatches = RegExp(r'[A-Za-z]').allMatches(sourceText).length;
    return cjkMatches > latinMatches ~/ 2 ? 'zh-CN' : 'en';
  }

  String _normalizeText(String sourceText) {
    // 中文注释: 这里先做最小的换行归一化和裁剪，避免结构服务被平台换行差异污染。
    return sourceText.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }

  int _estimateTokenCount(String text) {
    // 中文注释: 这里用轻量字符近似值代表 token 估计，满足元数据记录需求即可，不模拟真实 tokenizer。
    if (text.trim().isEmpty) {
      return 0;
    }
    return (text.length / 2).ceil();
  }

  String _safeId(String value, {required String fallback}) {
    // 中文注释: 稳定 id 只允许字母数字与少量分隔符，避免主键里混入路径或空白噪音。
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? fallback : normalized.toLowerCase();
  }

  Future<void> _emitProgress(
    RagTxtCorpusIngestionProgressCallback? onProgress,
    RagTxtCorpusIngestionProgress progress,
  ) async {
    if (onProgress == null) {
      await _yieldToUi();
      return;
    }
    await onProgress(progress);
    await _yieldToUi();
  }

  Future<void> _yieldToUi() {
    return Future<void>.delayed(Duration.zero);
  }
}
