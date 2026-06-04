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
    ProjectImportActionPolicyService? actionPolicyService,
    BookDeconstructionDraftBuilderService? draftBuilderService,
    BookDeconstructionPreviewMarkdownService? previewMarkdownService,
  }) : _importProjectFilesUseCase = importProjectFilesUseCase,
       _projectToolHostPort = projectToolHostPort,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _narrativePersistenceService = narrativePersistenceService,
       _actionPolicyService =
           actionPolicyService ?? ProjectImportActionPolicyService(),
       _draftBuilderService =
           draftBuilderService ?? BookDeconstructionDraftBuilderService(),
       _previewMarkdownService =
           previewMarkdownService ??
           const BookDeconstructionPreviewMarkdownService();

  final ImportProjectFilesUseCase _importProjectFilesUseCase;
  final ProjectToolHostPort _projectToolHostPort;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final BookDeconstructionNarrativePersistenceService
  _narrativePersistenceService;
  final ProjectImportActionPolicyService _actionPolicyService;
  final BookDeconstructionDraftBuilderService _draftBuilderService;
  final BookDeconstructionPreviewMarkdownService _previewMarkdownService;

  Future<ProjectImportExecutionResult> execute({
    required ProjectDescriptor project,
    required ProjectImportRequest request,
  }) async {
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
    if (!request.autoDeconstruct || !importOk) {
      return ProjectImportExecutionResult(
        ok: importOk,
        summary: baseSummary,
        importedPaths: importedPaths,
        skippedPaths: skippedPaths,
        autoDeconstructionApplied: false,
        autoDeconstructionPreviewPath: '',
      );
    }
    final policy = _actionPolicyService.build(
      projectType: project.projectType,
      sourcePaths: request.sourcePaths,
      requestedTargetDirectory: request.targetDirectory,
      requestedAutoDeconstruct: request.autoDeconstruct,
    );
    if (!policy.canAutoDeconstruct) {
      return ProjectImportExecutionResult(
        ok: importOk,
        summary: '$baseSummary ${policy.outputHint}',
        importedPaths: importedPaths,
        skippedPaths: skippedPaths,
        autoDeconstructionApplied: false,
        autoDeconstructionPreviewPath: '',
      );
    }
    final sourcePath = request.sourcePaths.single.trim();
    final sourceContent =
        await _projectToolHostPort.readExternalTextFile(sourcePath) ?? '';
    if (sourceContent.trim().isEmpty) {
      return ProjectImportExecutionResult(
        ok: importOk,
        summary: '$baseSummary 自动拆书失败：所选文件不可读取或内容为空。',
        importedPaths: importedPaths,
        skippedPaths: skippedPaths,
        autoDeconstructionApplied: false,
        autoDeconstructionPreviewPath: '',
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
    return ProjectImportExecutionResult(
      ok: importOk,
      summary: '$baseSummary 自动拆书预演纪要已写入 $previewPath。',
      importedPaths: importedPaths,
      skippedPaths: skippedPaths,
      autoDeconstructionApplied: true,
      autoDeconstructionPreviewPath: previewPath,
    );
  }
}
