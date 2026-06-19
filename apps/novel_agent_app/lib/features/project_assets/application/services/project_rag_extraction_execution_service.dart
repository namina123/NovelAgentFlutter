import 'dart:async';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/desktop_text_file_picker_service.dart';
import '../models/project_rag_extraction_execution_result.dart';
import '../models/project_rag_extraction_mode_id.dart';
import '../models/project_rag_mount_summary.dart';

class ProjectRagExtractionExecutionService {
  ProjectRagExtractionExecutionService({
    DesktopTextFilePickerService? sourcePickerService,
    RagTxtCorpusIngestionService? txtCorpusIngestionService,
    SqliteRagMetadataRepository? metadataRepository,
    RagProjectMountSummaryService? mountSummaryService,
  }) : _sourcePickerService =
           sourcePickerService ?? const DesktopTextFilePickerService(),
       _txtCorpusIngestionService =
           txtCorpusIngestionService ?? RagTxtCorpusIngestionService(),
       _metadataRepository =
           metadataRepository ?? SqliteRagMetadataRepository(),
       _mountSummaryService =
           mountSummaryService ?? RagProjectMountSummaryService(
             metadataRepository: metadataRepository ?? SqliteRagMetadataRepository(),
           );

  final DesktopTextFilePickerService _sourcePickerService;
  final RagTxtCorpusIngestionService _txtCorpusIngestionService;
  final SqliteRagMetadataRepository _metadataRepository;
  final RagProjectMountSummaryService _mountSummaryService;

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
    );
  }

  Future<ProjectRagExtractionExecutionResult> pickAndExecute({
    required ProjectDescriptor project,
    String modeId = '',
    Future<void> Function(String statusMessage)? onProgress,
  }) async {
    final selectedPath = await _sourcePickerService.pickSingleFile(
      dialogTitle: '选择 txt 语料源文件',
    );
    if (selectedPath == null) {
      return const ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '已取消语料提取。',
      );
    }
    return execute(
      project: project,
      sourceFilePath: selectedPath,
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
    // 中文注释: 第一阶段只允许 txt 语料提取，其他模式先以明确的合同占位返回。
    final normalizedModeId = modeId.trim().isEmpty
        ? ProjectRagExtractionModeId.ragExtraction
        : modeId.trim();
    if (!ProjectRagExtractionModeId.isImplemented(normalizedModeId)) {
      return ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '${ProjectRagExtractionModeId.labelOf(normalizedModeId)} 暂未开放实现。',
      );
    }
    final cleanSourcePath = sourceFilePath.trim();
    if (cleanSourcePath.isEmpty) {
      return const ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '缺少可提取的 txt 源文件路径。',
      );
    }
    final fileName = cleanSourcePath.replaceAll('\\', '/').split('/').last;
    final timestamp = DateTime.now().toIso8601String();
    final corpusPackage = RagCorpusPackage(
      corpusId: _buildCorpusId(fileName, timestamp),
      title: fileName.trim().isEmpty ? 'txt 语料包' : 'txt 语料：$fileName',
      description: '第一阶段 txt 语料包。',
      sourceKind: 'txt',
      buildMode: 'basic',
      metadata: <String, Object?>{
        'source_file_path': cleanSourcePath,
        'mode_id': normalizedModeId,
      },
    );
    try {
      await _emitProgress(onProgress, '正在准备语料提取...');
      final builtCorpus = await _txtCorpusIngestionService.ingestFile(
        project: project,
        sourceFilePath: cleanSourcePath,
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
            'txt 语料已构建：${builtCorpus.title}，${builtCorpus.chapterCount} 章，${builtCorpus.chunkCount} 个分片。',
        corpusPackage: builtCorpus,
        mountSummary: _toProjectMountSummary(mountSummary),
      );
    } catch (error) {
      return ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: 'txt 语料构建失败：$error',
      );
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
      metadata: <String, Object?>{
        'source_corpus_title': corpusPackage.title,
      },
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
      );
    } catch (error) {
      return ProjectRagExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '语料挂载失败：$error',
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
