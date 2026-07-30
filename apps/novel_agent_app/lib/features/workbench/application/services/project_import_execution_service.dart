import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_smart_import_agent_service.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_smart_import_contract.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_smart_import_orchestration_service.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_preview_markdown_service.dart';
import '../../../workbench/application/controllers/generate_draft_use_case_factory.dart';
import '../models/project_import_execution_result.dart';
import '../models/project_import_request.dart';
import 'delegating_project_source_original_archive_store.dart';
import 'markdown_project_source_original_archive_store.dart';
import 'project_import_action_policy_service.dart';
import 'project_import_smart_analysis_agent_service.dart';
import 'project_source_original_archive_store.dart';
import 'sqlite_project_source_original_archive_store.dart';

class ProjectImportExecutionService {
  ProjectImportExecutionService({
    required ImportProjectFilesUseCase importProjectFilesUseCase,
    required ProjectToolHostPort projectToolHostPort,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required BookDeconstructionNarrativePersistenceService
    narrativePersistenceService,
    AppSettings? Function()? readSettings,
    GenerateDraftUseCaseFactory? generateDraftUseCaseFactory,
    ReferenceSourceDocumentFileReaderService? sourceDocumentReaderService,
    ProjectImportActionPolicyService? actionPolicyService,
    ProjectImportSmartAnalysisAgentService? smartAnalysisAgentService,
    BookDeconstructionDraftBuilderService? draftBuilderService,
    BookDeconstructionPreviewMarkdownService? previewMarkdownService,
    BookDeconstructionTargetPathService? targetPathService,
    ProjectSourceOriginalArchiveStore? sourceOriginalArchiveStore,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
    ProjectContentPathPolicyService? contentPathPolicyService,
    SourceDocumentFormatCatalogService? sourceDocumentFormatCatalogService,
  }) : _importProjectFilesUseCase = importProjectFilesUseCase,
       _projectToolHostPort = projectToolHostPort,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _narrativePersistenceService = narrativePersistenceService,
       _sourceDocumentReaderService =
           sourceDocumentReaderService ??
           const ReferenceSourceDocumentFileReaderService(),
       _readSettings = readSettings,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _actionPolicyService =
           actionPolicyService ?? ProjectImportActionPolicyService(),
       _smartAnalysisAgentService =
           smartAnalysisAgentService ??
           (readSettings != null && generateDraftUseCaseFactory != null
               ? ProjectImportSmartAnalysisAgentService(
                   readSettings: readSettings,
                   generateDraftUseCaseFactory: generateDraftUseCaseFactory,
                   projectToolHostPort: projectToolHostPort,
                 )
               : null),
       _draftBuilderService =
           draftBuilderService ?? BookDeconstructionDraftBuilderService(),
       _previewMarkdownService =
           previewMarkdownService ??
           const BookDeconstructionPreviewMarkdownService(),
       _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService(),
       _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService(),
       _sourceDocumentFormatCatalogService =
           sourceDocumentFormatCatalogService ??
           const SourceDocumentFormatCatalogService(),
       _sourceOriginalArchiveStore =
           sourceOriginalArchiveStore ??
           DelegatingProjectSourceOriginalArchiveStore(
             markdownStore: MarkdownProjectSourceOriginalArchiveStore(
               projectToolHostPort: projectToolHostPort,
             ),
             sqliteStore: SqliteProjectSourceOriginalArchiveStore(
               projectToolHostPort: projectToolHostPort,
             ),
           );

  final ImportProjectFilesUseCase _importProjectFilesUseCase;
  final ProjectToolHostPort _projectToolHostPort;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final BookDeconstructionNarrativePersistenceService
  _narrativePersistenceService;
  final ReferenceSourceDocumentFileReaderService _sourceDocumentReaderService;
  final AppSettings? Function()? _readSettings;
  final GenerateDraftUseCaseFactory? _generateDraftUseCaseFactory;
  final ProjectImportActionPolicyService _actionPolicyService;
  final ProjectImportSmartAnalysisAgentService? _smartAnalysisAgentService;
  final BookDeconstructionDraftBuilderService _draftBuilderService;
  final BookDeconstructionPreviewMarkdownService _previewMarkdownService;
  final BookDeconstructionTargetPathService _targetPathService;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;
  final ProjectContentPathPolicyService _contentPathPolicyService;
  final SourceDocumentFormatCatalogService _sourceDocumentFormatCatalogService;
  final ProjectSourceOriginalArchiveStore _sourceOriginalArchiveStore;

