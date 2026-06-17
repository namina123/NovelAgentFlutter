import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_snapshot.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_preview_markdown_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/desktop_book_deconstruction_source_picker_service.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_import_request.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_import_execution_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_import_workspace_command_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';
import 'probe_support.dart';

Future<void> main(List<String> arguments) async {
  await ensureLocalRealProbeOptIn(
    probeName: 'real_gui_book_deconstruction_import_probe',
  );
  final report = await runRealGuiBookDeconstructionImportProbe();
  stdout.writeln(ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL');
  if (!ValueReaders.boolValue(report['ok'])) {
    exitCode = 1;
  }
}

Future<JsonMap> runRealGuiBookDeconstructionImportProbe({
  bool requireRealProbeOptIn = true,
}) async {
  // 中文注释: 这个 probe 同时验证拆书归档、一般导入、多格式 reader 与 smart-analysis 门控，所有结果都写回结构化报告。
  final repoRoot = resolveLocalProbeRepoRoot();
  final rawRunId = DateTime.now().toIso8601String();
  final runId = safeProbeTimestamp(rawRunId);
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: 'real_gui_book_deconstruction_import_probe',
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);
  final settingsRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}settings',
  )..createSync(recursive: true);
  final projectsRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}projects',
  )..createSync(recursive: true);
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: workspaceRoot.path,
    settingsRootPath: settingsRoot.path,
    defaultProjectRootPath: projectsRoot.path,
    allowConfiguredProjectPathOverride: false,
  );
  final report = <String, Object?>{
    'probe_name': 'real_gui_book_deconstruction_import_probe',
    'run_id': runId,
    'raw_run_id': rawRunId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace_root': workspaceRoot.path,
    'settings_root': settingsRoot.path,
    'projects_root': projectsRoot.path,
  };

  try {
    if (requireRealProbeOptIn) {
      await ensureLocalRealProbeOptIn(
        probeName: 'real_gui_book_deconstruction_import_probe',
      );
    }
    final assets = await _prepareSourceAssets(
      repoRoot: repoRoot,
      workspaceRoot: workspaceRoot,
    );
    report['source_assets'] = assets.toJson();

    final bookProject = ProjectDescriptor(
      id: 'probe_book_deconstruction',
      name: '拆书导入探针项目',
      rootPath:
          '${projectsRoot.path}${Platform.pathSeparator}probe_book_deconstruction',
      projectType: BookDeconstructionConstants.projectTypeId,
    );
    final generalSingleProject = ProjectDescriptor(
      id: 'probe_general_single_import',
      name: '一般单文件导入探针项目',
      rootPath:
          '${projectsRoot.path}${Platform.pathSeparator}probe_general_single_import',
      projectType: 'novel',
    );
    final generalDirectoryProject = ProjectDescriptor(
      id: 'probe_general_directory_import',
      name: '一般目录导入探针项目',
      rootPath:
          '${projectsRoot.path}${Platform.pathSeparator}probe_general_directory_import',
      projectType: 'novel',
    );
    for (final root in <String>[
      bookProject.rootPath,
      generalSingleProject.rootPath,
      generalDirectoryProject.rootPath,
    ]) {
      Directory(root).createSync(recursive: true);
    }

    final readerService = const ReferenceSourceDocumentFileReaderService();
    final sourceDiscoveryService = const SourceImportDiscoveryService();
    final importUseCase = ImportProjectFilesUseCase(
      projectToolHostPort: bundle.projectToolHostPort,
      sourceImportDiscoveryPort: sourceDiscoveryService,
    );
    final narrativePersistenceService =
        BookDeconstructionNarrativePersistenceService(
          workspacePort: bundle.projectWorkspacePort,
        );
    final previewMarkdownService =
        const BookDeconstructionPreviewMarkdownService();
    final draftBuilderService = BookDeconstructionDraftBuilderService();
    final bookController = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(
        bundle.projectWorkspacePort,
      ),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: bundle.projectWorkspacePort,
      ),
      narrativePersistenceService: narrativePersistenceService,
      readCurrentProject: () => bookProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      sourcePickerService: _FixedBookSourcePickerService(assets.bookSourcePath),
      draftBuilderService: draftBuilderService,
      previewMarkdownService: previewMarkdownService,
      viewDataService: const BookDeconstructionViewDataService(),
    );
    await bookController.initialize();
    await bookController.onBookDeconstructionImportFileRequested();
    bookController.onBookDeconstructionOperatorNotesChanged(
      '保留原文边界，确认后继续验证 continuation / fanfic 分流。',
    );
    bookController.onBookDeconstructionStyleSummaryChanged(
      '保持校园感与来源边界，不把预演混成正文。',
    );
    bookController.onBookDeconstructionWorldRulesChanged('拆书来源层、分析层和正文层必须分开。');
    bookController.onBookDeconstructionCharacterLinesChanged(
      '哈利、罗恩、赫敏保持核心三人组。',
    );
    bookController.onBookDeconstructionOrganizationLinesChanged(
      '霍格沃茨与原作组织关系保留来源身份。',
    );
    await bookController.onBookDeconstructionBuildPreviewRequested();
    final bookBuildResult = draftBuilderService.build(
      sourceTitle: bookController.viewData.sourceTitle,
      sourceContent: bookController.viewData.sourceContent,
      sourceAbsolutePath: bookController.viewData.sourceAbsolutePath,
      operatorNotes: '保留原文边界，确认后继续验证 continuation / fanfic 分流。',
      styleSummary: '保持校园感与来源边界，不把预演混成正文。',
      worldRulesText: '拆书来源层、分析层和正文层必须分开。',
      characterLinesText: '哈利、罗恩、赫敏保持核心三人组。',
      organizationLinesText: '霍格沃茨与原作组织关系保留来源身份。',
    );
    final bookViewData = const BookDeconstructionViewDataService().build(
      projectTitle: bookProject.name,
      snapshot: BookDeconstructionSnapshot.initial().copyWith(
        projectRootPath: bookProject.rootPath,
        sourceAbsolutePath: bookController.viewData.sourceAbsolutePath,
        sourceTitle: bookController.viewData.sourceTitle,
        sourceContent: bookController.viewData.sourceContent,
        operatorNotes: '保留原文边界，确认后继续验证 continuation / fanfic 分流。',
        styleSummary: '保持校园感与来源边界，不把预演混成正文。',
        worldRulesText: '拆书来源层、分析层和正文层必须分开。',
        characterLinesText: '哈利、罗恩、赫敏保持核心三人组。',
        organizationLinesText: '霍格沃茨与原作组织关系保留来源身份。',
        buildResult: bookBuildResult,
        selectedItemIds: bookBuildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
      ),
      status: bookController.viewData.status,
    );
    await bookController.onBookDeconstructionConfirmRequested();
    final bookArchivePath = const BookDeconstructionTargetPathService()
        .sourceArchivePath(assets.bookSourcePath);
    final bookPreviewPath = const BookDeconstructionTargetPathService()
        .previewPath();
    final bookArchiveText = await bundle.projectWorkspacePort.readTextFile(
      bookProject.rootPath,
      bookArchivePath,
    );
    final bookPreviewText = await bundle.projectWorkspacePort.readTextFile(
      bookProject.rootPath,
      bookPreviewPath,
    );
    final bookChaptersPreviewText = await bundle.projectWorkspacePort
        .readTextFile(
          bookProject.rootPath,
          'chapters/book_deconstruction_preview.md',
        );
    final continuationPlan =
        const BookDeconstructionDerivedProjectPlanBuilderService().build(
          input: bookBuildResult.input,
          followupMenu: bookBuildResult.followupMenu,
          followupOptionId: 'continuation_novel',
          narrativeArtifacts: bookBuildResult.narrativeArtifacts,
        );
    final fanficPlan =
        const BookDeconstructionDerivedProjectPlanBuilderService().build(
          input: bookBuildResult.input,
          followupMenu: bookBuildResult.followupMenu,
          followupOptionId: 'fanfic_seed_autopilot_novel',
          narrativeArtifacts: bookBuildResult.narrativeArtifacts,
        );

    final generalCommandService =
        ProjectImportWorkspaceCommandViewDataService();
    final bookImportCommand = generalCommandService.build(
      projectType: BookDeconstructionConstants.projectTypeId,
      sourcePaths: <String>[assets.generalSingleSourcePath],
      requestedTargetDirectory: 'assets',
      requestedAutoDeconstruct: false,
      requestedSmartAnalysis: true,
      analysisAgentId: 'probe-analysis-agent',
      analysisAgentGroupId: 'probe-analysis-group',
    );
    final generalImportCommand = generalCommandService.build(
      projectType: 'novel',
      sourcePaths: <String>[assets.generalSingleSourcePath],
      requestedTargetDirectory: 'assets',
      requestedAutoDeconstruct: false,
      requestedSmartAnalysis: true,
      analysisAgentId: 'probe-analysis-agent',
      analysisAgentGroupId: 'probe-analysis-group',
    );

    final singleImportResult =
        await ProjectImportExecutionService(
          importProjectFilesUseCase: importUseCase,
          projectToolHostPort: bundle.projectToolHostPort,
          writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
            projectWorkspacePort: bundle.projectWorkspacePort,
          ),
          narrativePersistenceService: narrativePersistenceService,
          sourceDocumentReaderService: readerService,
        ).execute(
          project: generalSingleProject,
          request: ProjectImportRequest(
            sourcePaths: <String>[assets.generalSingleSourcePath],
            targetDirectory: 'assets/single',
            autoDeconstruct: false,
            smartAnalysis: true,
            analysisAgentId: 'probe-analysis-agent',
            analysisAgentGroupId: 'probe-analysis-group',
          ),
        );

    final discoveryRequest = SourceImportRequest(
      requestId: 'probe_directory_import',
      selections: <SourceImportSelection>[
        SourceImportSelection(
          selectionId: 'directory_bundle',
          selectionKind: SourceImportSelectionKinds.directory,
          sourceIdentity: const SourceAssetIdentity(
            sourceAssetId: 'directory_bundle',
            sourceKind: 'directory',
            displayName: 'directory_bundle',
            localHintPath: 'directory_bundle',
          ),
          sourceLocator: assets.generalDirectoryRootPath,
          sortOrder: 1,
          mediaType: 'inode/directory',
          relativePathHint: 'directory_bundle',
          recursive: true,
        ),
      ],
    );
    final discoveryResult = await sourceDiscoveryService.discover(
      discoveryRequest,
    );

    final directoryImportResult =
        await ProjectImportExecutionService(
          importProjectFilesUseCase: importUseCase,
          projectToolHostPort: bundle.projectToolHostPort,
          writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
            projectWorkspacePort: bundle.projectWorkspacePort,
          ),
          narrativePersistenceService: narrativePersistenceService,
          sourceDocumentReaderService: readerService,
        ).execute(
          project: generalDirectoryProject,
          request: ProjectImportRequest(
            sourcePaths: <String>[assets.generalDirectoryRootPath],
            targetDirectory: 'assets/bundle',
            autoDeconstruct: false,
            smartAnalysis: true,
            analysisAgentId: 'probe-analysis-agent',
            analysisAgentGroupId: 'probe-analysis-group',
          ),
        );

    final epubReaderResult = await readerService.read(
      sourceFilePath: assets.epubFilePath,
    );
    final generalSingleAnalysisText = await bundle.projectWorkspacePort
        .readTextFile(
          generalSingleProject.rootPath,
          'analysis/project_import_analysis.md',
        );
    final generalDirectoryAnalysisText = await bundle.projectWorkspacePort
        .readTextFile(
          generalDirectoryProject.rootPath,
          'analysis/project_import_analysis.md',
        );

    report['book_deconstruction'] = <String, Object?>{
      'project_root': bookProject.rootPath,
      'source_path': assets.bookSourcePath,
      'source_title': bookController.viewData.sourceTitle,
      'archive_path': bookArchivePath,
      'archive_exists': (bookArchiveText ?? '').trim().isNotEmpty,
      'preview_path': bookPreviewPath,
      'preview_exists': (bookPreviewText ?? '').trim().isNotEmpty,
      'chapters_preview_exists': (bookChaptersPreviewText ?? '')
          .trim()
          .isNotEmpty,
      'controller_status': bookController.viewData.status,
      'controller_confirmed_preview_path':
          bookController.viewData.confirmedPreviewPath,
      'continuity_groups': bookViewData.continuity!.followupGroups
          .map((group) => group.id)
          .toList(growable: false),
      'information_routes': bookViewData.informationBridge!.followupRoutes
          .map((route) => route.title)
          .toList(growable: false),
      'continuation_plan': <String, Object?>{
        'followup_option_id': continuationPlan.followupOptionId,
        'target_project_type_id': continuationPlan.targetProjectTypeId,
        'source_inheritance_mode': continuationPlan.sourceInheritanceMode.name,
        'recommended_build_tier': continuationPlan.recommendedBuildTier.name,
        'suggested_project_title': continuationPlan.suggestedProjectTitle,
      },
      'fanfic_plan': <String, Object?>{
        'followup_option_id': fanficPlan.followupOptionId,
        'target_project_type_id': fanficPlan.targetProjectTypeId,
        'source_inheritance_mode': fanficPlan.sourceInheritanceMode.name,
        'recommended_build_tier': fanficPlan.recommendedBuildTier.name,
        'suggested_project_title': fanficPlan.suggestedProjectTitle,
      },
      'controller_view_status': bookController.viewData.status,
    };
    report['smart_analysis_visibility'] = <String, Object?>{
      'book_project_can_smart_analyze': bookImportCommand.canSmartAnalyze,
      'book_project_smart_analysis_visible': bookImportCommand.canSmartAnalyze,
      'general_project_can_smart_analyze': generalImportCommand.canSmartAnalyze,
      'general_project_smart_analysis_visible':
          generalImportCommand.canSmartAnalyze,
      'general_project_smart_analysis_enabled':
          generalImportCommand.smartAnalysis,
      'book_project_file_selection_hint':
          bookImportCommand.importFileSelectionHint,
      'general_project_file_selection_hint':
          generalImportCommand.importFileSelectionHint,
    };
    report['source_discovery'] = <String, Object?>{
      'selection_count': discoveryResult.selections.length,
      'skipped_paths': discoveryResult.skippedPaths,
      'relative_paths': discoveryResult.selections
          .map((selection) => selection.relativePathHint)
          .toList(growable: false),
      'media_types': discoveryResult.selections
          .map((selection) => selection.mediaType)
          .toList(growable: false),
    };
    report['single_import'] = <String, Object?>{
      'project_root': generalSingleProject.rootPath,
      'imported_paths': singleImportResult.importedPaths,
      'skipped_paths': singleImportResult.skippedPaths,
      'auto_deconstruction_applied':
          singleImportResult.autoDeconstructionApplied,
      'smart_analysis_applied': singleImportResult.smartAnalysisApplied,
      'smart_analysis_report_path': singleImportResult.smartAnalysisReportPath,
      'smart_analysis_report_exists': (generalSingleAnalysisText ?? '')
          .trim()
          .isNotEmpty,
      'smart_analysis_report_excerpt': _snippet(
        generalSingleAnalysisText ?? '',
        maxLength: 320,
      ),
    };
    report['directory_import'] = <String, Object?>{
      'project_root': generalDirectoryProject.rootPath,
      'imported_paths': directoryImportResult.importedPaths,
      'skipped_paths': directoryImportResult.skippedPaths,
      'auto_deconstruction_applied':
          directoryImportResult.autoDeconstructionApplied,
      'smart_analysis_applied': directoryImportResult.smartAnalysisApplied,
      'smart_analysis_report_path':
          directoryImportResult.smartAnalysisReportPath,
      'smart_analysis_report_exists': (generalDirectoryAnalysisText ?? '')
          .trim()
          .isNotEmpty,
      'smart_analysis_report_excerpt': _snippet(
        generalDirectoryAnalysisText ?? '',
        maxLength: 320,
      ),
    };
    report['epub_reader'] = <String, Object?>{
      'epub_path': assets.epubFilePath,
      'decode_mode': epubReaderResult.decodeMode,
      'source_title': epubReaderResult.sourceTitle,
      'text_excerpt': _snippet(epubReaderResult.sourceText, maxLength: 240),
    };

    _ensure(
      (bookArchiveText ?? '').trim().isNotEmpty,
      '拆书原文未归档到 sources/original/。',
    );
    _ensure((bookPreviewText ?? '').trim().isNotEmpty, '拆书预演纪要未写入 analysis/。');
    _ensure(
      (bookChaptersPreviewText ?? '').trim().isEmpty,
      '拆书预演纪要不应落到 chapters/。',
    );
    _ensure(
      bookController.viewData.confirmedPreviewPath == bookPreviewPath,
      '拆书控制器确认路径不正确。',
    );
    _ensure(
      continuationPlan.sourceInheritanceMode ==
          BookDeconstructionSourceInheritanceMode.continuation,
      'continuation 派生计划的来源继承模式不正确。',
    );
    _ensure(
      fanficPlan.sourceInheritanceMode ==
          BookDeconstructionSourceInheritanceMode.fanfic,
      'fanfic 派生计划的来源继承模式不正确。',
    );
    _ensure(bookImportCommand.canSmartAnalyze == false, '拆书导入场景不应暴露智能分析入口。');
    _ensure(generalImportCommand.canSmartAnalyze == true, '一般导入场景应暴露智能分析入口。');
    _ensure(discoveryResult.selections.length == 3, '目录发现结果没有完整展开为三类受支持文件。');
    _ensure(
      discoveryResult.selections.any(
        (selection) => selection.mediaType == 'application/epub+zip',
      ),
      '目录发现结果没有识别 EPUB。',
    );
    _ensure(singleImportResult.smartAnalysisApplied, '一般单文件导入的智能分析没有落盘。');
    _ensure(directoryImportResult.smartAnalysisApplied, '一般目录导入的智能分析没有落盘。');
    _ensure(epubReaderResult.decodeMode == 'epub', 'EPUB reader 没有按 epub 路由。');
    report['ok'] = true;
  } catch (error, stackTrace) {
    report['ok'] = false;
    report['error'] = '$error';
    report['stack_trace'] = '$stackTrace';
  } finally {
    report['finished_at'] = DateTime.now().toIso8601String();
    final reportFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_gui_book_deconstruction_import_probe_report.json',
    );
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    final markdownFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_gui_book_deconstruction_import_probe_report.md',
    );
    await markdownFile.writeAsString(_reportMarkdown(report));
    report['report_path'] = reportFile.path;
  }
  return report;
}

