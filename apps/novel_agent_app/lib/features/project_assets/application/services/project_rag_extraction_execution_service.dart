import 'dart:async';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/desktop_text_file_picker_service.dart';
import '../../../../shared/services/user_facing_error_humanizer.dart';
import '../models/project_rag_preprocess_result.dart';
import '../models/project_rag_extraction_execution_result.dart';
import '../models/project_rag_extraction_mode_id.dart';
import '../models/project_rag_mount_summary.dart';
import 'project_rag_analysis_summary_decoder.dart';
import 'project_rag_source_preprocessing_service.dart';

class ProjectRagExtractionExecutionService {
  ProjectRagExtractionExecutionService({
    DesktopTextFilePickerService? sourcePickerService,
    RagTxtCorpusIngestionService? txtCorpusIngestionService,
    SqliteRagMetadataRepository? metadataRepository,
    RagProjectMountSummaryService? mountSummaryService,
    ProjectRagAnalysisSummaryDecoder? analysisSummaryDecoder,
    ProjectRagSourcePreprocessingService? sourcePreprocessingService,
    Future<EmbeddingProviderPort?> Function()? embeddingProviderResolver,
  }) : _txtCorpusIngestionService =
           txtCorpusIngestionService ??
           RagTxtCorpusIngestionService(
             embeddingProviderResolver: embeddingProviderResolver,
           ),
       _metadataRepository =
           metadataRepository ?? SqliteRagMetadataRepository(),
       _mountSummaryService =
           mountSummaryService ??
           RagProjectMountSummaryService(
             metadataRepository:
                 metadataRepository ?? SqliteRagMetadataRepository(),
           ),
       _analysisSummaryDecoder =
           analysisSummaryDecoder ?? const ProjectRagAnalysisSummaryDecoder(),
       _sourcePreprocessingService =
           sourcePreprocessingService ??
           ProjectRagSourcePreprocessingService(
             sourcePickerService:
                 sourcePickerService ?? const DesktopTextFilePickerService(),
           );

  final RagTxtCorpusIngestionService _txtCorpusIngestionService;
  final SqliteRagMetadataRepository _metadataRepository;
  final RagProjectMountSummaryService _mountSummaryService;
  final ProjectRagAnalysisSummaryDecoder _analysisSummaryDecoder;
  final ProjectRagSourcePreprocessingService _sourcePreprocessingService;

  Future<ProjectRagExtractionExecutionResult> loadSnapshot({
    required ProjectDescriptor project,
    String selectedCorpusId = '',
  }) async {
    // 中文注释: 视图刷新只恢复当前项目的语料和挂载摘要，不触发任何构建动作。
    final corpora = await _metadataRepository.listCorpora(project);
    final selectedCorpus = _selectCorpus(corpora, selectedCorpusId);
    final mountSummary = await _mountSummaryService.summarize(project);
    return ProjectRagExtractionExecutionResult(
      ok: true,
      didMutateProject: false,
      statusMessage: mountSummary.hasBindings
          ? '当前项目已挂载 ${mountSummary.bindingCount} 组语料。'
          : '当前项目还没有挂载语料。',
      corpusPackage: selectedCorpus,
      mountSummary: _toProjectMountSummary(mountSummary),
      analysisSummary: _analysisSummaryDecoder.decode(selectedCorpus),
    );
  }