  Future<ProjectImportExecutionResult> execute({
    required ProjectDescriptor project,
    required ProjectImportRequest request,
  }) async {
    final policy = _actionPolicyService.build(
      projectType: project.projectType,
      storageStrategy: project.storageStrategy,
      sourcePaths: request.sourcePaths,
      requestedTargetDirectory: request.targetDirectory,
      requestedAutoDeconstruct: request.autoDeconstruct,
      requestedSmartAnalysis: request.smartAnalysis,
      smartAnalysisProviderId: request.smartAnalysisProviderId,
      smartAnalysisModelId: request.smartAnalysisModelId,
      requestedSmartDeconstruction: request.smartDeconstruction,
      smartDeconstructionProviderId: request.smartDeconstructionProviderId,
      smartDeconstructionModelId: request.smartDeconstructionModelId,
    );
    final primarySourceSnapshots =
        <String, SqliteProjectBodyTextDocument?>{};
    final importResult = await _importProjectFilesUseCase.execute(
      project: project,
      sourcePaths: request.sourcePaths,
      targetDirectory: policy.resolvedTargetDirectory,
      prepareImportedFile:
          ({required project, required sourcePath, required relativePath}) {
            return _prepareImportedFilePrimarySource(
              project: project,
              sourcePath: sourcePath,
              relativePath: relativePath,
              snapshots: primarySourceSnapshots,
            );
          },
      rollbackPreparedImportedFile:
          ({required project, required sourcePath, required relativePath}) {
            return _restoreImportedFilePrimarySource(
              project: project,
              relativePath: relativePath,
              snapshots: primarySourceSnapshots,
            );
          },
    );
    final importedPaths = ValueReaders.stringList(
      importResult['imported_paths'],
    );
    final skippedPaths = ValueReaders.stringList(importResult['skipped_paths']);
    final importOk = ValueReaders.boolValue(importResult['ok']);
    final baseSummary = ValueReaders.stringValue(
      importResult['summary'],
      importOk ? '导入完成。' : '导入失败。',
    );
    if (!importOk) {
      return ProjectImportExecutionResult(
        ok: importOk,
        summary: baseSummary,
        importedPaths: importedPaths,
        skippedPaths: skippedPaths,
        autoDeconstructionApplied: false,
        autoDeconstructionPreviewPath: '',
        smartAnalysisApplied: false,
        smartAnalysisReportPath: '',
      );
    }
    final summaryParts = <String>[baseSummary];
    var autoDeconstructionApplied = false;
    var autoDeconstructionPreviewPath = '';
    final requestedAnyDeconstruction =
        request.autoDeconstruct || request.smartDeconstruction;
    if (requestedAnyDeconstruction) {
      if (policy.smartDeconstruction) {
        final autoResult = await _writeSmartDeconstructionPreview(
          project: project,
          sourcePaths: request.sourcePaths,
          providerId: request.smartDeconstructionProviderId,
          modelId: request.smartDeconstructionModelId,
        );
        if (autoResult.previewPath.trim().isNotEmpty) {
          autoDeconstructionApplied = true;
          autoDeconstructionPreviewPath = autoResult.previewPath;
          summaryParts.add('智能拆书预演纪要已写入 ${autoResult.previewPath}。');
        }
        if (autoResult.note.isNotEmpty) {
          summaryParts.add(autoResult.note);
        }
      } else if (!policy.canAutoDeconstruct) {
        summaryParts.add(policy.outputHint);
      } else {
        final autoResult = await _writeAutoDeconstructionPreview(
          project: project,
          sourcePath: request.sourcePaths.single.trim(),
        );
        if (autoResult.previewPath.trim().isNotEmpty) {
          autoDeconstructionApplied = true;
          autoDeconstructionPreviewPath = autoResult.previewPath;
          summaryParts.add('自动拆书预演纪要已写入 ${autoResult.previewPath}。');
        }
        if (autoResult.note.isNotEmpty) {
          summaryParts.add(autoResult.note);
        }
      }
    }
    var smartAnalysisApplied = false;
    var smartAnalysisReportPath = '';
    if (policy.canSmartAnalyze && policy.smartAnalysis) {
      final smartResult = await _writeSmartAnalysisReport(
        project: project,
        importedPaths: importedPaths,
        smartAnalysisProviderId: policy.smartAnalysisProviderId,
        smartAnalysisModelId: policy.smartAnalysisModelId,
      );
      if (smartResult.reportPath.isNotEmpty) {
        smartAnalysisApplied = true;
        smartAnalysisReportPath = smartResult.reportPath;
        summaryParts.add('智能分析报告已写入 ${smartResult.reportPath}。');
        if (smartResult.note.isNotEmpty) {
          summaryParts.add(smartResult.note);
        }
      } else if (smartResult.note.isNotEmpty) {
        summaryParts.add(smartResult.note);
      }
    }
    return ProjectImportExecutionResult(
      ok: importOk,
      summary: summaryParts.join(' '),
      importedPaths: importedPaths,
      skippedPaths: skippedPaths,
      autoDeconstructionApplied: autoDeconstructionApplied,
      autoDeconstructionPreviewPath: autoDeconstructionPreviewPath,
      smartAnalysisApplied: smartAnalysisApplied,
      smartAnalysisReportPath: smartAnalysisReportPath,
    );
  }