class _ProbeSourceAssets {
  const _ProbeSourceAssets({
    required this.bookSourcePath,
    required this.generalSingleSourcePath,
    required this.generalDirectoryRootPath,
    required this.epubFilePath,
  });

  final String bookSourcePath;
  final String generalSingleSourcePath;
  final String generalDirectoryRootPath;
  final String epubFilePath;

  JsonMap toJson() {
    // 中文注释: source asset 列表只作为 probe 报告的一部分，不承担任何业务判断。
    return <String, Object?>{
      'book_source_path': bookSourcePath,
      'general_single_source_path': generalSingleSourcePath,
      'general_directory_root_path': generalDirectoryRootPath,
      'epub_file_path': epubFilePath,
    };
  }
}

Future<_ProbeSourceAssets> _prepareSourceAssets({
  required String repoRoot,
  required Directory workspaceRoot,
}) async {
  // 中文注释: 这里把仓库里的真实文本资产复制到临时工作区，再额外生成一个最小 EPUB，便于同时验证单文件、目录与多格式 reader。
  final sourceFilesRoot = Directory(
    '$repoRoot${Platform.pathSeparator}references${Platform.pathSeparator}files',
  );
  final generalSourceRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}source_assets',
  )..createSync(recursive: true);
  final singleSourceFile = await _copyReferenceFile(
    sourceFilesRoot: sourceFilesRoot,
    sourceFileName: '下一个提示.md',
    targetFile: File(
      '${generalSourceRoot.path}${Platform.pathSeparator}single_outline.md',
    ),
  );
  final directoryRoot = Directory(
    '${generalSourceRoot.path}${Platform.pathSeparator}mixed_directory',
  )..createSync(recursive: true);
  final textDirectory = Directory(
    '${directoryRoot.path}${Platform.pathSeparator}texts',
  )..createSync(recursive: true);
  final epubDirectory = Directory(
    '${directoryRoot.path}${Platform.pathSeparator}series',
  )..createSync(recursive: true);
  final ignoredDirectory = Directory(
    '${directoryRoot.path}${Platform.pathSeparator}ignored',
  )..createSync(recursive: true);
  await _copyReferenceFile(
    sourceFilesRoot: sourceFilesRoot,
    sourceFileName: 'ai风味提问回答全文.md',
    targetFile: File(
      '${textDirectory.path}${Platform.pathSeparator}outline.md',
    ),
  );
  await _copyReferenceFile(
    sourceFilesRoot: sourceFilesRoot,
    sourceFileName: '下一个提示.md',
    targetFile: File(
      '${textDirectory.path}${Platform.pathSeparator}chapter_01.txt',
    ),
  );
  final epubFile = File(
    '${epubDirectory.path}${Platform.pathSeparator}probe_story.epub',
  );
  await epubFile.writeAsBytes(buildProbeSampleEpubBytes());
  await File(
    '${ignoredDirectory.path}${Platform.pathSeparator}cover.png',
  ).writeAsBytes(<int>[0x89, 0x50, 0x4E, 0x47]);
  return _ProbeSourceAssets(
    bookSourcePath:
        '$repoRoot${Platform.pathSeparator}references${Platform.pathSeparator}files${Platform.pathSeparator}Harry Potter - Volume 1 Raw.txt',
    generalSingleSourcePath: singleSourceFile.path,
    generalDirectoryRootPath: directoryRoot.path,
    epubFilePath: epubFile.path,
  );
}

