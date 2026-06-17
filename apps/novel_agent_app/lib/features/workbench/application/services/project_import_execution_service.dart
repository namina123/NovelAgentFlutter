import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_preview_markdown_service.dart';
import '../models/project_import_execution_result.dart';
import '../models/project_import_request.dart';
import 'project_import_action_policy_service.dart';

class ProjectImportExecutionService {
  ProjectImportExecutionService({
    required ImportProjectFilesUseCase importProjectFilesUseCase,
    required ProjectToolHostPort projectToolHostPort,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required BookDeconstructionNarrativePersistenceService
    narrativePersistenceService,
    ReferenceSourceDocumentFileReaderService? sourceDocumentReaderService,
    ProjectImportActionPolicyService? actionPolicyService,
    BookDeconstructionDraftBuilderService? draftBuilderService,
    BookDeconstructionPreviewMarkdownService? previewMarkdownService,
    BookDeconstructionTargetPathService? targetPathService,
  }) : _importProjectFilesUseCase = importProjectFilesUseCase,
       _projectToolHostPort = projectToolHostPort,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _narrativePersistenceService = narrativePersistenceService,
       _sourceDocumentReaderService =
           sourceDocumentReaderService ??
           const ReferenceSourceDocumentFileReaderService(),
       _actionPolicyService =
           actionPolicyService ?? ProjectImportActionPolicyService(),
       _draftBuilderService =
           draftBuilderService ?? BookDeconstructionDraftBuilderService(),
       _previewMarkdownService =
           previewMarkdownService ??
           const BookDeconstructionPreviewMarkdownService(),
       _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService();

  final ImportProjectFilesUseCase _importProjectFilesUseCase;
  final ProjectToolHostPort _projectToolHostPort;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final BookDeconstructionNarrativePersistenceService
  _narrativePersistenceService;
  final ReferenceSourceDocumentFileReaderService _sourceDocumentReaderService;
  final ProjectImportActionPolicyService _actionPolicyService;
  final BookDeconstructionDraftBuilderService _draftBuilderService;
  final BookDeconstructionPreviewMarkdownService _previewMarkdownService;
  final BookDeconstructionTargetPathService _targetPathService;

  Future<ProjectImportExecutionResult> execute({
    required ProjectDescriptor project,
    required ProjectImportRequest request,
  }) async {
    final policy = _actionPolicyService.build(
      projectType: project.projectType,
      sourcePaths: request.sourcePaths,
      requestedTargetDirectory: request.targetDirectory,
      requestedAutoDeconstruct: request.autoDeconstruct,
      requestedSmartAnalysis: request.smartAnalysis,
      analysisAgentId: request.analysisAgentId,
      analysisAgentGroupId: request.analysisAgentGroupId,
    );
    final importResult = await _importProjectFilesUseCase.execute(
      project: project,
      sourcePaths: request.sourcePaths,
      targetDirectory: request.targetDirectory,
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
    if (request.autoDeconstruct) {
      if (!policy.canAutoDeconstruct) {
        summaryParts.add(policy.outputHint);
      } else {
        final autoResult = await _writeAutoDeconstructionPreview(
          project: project,
          sourcePath: request.sourcePaths.single.trim(),
        );
        autoDeconstructionApplied = true;
        autoDeconstructionPreviewPath = autoResult.previewPath;
        summaryParts.add('自动拆书预演纪要已写入 ${autoResult.previewPath}。');
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
        analysisAgentId: policy.analysisAgentId,
        analysisAgentGroupId: policy.analysisAgentGroupId,
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
    final buildResult = _draftBuilderService.build(
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
      final archivePath = _targetPathService.sourceArchivePath(sourcePath);
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: archivePath,
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

  Future<_SmartAnalysisOutcome> _writeSmartAnalysisReport({
    required ProjectDescriptor project,
    required List<String> importedPaths,
    required String analysisAgentId,
    required String analysisAgentGroupId,
  }) async {
    // 中文注释: 一般项目导入的智能分析只消费已经落盘的导入文件，输出分类报告，不反向污染拆书主链。
    if (project.projectType.trim() ==
        BookDeconstructionConstants.projectTypeId) {
      return const _SmartAnalysisOutcome();
    }
    if (importedPaths.isEmpty) {
      return const _SmartAnalysisOutcome(note: '智能分析未执行：没有可分析的导入文件。');
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
        _classifyImportedFile(relativePath: importedPath, content: content),
      );
    }
    if (analyses.isEmpty) {
      return const _SmartAnalysisOutcome(note: '智能分析未执行：导入文件内容为空或不可读取。');
    }
    final reportPath = 'analysis/project_import_analysis.md';
    final report = _renderSmartAnalysisReport(
      project: project,
      analysisAgentId: analysisAgentId,
      analysisAgentGroupId: analysisAgentGroupId,
      analyses: analyses,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: reportPath,
      content: report,
    );
    return _SmartAnalysisOutcome(
      reportPath: reportPath,
      note: _smartAnalysisSummary(analyses),
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
    required String analysisAgentId,
    required String analysisAgentGroupId,
    required List<_ImportedFileAnalysis> analyses,
  }) {
    final buffer = StringBuffer()
      ..writeln('# 导入智能分析')
      ..writeln()
      ..writeln('- 项目类型: ${project.projectType}')
      ..writeln(
        '- 智能体: ${analysisAgentId.trim().isEmpty ? '默认' : analysisAgentId.trim()}',
      )
      ..writeln(
        '- 智能体组: ${analysisAgentGroupId.trim().isEmpty ? '默认' : analysisAgentGroupId.trim()}',
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