  Future<void> _prepareImportedFilePrimarySource({
    required ProjectDescriptor project,
    required String sourcePath,
    required String relativePath,
    required Map<String, SqliteProjectBodyTextDocument?> snapshots,
  }) async {
    final snapshot = await _structuredContentBridgeService.loadStructuredDocument(
      project: project,
      documentPath: relativePath,
    );
    final persisted = await _persistImportedFilePrimarySource(
      project: project,
      sourcePath: sourcePath,
      relativePath: relativePath,
    );
    if (persisted) {
      snapshots[relativePath] = snapshot;
    }
  }

  Future<void> _restoreImportedFilePrimarySource({
    required ProjectDescriptor project,
    required String relativePath,
    required Map<String, SqliteProjectBodyTextDocument?> snapshots,
  }) async {
    if (!snapshots.containsKey(relativePath)) {
      return;
    }
    await _structuredContentBridgeService.restoreStructuredDocument(
      project: project,
      documentPath: relativePath,
      snapshot: snapshots.remove(relativePath),
    );
  }

  Future<bool> _persistImportedFilePrimarySource({
    required ProjectDescriptor project,
    required String sourcePath,
    required String relativePath,
  }) async {
    // 中文注释: SQLite 的导入文本先通过正式 reader 解码并入主库；无法解析的附件保留为纯文件复制。
    if (project.storageStrategy != ProjectStorageStrategy.sqliteProjectStore ||
        !_sourceDocumentFormatCatalogService.supportsPath(sourcePath)) {
      return false;
    }
    ReferenceSourceDocumentFileReadResult sourceDocument;
    try {
      sourceDocument = await _sourceDocumentReaderService.read(
        sourceFilePath: sourcePath,
      );
    } catch (_) {
      // Reader failures must not turn an otherwise valid attachment import into a failed operation.
      return false;
    }
    if (sourceDocument.sourceText.trim().isEmpty) {
      return false;
    }
    // 中文注释: 已可解析的文本必须先成功写入 SQLite 主事实源；写入失败时不能
    // 继续复制 Markdown 投影，否则下次按主库读取会丢失该资料。
    await _structuredContentBridgeService.persistStructuredDocument(
      project: project,
      documentPath: relativePath,
      documentKind: _importedDocumentKind(project, relativePath),
      title: sourceDocument.sourceTitle,
      content: sourceDocument.sourceText,
    );
    return true;
  }

  String _importedDocumentKind(ProjectDescriptor project, String relativePath) {
    final normalizedPath = relativePath.trim().replaceAll('\\', '/');
    final inferredKind = _contentPathPolicyService.inferContentTypeFromPath(
      normalizedPath,
    );
    if (project.projectType.trim() ==
            BookDeconstructionConstants.projectTypeId &&
        (normalizedPath.startsWith('imports/source_original/') ||
            normalizedPath.startsWith('sources/original/'))) {
      return 'source_original';
    }
    if (project.projectType.trim() == 'knowledge_base' &&
        normalizedPath.startsWith('imports/') &&
        !normalizedPath.startsWith('imports/analysis/') &&
        !normalizedPath.startsWith('imports/source_original/') &&
        !normalizedPath.startsWith('imports/derived/')) {
      return 'knowledge';
    }
    return inferredKind;
  }