Future<File> _copyReferenceFile({
  required Directory sourceFilesRoot,
  required String sourceFileName,
  required File targetFile,
}) async {
  // 中文注释: 复制参考资产只用于 probe fixture 准备，不改变仓库里的正式资源树。
  final sourceFile = File(
    '${sourceFilesRoot.path}${Platform.pathSeparator}$sourceFileName',
  );
  if (!await sourceFile.exists()) {
    throw StateError('Source asset missing: ${sourceFile.path}');
  }
  await targetFile.parent.create(recursive: true);
  await targetFile.writeAsBytes(await sourceFile.readAsBytes());
  return targetFile;
}

List<int> buildProbeSampleEpubBytes() {
  // 中文注释: 这个最小 EPUB 只负责验证 zip 容器、container.xml、opf/spine 顺序和 XHTML 文本提取，不承担任何业务语义。
  return _buildStoredZip(<_ZipEntrySpec>[
    const _ZipEntrySpec('mimetype', 'application/epub+zip', isStored: true),
    const _ZipEntrySpec(
      'META-INF/container.xml',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
          '<rootfiles>'
          '<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>'
          '</rootfiles>'
          '</container>',
    ),
    const _ZipEntrySpec(
      'OEBPS/content.opf',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<package version="3.0" xmlns="http://www.idpf.org/2007/opf" '
          'xmlns:dc="http://purl.org/dc/elements/1.1/">'
          '<metadata>'
          '<dc:title>探针混合样章</dc:title>'
          '</metadata>'
          '<manifest>'
          '<item id="chap1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>'
          '<item id="chap2" href="chapter2.xhtml" media-type="application/xhtml+xml"/>'
          '</manifest>'
          '<spine>'
          '<itemref idref="chap1"/>'
          '<itemref idref="chap2"/>'
          '</spine>'
          '</package>',
    ),
    const _ZipEntrySpec(
      'OEBPS/chapter1.xhtml',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<h1>第一章 港口风暴</h1><p>哈利站在海风里。</p>'
          '</body></html>',
    ),
    const _ZipEntrySpec(
      'OEBPS/chapter2.xhtml',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<h1>第二章 议会阴影</h1><p>城邦议会悄然浮现。</p>'
          '</body></html>',
    ),
  ]);
}

