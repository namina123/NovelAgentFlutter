import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'reference_source_document_file_reader_service.dart';
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

class RagTxtCorpusIngestionService {
  RagTxtCorpusIngestionService({
    SqliteRagMetadataRepository? metadataRepository,
    ReferenceSourceDocumentFileReaderService? fileReaderService,
    ReferenceSourceDocumentStructureService? structureService,
    BundleChecksumService? checksumService,
  }) : _metadataRepository = metadataRepository ?? SqliteRagMetadataRepository(),
       _fileReaderService =
           fileReaderService ?? const ReferenceSourceDocumentFileReaderService(),
       _structureService =
           structureService ?? const ReferenceSourceDocumentStructureService(),
       _checksumService = checksumService ?? const BundleChecksumService();

  final SqliteRagMetadataRepository _metadataRepository;
  final ReferenceSourceDocumentFileReaderService _fileReaderService;
  final ReferenceSourceDocumentStructureService _structureService;
  final BundleChecksumService _checksumService;

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
    final updatedCorpus = normalizedCorpus.copyWith(
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
      },
    );
    final indexHandle = _buildIndexHandle(
      corpusPackage: updatedCorpus,
      timestamp: timestamp,
    );
    final ingestionRun = _buildIngestionRun(
      project: project,
      corpusPackage: updatedCorpus,
      sourceDocument: sourceDocument,
      sectionCount: structure.sections.length,
      chunkCount: chunks.length,
      timestamp: timestamp,
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
      chunks: chunks,
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
      throw StateError(
        '无效的语料包：${validationIssues.join(', ')}',
      );
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
  }) {
    // 中文注释: 索引句柄这里只登记 metadata-only 状态，避免把真实向量后端假装成已经落地。
    return RagIndexHandle(
      indexHandleId: '${corpusPackage.corpusId}_index',
      corpusId: corpusPackage.corpusId,
      backendKind: 'sqlite-meta',
      backendLocation: '.novel_agent/sqlite/novel_agent.db',
      embeddingDimension: 0,
      status: 'ready',
      version: corpusPackage.version.trim().isEmpty ? 'v1' : corpusPackage.version,
      lastBuiltAt: timestamp,
      metadata: <String, Object?>{
        'backend_policy': 'metadata_only',
        'source_kind': corpusPackage.sourceKind,
        'build_mode': corpusPackage.buildMode,
      },
    );
  }

  JsonMap _buildIngestionRun({
    required ProjectDescriptor project,
    required RagCorpusPackage corpusPackage,
    required RagSourceDocument sourceDocument,
    required int sectionCount,
    required int chunkCount,
    required String timestamp,
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
      },
    };
  }

  List<String> _mergeCapabilityFlags(List<String> capabilityFlags) {
    // 中文注释: 能力标记只保留少量可读值，避免 corpus metadata 变成不受控的状态垃圾场。
    final result = <String>{
      'txt',
      'rule_based',
      'metadata_only',
      ...capabilityFlags.map((entry) => entry.trim()).where((entry) => entry.isNotEmpty),
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
    return structureKind == ReferenceSourceDocumentStructureKinds.explicitChapter
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