  Future<_AutoDeconstructionOutcome> _writeAutoDeconstructionPreview({
    required ProjectDescriptor project,
    required String sourcePath,
  }) async {
    // 中文注释: 自动拆书统一走 source document reader，这样 txt / markdown / epub 都会先被解成标准文本。
    final sourceDocument = await _sourceDocumentReaderService.read(
      sourceFilePath: sourcePath,
    );
    final sourceContent = sourceDocument.sourceText;
    if (sourceContent.trim().isEmpty) {
      return const _AutoDeconstructionOutcome(
        previewPath: '',
        note: '自动拆书失败：所选文件不可读取或内容为空。',
      );
    }
    final buildResult = await _draftBuilderService.build(
      sourceTitle: '',
      sourceContent: sourceContent,
      sourceAbsolutePath: sourcePath,
      operatorNotes: '',
      styleSummary: '',
      worldRulesText: '',
      characterLinesText: '',
      organizationLinesText: '',
    );
    final previewPath = _actionPolicyService.autoDeconstructionPreviewPath(
      projectType: project.projectType,
      sourcePath: sourcePath,
    );
    var note = '';
    if (project.projectType.trim() ==
        BookDeconstructionConstants.projectTypeId) {
      final archivePath = _targetPathService.sourceArchivePath(
        sourcePath,
        storageStrategy: project.storageStrategy,
      );
      await _sourceOriginalArchiveStore.persist(
        project: project,
        relativePath: archivePath,
        title: _sourceTitleFromPath(sourcePath),
        content: sourceDocument.sourceText.trim(),
      );
      note = '原文文本归档已写入 $archivePath。';
    }
    final selectedItemIds = buildResult.applicationPlan.items
        .map((item) => item.id)
        .toSet();
    final previewMarkdown = _previewMarkdownService.render(
      buildResult: buildResult,
      selectedItemIds: selectedItemIds,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: previewPath,
      content: previewMarkdown,
    );
    await _narrativePersistenceService.persist(
      project: project,
      narrativeArtifacts: buildResult.narrativeArtifacts,
    );
    return _AutoDeconstructionOutcome(previewPath: previewPath, note: note);
  }