List<int> _buildStoredZip(List<_ZipEntrySpec> specs) {
  // 中文注释: 这里手工写一个最小 ZIP 存储器，避免 probe 额外依赖编解码包，同时保证 EPUB fixture 可重复生成。
  final archive = BytesBuilder(copy: false);
  final centralDirectory = BytesBuilder(copy: false);
  var offset = 0;
  final entries = <_StoredZipEntry>[];
  for (final spec in specs) {
    final nameBytes = utf8.encode(spec.path);
    final dataBytes = utf8.encode(spec.content);
    final crc32 = _crc32(dataBytes);
    final localHeader = BytesBuilder(copy: false)
      ..add(_uint32(0x04034b50))
      ..add(_uint16(20))
      ..add(_uint16(0))
      ..add(_uint16(spec.isStored ? 0 : 0))
      ..add(_uint16(0))
      ..add(_uint16(0))
      ..add(_uint32(crc32))
      ..add(_uint32(dataBytes.length))
      ..add(_uint32(dataBytes.length))
      ..add(_uint16(nameBytes.length))
      ..add(_uint16(0))
      ..add(nameBytes);
    final localHeaderBytes = localHeader.takeBytes();
    archive.add(localHeaderBytes);
    archive.add(dataBytes);
    entries.add(
      _StoredZipEntry(
        path: spec.path,
        nameBytes: nameBytes,
        crc32: crc32,
        dataLength: dataBytes.length,
        localHeaderOffset: offset,
      ),
    );
    offset += localHeaderBytes.length + dataBytes.length;
  }
  final centralDirectoryOffset = offset;
  for (final entry in entries) {
    final centralHeader = BytesBuilder(copy: false)
      ..add(_uint32(0x02014b50))
      ..add(_uint16(20))
      ..add(_uint16(20))
      ..add(_uint16(0))
      ..add(_uint16(0))
      ..add(_uint16(0))
      ..add(_uint16(0))
      ..add(_uint32(entry.crc32))
      ..add(_uint32(entry.dataLength))
      ..add(_uint32(entry.dataLength))
      ..add(_uint16(entry.nameBytes.length))
      ..add(_uint16(0))
      ..add(_uint16(0))
      ..add(_uint16(0))
      ..add(_uint16(0))
      ..add(_uint32(0))
      ..add(_uint32(entry.localHeaderOffset))
      ..add(entry.nameBytes);
    final centralHeaderBytes = centralHeader.takeBytes();
    centralDirectory.add(centralHeaderBytes);
    offset += centralHeaderBytes.length;
  }
  final centralDirectoryBytes = centralDirectory.takeBytes();
  final eocd = BytesBuilder(copy: false)
    ..add(_uint32(0x06054b50))
    ..add(_uint16(0))
    ..add(_uint16(0))
    ..add(_uint16(entries.length))
    ..add(_uint16(entries.length))
    ..add(_uint32(centralDirectoryBytes.length))
    ..add(_uint32(centralDirectoryOffset))
    ..add(_uint16(0));
  archive.add(centralDirectoryBytes);
  archive.add(eocd.takeBytes());
  return archive.takeBytes();
}