  Future<ProjectRagExtractionExecutionResult> pickAndExecute({
    required ProjectDescriptor project,
    String modeId = '',
    Future<void> Function(String statusMessage)? onProgress,
  }) async {
    final preprocessed = await _sourcePreprocessingService.pickAndPreprocess(
      project: project,
      onProgress: onProgress,
    );
    if (preprocessed == null) {
      return const ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '已取消语料提取。',
      );
    }
    return executePreprocessed(
      project: project,
      preprocessed: preprocessed,
      modeId: modeId,
      onProgress: onProgress,
    );
  }

  Future<ProjectRagExtractionExecutionResult> execute({
    required ProjectDescriptor project,
    required String sourceFilePath,
    String modeId = '',
    Future<void> Function(String statusMessage)? onProgress,
  }) async {
    final preprocessed = await _sourcePreprocessingService.preprocess(
      project: project,
      sourcePaths: <String>[sourceFilePath],
      onProgress: onProgress,
    );
    return executePreprocessed(
      project: project,
      preprocessed: preprocessed,
      modeId: modeId,
      onProgress: onProgress,
    );
  }

  Future<ProjectRagExtractionExecutionResult> executePreprocessed({
    required ProjectDescriptor project,
    required ProjectRagPreprocessResult preprocessed,
    String modeId = '',
    Future<void> Function(String statusMessage)? onProgress,
  }) async {
    final normalizedModeId = modeId.trim().isEmpty
        ? ProjectRagExtractionModeId.ragExtraction
        : modeId.trim();
    if (!ProjectRagExtractionModeId.isImplemented(normalizedModeId)) {
      return ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage:
            '${ProjectRagExtractionModeId.labelOf(normalizedModeId)} 暂未开放实现。',
      );
    }
    if (!preprocessed.ok ||
        preprocessed.normalizedSourceText.trim().isEmpty ||
        preprocessed.recentSourcePath.trim().isEmpty) {
      return ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: preprocessed.note.trim().isNotEmpty
            ? '语料提取失败：${preprocessed.note}'
            : '缺少可提取的规范文本。',
        normalizationNote: preprocessed.note,
      );
    }
    final fileName = preprocessed.displaySourceName.trim().isEmpty
        ? preprocessed.recentSourcePath.replaceAll('\\', '/').split('/').last
        : preprocessed.displaySourceName.trim();
    final timestamp = DateTime.now().toIso8601String();
    final corpusPackage = RagCorpusPackage(
      corpusId: _buildCorpusId(fileName, timestamp),
      title: fileName.trim().isEmpty ? 'txt 语料包' : 'txt 语料：$fileName',
      description: '第一阶段 txt 语料包。',
      sourceKind: 'txt',
      buildMode: 'basic',
      metadata: <String, Object?>{
        'source_file_path': preprocessed.recentSourcePath,
        'mode_id': normalizedModeId,
        'normalization_note': preprocessed.note,
        'normalization_stage': preprocessed.usedSmartNormalization
            ? 'smart_book_deconstruction'
            : 'offline_book_deconstruction',
      },
    );
    try {
      await _emitProgress(onProgress, '正在基于整理后的纯文本构建语料...');
      final builtCorpus = await _txtCorpusIngestionService.ingestNormalizedText(
        project: project,
        sourceDisplayName: fileName,
        sourceIdentityPath: preprocessed.recentSourcePath,
        normalizedText: preprocessed.normalizedSourceText,
        corpusPackage: corpusPackage,
        ingestedAt: timestamp,
        onProgress: (progress) async {
          await _emitProgress(onProgress, progress.message);
        },
      );
      final mountSummary = await _mountSummaryService.summarize(project);
      return ProjectRagExtractionExecutionResult(
        ok: true,
        didMutateProject: true,
        statusMessage:
            '语料已从整理后的纯文本构建：${builtCorpus.title}，${builtCorpus.chapterCount} 章，${builtCorpus.chunkCount} 个分片。'
            '${_embeddingDegradationNote(builtCorpus.metadata)}',
        corpusPackage: builtCorpus,
        mountSummary: _toProjectMountSummary(mountSummary),
        analysisSummary: _analysisSummaryDecoder.decode(builtCorpus),
        normalizationNote: preprocessed.note,
      );
    } catch (error) {
      return ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: UserFacingErrorHumanizer.humanize(error, action: '语料构建'),
        normalizationNote: preprocessed.note,
      );
    }
  }

  /// 把入库时记录的 embedding 降级原因翻译成给用户的诚实提示（拼接在成功消息后）。
  /// 空 = 向量正常生成，不附加任何说明。
  String _embeddingDegradationNote(JsonMap metadata) {
    final reason = ValueReaders.stringValue(
      metadata['embedding_degraded_reason'],
    );
    switch (reason) {
      case 'embedding_failed':
        return '（向量化失败，已退回关键词检索；如已配置向量化模型，请检查其密钥与可用性后重新入库。）';
      case 'embedding_empty':
        return '（向量化模型未返回有效向量，已退回关键词检索。）';
      case 'no_provider':
        return '（未配置向量化模型，本次仅写入元数据，检索将走关键词匹配。）';
      default:
        return '';
    }
  }

  Future<ProjectRagExtractionExecutionResult> mountSelectedCorpus({
    required ProjectDescriptor project,
    required RagCorpusPackage corpusPackage,
  }) async {
    // 中文注释: 挂载只建立项目与 corpus 的正式绑定，不在这里改写语料本体。
    final cleanCorpusId = corpusPackage.corpusId.trim();
    if (cleanCorpusId.isEmpty) {
      return const ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '当前没有可挂载的语料。',
      );
    }
    final binding = RetrievalMountBinding(
      bindingId: '${project.id}_${cleanCorpusId}_mount',
      projectId: project.id,
      corpusId: cleanCorpusId,
      mountScope: 'project',
      priority: 100,
      usagePolicy: 'evidence_only',
      activationPolicy: 'project_activation',
      createdAt: DateTime.now().toIso8601String(),
      metadata: <String, Object?>{'source_corpus_title': corpusPackage.title},
    );
    try {
      await _metadataRepository.upsertMountBinding(project, binding);
      final mountSummary = await _mountSummaryService.summarize(project);
      return ProjectRagExtractionExecutionResult(
        ok: true,
        didMutateProject: true,
        statusMessage: '语料已挂载到当前项目：${corpusPackage.title}',
        corpusPackage: corpusPackage,
        mountSummary: _toProjectMountSummary(mountSummary),
        analysisSummary: _analysisSummaryDecoder.decode(corpusPackage),
      );
    } catch (error) {
      return ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: UserFacingErrorHumanizer.humanize(error, action: '挂载语料'),
        corpusPackage: corpusPackage,
      );
    }
  }

  RagCorpusPackage? _selectCorpus(
    List<RagCorpusPackage> corpora,
    String selectedCorpusId,
  ) {
    if (corpora.isEmpty) {
      return null;
    }
    final cleanSelectedId = selectedCorpusId.trim();
    if (cleanSelectedId.isNotEmpty) {
      for (final corpus in corpora) {
        if (corpus.corpusId == cleanSelectedId) {
          return corpus;
        }
      }
    }
    final sorted = List<RagCorpusPackage>.from(corpora)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return sorted.first;
  }

  ProjectRagMountSummary _toProjectMountSummary(
    RagProjectMountSummary summary,
  ) {
    return ProjectRagMountSummary(
      projectId: summary.projectId,
      bindingCount: summary.bindingCount,
      corpusIds: summary.corpusIds,
      topCorpusId: summary.topCorpusId,
      topBindingId: summary.topBindingId,
      topMountScope: summary.topMountScope,
      topUsagePolicy: summary.topUsagePolicy,
      topActivationPolicy: summary.topActivationPolicy,
    );
  }

  String _buildCorpusId(String fileName, String timestamp) {
    // 中文注释: corpus id 只由文件名与时间戳派生，确保第一阶段构建可稳定定位，又不会引入随机主键。
    final cleanName = fileName
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final suffix = timestamp.replaceAll(RegExp(r'[^0-9]'), '').padLeft(14, '0');
    return 'rag_${cleanName.isEmpty ? 'txt' : cleanName}_$suffix';
  }

  Future<void> _emitProgress(
    Future<void> Function(String statusMessage)? onProgress,
    String statusMessage,
  ) async {
    if (onProgress == null) {
      return;
    }
    await onProgress(statusMessage);
  }
}