  Future<_AutoDeconstructionOutcome> _writeSmartDeconstructionPreview({
    required ProjectDescriptor project,
    required List<String> sourcePaths,
    required String providerId,
    required String modelId,
  }) async {
    final readSettings = _readSettings;
    final generateDraftUseCaseFactory = _generateDraftUseCaseFactory;
    if (readSettings == null || generateDraftUseCaseFactory == null) {
      return const _AutoDeconstructionOutcome(
        previewPath: '',
        note: '智能拆书未执行：缺少模型或运行时装配。',
      );
    }
    if (providerId.trim().isEmpty || modelId.trim().isEmpty) {
      return const _AutoDeconstructionOutcome(
        previewPath: '',
        note: '智能拆书未执行：需要先选择拆书专用模型。',
      );
    }
    final orchestrationService =
        BookDeconstructionSmartImportOrchestrationService(
          agentService: BookDeconstructionSmartImportAgentService(
            readSettings: readSettings,
            generateDraftUseCaseFactory: generateDraftUseCaseFactory,
          ),
        );
    final smartResult = await orchestrationService.execute(
      project: project,
      sourcePaths: sourcePaths,
      providerId: providerId,
      modelId: modelId,
    );
    if (smartResult.normalizedSourceText.trim().isEmpty) {
      return _AutoDeconstructionOutcome(
        previewPath: '',
        note: smartResult.note.isNotEmpty
            ? smartResult.note
            : '智能拆书未产出有效的清洗文本。',
      );
    }
    final buildResult = await _draftBuilderService.build(
      sourceTitle: '',
      sourceContent: smartResult.normalizedSourceText,
      sourceAbsolutePath: sourcePaths.first.trim(),
      operatorNotes: '',
      styleSummary: '',
      worldRulesText: '',
      characterLinesText: '',
      organizationLinesText: '',
    );
    final previewPath = _actionPolicyService.autoDeconstructionPreviewPath(
      projectType: project.projectType,
      sourcePath: sourcePaths.first.trim(),
    );
    var note = smartResult.note.trim().isEmpty
        ? '智能拆书已完成。'
        : smartResult.note.trim();
    if (project.projectType.trim() ==
            BookDeconstructionConstants.projectTypeId &&
        sourcePaths.length == 1 &&
        await FileSystemEntity.type(
              sourcePaths.single.trim(),
              followLinks: false,
            ) ==
            FileSystemEntityType.file) {
      final primarySourcePath = sourcePaths.first.trim();
      final sourceDocument = await _sourceDocumentReaderService.read(
        sourceFilePath: primarySourcePath,
      );
      final archivePath = _targetPathService.sourceArchivePath(
        primarySourcePath,
        storageStrategy: project.storageStrategy,
      );
      await _sourceOriginalArchiveStore.persist(
        project: project,
        relativePath: archivePath,
        title: _sourceTitleFromPath(primarySourcePath),
        content: sourceDocument.sourceText.trim(),
      );
      note = note.isEmpty
          ? '原文文本归档已写入 $archivePath。'
          : '$note 原文文本归档已写入 $archivePath。';
    } else if (project.projectType.trim() ==
        BookDeconstructionConstants.projectTypeId) {
      note = note.isEmpty
          ? '原始导入文件已按原路径保留在来源目录中。'
          : '$note 原始导入文件已按原路径保留在来源目录中。';
    }
    final selectedItemIds = buildResult.applicationPlan.items
        .map((item) => item.id)
        .toSet();
    final previewMarkdown = _previewMarkdownService.render(
      buildResult: buildResult,
      selectedItemIds: selectedItemIds,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: previewPath,
      content: previewMarkdown,
    );
    await _narrativePersistenceService.persist(
      project: project,
      narrativeArtifacts: buildResult.narrativeArtifacts,
    );
    if (smartResult.rulesContent.trim().isNotEmpty) {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: _smartDeconstructionRulesProjectPath(),
        content: smartResult.rulesContent,
      );
    }
    final reportPath = _smartDeconstructionReportProjectPath();
    if (smartResult.reportContent.trim().isNotEmpty) {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: reportPath,
        content: smartResult.reportContent,
      );
    }
    if (smartResult.reportPath.isNotEmpty) {
      note = '$note 报告已写入 $reportPath。';
    }
    return _AutoDeconstructionOutcome(previewPath: previewPath, note: note);
  }

  String _smartDeconstructionRulesProjectPath() {
    return BookDeconstructionSmartImportContract.rulesPath.replaceFirst(
      'deconstruction_import',
      'deconstruction',
    );
  }

  String _smartDeconstructionReportProjectPath() {
    return BookDeconstructionSmartImportContract.reportPath.replaceFirst(
      'deconstruction_import',
      'deconstruction',
    );
  }

  Future<_SmartAnalysisOutcome> _writeSmartAnalysisReport({
    required ProjectDescriptor project,
    required List<String> importedPaths,
    required String smartAnalysisProviderId,
    required String smartAnalysisModelId,
  }) async {
    // 中文注释: 一般项目导入的智能分析只消费已经落盘的导入文件，输出分类报告，不反向污染拆书主链。
    if (project.projectType.trim() ==
        BookDeconstructionConstants.projectTypeId) {
      return const _SmartAnalysisOutcome();
    }
    if (importedPaths.isEmpty) {
      return const _SmartAnalysisOutcome(note: '智能分析未执行：没有可分析的导入文件。');
    }
    var fallbackNote = '';
    final smartAnalysisAgentService = _smartAnalysisAgentService;
    if (smartAnalysisAgentService != null &&
        smartAnalysisProviderId.trim().isNotEmpty &&
        smartAnalysisModelId.trim().isNotEmpty) {
      final smartAgentResult = await smartAnalysisAgentService.execute(
        project: project,
        importedPaths: importedPaths,
        providerId: smartAnalysisProviderId,
        modelId: smartAnalysisModelId,
      );
      if (smartAgentResult.applied &&
          smartAgentResult.reportPath.trim().isNotEmpty) {
        return _SmartAnalysisOutcome(
          reportPath: smartAgentResult.reportPath,
          note: smartAgentResult.note.trim().isEmpty
              ? '智能分析已使用 ${smartAgentResult.resolvedModelId} 生成报告。'
              : smartAgentResult.note,
        );
      }
      fallbackNote = smartAgentResult.note.trim();
    }
    final analyses = <_ImportedFileAnalysis>[];
    for (final importedPath in importedPaths) {
      final content = await _readImportedSourceContent(
        project: project,
        importedPath: importedPath,
      );
      if (content.trim().isEmpty) {
        continue;
      }
      analyses.add(
        _classifyImportedFile(
          relativePath: importedPath,
          content: _classificationSample(content),
        ),
      );
    }
    if (analyses.isEmpty) {
      return const _SmartAnalysisOutcome(note: '智能分析未执行：导入文件内容为空或不可读取。');
    }
    final reportPath = 'analysis/project_import_analysis.md';
    final report = _renderSmartAnalysisReport(
      project: project,
      smartAnalysisProviderId: smartAnalysisProviderId,
      smartAnalysisModelId: smartAnalysisModelId,
      analyses: analyses,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: reportPath,
      content: report,
    );
    return _SmartAnalysisOutcome(
      reportPath: reportPath,
      note: [
        if (fallbackNote.isNotEmpty) fallbackNote,
        _smartAnalysisSummary(analyses),
      ].join(' '),
    );
  }

  Future<String> _readImportedSourceContent({
    required ProjectDescriptor project,
    required String importedPath,
  }) async {
    // 中文注释: 智能分析优先走正式 source-document reader，这样文本、Markdown 与 EPUB 都能按同一格式目录消费。
    final absolutePath = _projectAbsolutePath(project.rootPath, importedPath);
    try {
      final document = await _sourceDocumentReaderService.read(
        sourceFilePath: absolutePath,
      );
      if (document.sourceText.trim().isNotEmpty) {
        return document.sourceText;
      }
    } catch (_) {
      // 中文注释: reader 失败时保留旧的项目工作区读取兜底，避免现有纯文本测试与历史导入流程被误伤。
    }
    return await _projectToolHostPort.readTextFile(
          project.rootPath,
          importedPath,
        ) ??
        '';
  }

  _ImportedFileAnalysis _classifyImportedFile({
    required String relativePath,
    required String content,
  }) {
    final cleanPath = relativePath.trim();
    final cleanContent = content.trim();
    final path = cleanPath.toLowerCase();
    final text = cleanContent.toLowerCase();
    final scores = <String, int>{
      'novel_source_text': 0,
      'outline_document': 0,
      'worldbuilding_document': 0,
      'character_document': 0,
      'reference_material': 0,
    };
    if (path.endsWith('.txt') || path.endsWith('.epub')) {
      scores['novel_source_text'] = scores['novel_source_text']! + 2;
    }
    if (path.endsWith('.md') || path.endsWith('.markdown')) {
      scores['outline_document'] = scores['outline_document']! + 1;
    }
    for (final pattern in <String>[
      '第一章',
      'chapter 1',
      'chapter one',
      '第1章',
      '第 1 章',
    ]) {
      if (text.contains(pattern)) {
        scores['novel_source_text'] = scores['novel_source_text']! + 2;
      }
    }
    for (final pattern in <String>[
      '大纲',
      '章纲',
      '卷纲',
      '目录',
      'outline',
      'summary',
    ]) {
      if (text.contains(pattern)) {
        scores['outline_document'] = scores['outline_document']! + 2;
      }
    }
    for (final pattern in <String>[
      '世界观',
      '设定',
      '规则',
      '体系',
      '法则',
      'worldbuilding',
    ]) {
      if (text.contains(pattern)) {
        scores['worldbuilding_document'] =
            scores['worldbuilding_document']! + 2;
      }
    }
    for (final pattern in <String>['角色', '人物', 'character', '人物卡', '角色卡']) {
      if (text.contains(pattern)) {
        scores['character_document'] = scores['character_document']! + 2;
      }
    }
    for (final pattern in <String>['参考', '资料', '引用', 'research', 'reference']) {
      if (text.contains(pattern)) {
        scores['reference_material'] = scores['reference_material']! + 2;
      }
    }
    final sortedScores = scores.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final best = sortedScores.first;
    final bestScore = best.value;
    final secondScore = sortedScores.length > 1 ? sortedScores[1].value : 0;
    final category = bestScore <= 0 || bestScore == secondScore
        ? 'mixed_unknown'
        : best.key;
    return _ImportedFileAnalysis(
      relativePath: cleanPath,
      category: category,
      confidence: bestScore <= 0
          ? 0.42
          : (bestScore / (bestScore + secondScore + 2)).clamp(0.45, 0.92),
      reason: _analysisReason(category, cleanPath),
    );
  }

  String _classificationSample(String content) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (normalized.length <= 16000) {
      return normalized;
    }
    final head = normalized.substring(0, 12000);
    final tail = normalized.substring(normalized.length - 4000);
    return '$head\n...\n$tail';
  }

  String _analysisReason(String category, String relativePath) {
    switch (category) {
      case 'novel_source_text':
        return '文件更像按章节组织的原文或正文来源。';
      case 'outline_document':
        return '文件更像大纲、章纲或结构说明。';
      case 'worldbuilding_document':
        return '文件更像世界观、设定或规则说明。';
      case 'character_document':
        return '文件更像角色或人物设定。';
      case 'reference_material':
        return '文件更像参考资料、研究材料或外部引用。';
      default:
        return '文件路径与内容信号都比较混合，暂时归为 unknown。';
    }
  }

  String _renderSmartAnalysisReport({
    required ProjectDescriptor project,
    required String smartAnalysisProviderId,
    required String smartAnalysisModelId,
    required List<_ImportedFileAnalysis> analyses,
  }) {
    final buffer = StringBuffer()
      ..writeln('# 导入智能分析')
      ..writeln()
      ..writeln('- 项目类型: ${project.projectType}')
      ..writeln('- 分析器: 内置导入分析智能体')
      ..writeln(
        '- 模型: ${smartAnalysisModelId.trim().isEmpty ? '未指定，已回退到规则分析' : smartAnalysisModelId.trim()}',
      )
      ..writeln(
        '- 接口: ${smartAnalysisProviderId.trim().isEmpty ? '未指定' : smartAnalysisProviderId.trim()}',
      )
      ..writeln('- 分析文件数: ${analyses.length}')
      ..writeln();
    for (final analysis in analyses) {
      buffer
        ..writeln('## ${analysis.relativePath}')
        ..writeln('- 类型: ${analysis.category}')
        ..writeln('- 置信度: ${analysis.confidence.toStringAsFixed(2)}')
        ..writeln('- 依据: ${analysis.reason}')
        ..writeln();
    }
    return buffer.toString().trimRight();
  }

  String _smartAnalysisSummary(List<_ImportedFileAnalysis> analyses) {
    final counts = <String, int>{};
    for (final analysis in analyses) {
      counts[analysis.category] = (counts[analysis.category] ?? 0) + 1;
    }
    final ordered = counts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final top = ordered.take(3).map((entry) => '${entry.key} ${entry.value} 项');
    return '智能分析已判断：${top.join('，')}。';
  }

  String _projectAbsolutePath(String rootPath, String relativePath) {
    // 中文注释: 这里只做绝对路径拼接与分隔符归一化，避免 reader 入口自己再长出一层路径策略。
    final cleanRoot = rootPath.trim().replaceAll('\\', '/');
    final cleanRelative = relativePath.trim().replaceAll('\\', '/');
    if (cleanRoot.isEmpty) {
      return cleanRelative;
    }
    if (cleanRelative.isEmpty) {
      return cleanRoot;
    }
    return '$cleanRoot/$cleanRelative';
  }

  String _sourceTitleFromPath(String sourcePath) {
    final normalized = sourcePath.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return '原文归档';
    }
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }
}

class _AutoDeconstructionOutcome {
  const _AutoDeconstructionOutcome({this.previewPath = '', this.note = ''});

  final String previewPath;
  final String note;
}

class _SmartAnalysisOutcome {
  const _SmartAnalysisOutcome({this.reportPath = '', this.note = ''});

  final String reportPath;
  final String note;
}

class _ImportedFileAnalysis {
  const _ImportedFileAnalysis({
    required this.relativePath,
    required this.category,
    required this.confidence,
    required this.reason,
  });

  final String relativePath;
  final String category;
  final double confidence;
  final String reason;
}