List<int> _uint16(int value) {
  // 中文注释: ZIP 头字段采用小端 16 位整数，这里单独封装，避免手工位移散落各处。
  return <int>[value & 0xff, (value >> 8) & 0xff];
}

List<int> _uint32(int value) {
  // 中文注释: ZIP 头字段采用小端 32 位整数，这里单独封装，避免 probe 里重复写位运算。
  return <int>[
    value & 0xff,
    (value >> 8) & 0xff,
    (value >> 16) & 0xff,
    (value >> 24) & 0xff,
  ];
}

final List<int> _crcTable = List<int>.generate(256, (index) {
  var crc = index;
  for (var bit = 0; bit < 8; bit += 1) {
    crc = (crc & 1) != 0 ? 0xEDB88320 ^ (crc >> 1) : crc >> 1;
  }
  return crc & 0xffffffff;
});

int _crc32(List<int> bytes) {
  // 中文注释: EPUB fixture 需要标准 CRC32 校验值，这里直接用 lookup table 生成，保持实现简单且可复用。
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xff] ^ (crc >> 8);
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

String _snippet(String text, {int maxLength = 240}) {
  // 中文注释: 报告只保留短摘录，避免把大段探针素材原文直接写进日志。
  final normalized = text.replaceAll('\r\n', '\n').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }
  return '${normalized.substring(0, maxLength)}...';
}

String _reportMarkdown(Map<String, Object?> report) {
  // 中文注释: markdown 报告只负责把 JSON 结果投影成可读摘要，不再重复一遍完整结构。
  final ok = ValueReaders.boolValue(report['ok']);
  final book = ValueReaders.mapValue(report['book_deconstruction']);
  final single = ValueReaders.mapValue(report['single_import']);
  final directory = ValueReaders.mapValue(report['directory_import']);
  final epub = ValueReaders.mapValue(report['epub_reader']);
  final visibility = ValueReaders.mapValue(report['smart_analysis_visibility']);
  final discovery = ValueReaders.mapValue(report['source_discovery']);
  final lines = <String>[
    '# 拆书与导入链高保真验收报告',
    '',
    '- 结果：${ok ? 'PASS' : 'FAIL'}',
    '- 工作区：${ValueReaders.stringValue(report['workspace_root'])}',
    '- 拆书原文归档：${ValueReaders.stringValue(book['archive_path'])}',
    '- 拆书预演：${ValueReaders.stringValue(book['preview_path'])}',
    '- 单文件导入：${ValueReaders.stringList(single['imported_paths']).join(', ')}',
    '- 目录导入：${ValueReaders.stringList(directory['imported_paths']).join(', ')}',
    '- EPUB 读取：${ValueReaders.stringValue(epub['decode_mode'])}',
    '- 智能分析可见性：book=${ValueReaders.boolValue(visibility['book_project_can_smart_analyze'])} / general=${ValueReaders.boolValue(visibility['general_project_can_smart_analyze'])}',
    '- 目录发现：${ValueReaders.intValue(discovery['selection_count'])} 项，跳过 ${ValueReaders.stringList(discovery['skipped_paths']).join(', ')}',
  ];
  if (!ok) {
    lines
      ..add('')
      ..add('- 错误：${ValueReaders.stringValue(report['error'])}');
  }
  return '${lines.join('\n')}\n';
}

void _ensure(bool condition, String message) {
  // 中文注释: probe 的校验失败直接抛出，让测试和命令行报告都能定位到正式合同缺口。
  if (!condition) {
    throw StateError(message);
  }
}

class _FixedBookSourcePickerService
    extends DesktopBookDeconstructionSourcePickerService {
  _FixedBookSourcePickerService(this.selection);

  final String selection;

  @override
  Future<String?> pickSourceFile() async {
    // 中文注释: 测试探针只返回预设路径，不把平台对话框行为带进来。
    return selection;
  }
}

class _ZipEntrySpec {
  const _ZipEntrySpec(this.path, this.content, {this.isStored = false});

  final String path;
  final String content;
  final bool isStored;
}

class _StoredZipEntry {
  const _StoredZipEntry({
    required this.path,
    required this.nameBytes,
    required this.crc32,
    required this.dataLength,
    required this.localHeaderOffset,
  });

  final String path;
  final List<int> nameBytes;
  final int crc32;
  final int dataLength;
  final int localHeaderOffset;
}
