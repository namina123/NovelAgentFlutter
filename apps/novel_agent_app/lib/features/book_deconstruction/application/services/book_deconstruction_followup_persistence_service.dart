import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_followup_documents_service.dart';
import 'book_deconstruction_followup_option_selection_service.dart';

class BookDeconstructionFollowupPersistenceService {
  BookDeconstructionFollowupPersistenceService({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    BookDeconstructionDerivedProjectPlanBuilderService? planBuilderService,
    BookDeconstructionTargetPathService? targetPathService,
    BookDeconstructionFollowupDocumentsService? documentsService,
    BookDeconstructionFollowupOptionSelectionService? optionSelectionService,
    ReferenceSourceDocumentStructureService? structureService,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _planBuilderService =
           planBuilderService ??
           const BookDeconstructionDerivedProjectPlanBuilderService(),
       _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService(),
       _documentsService =
           documentsService ??
           const BookDeconstructionFollowupDocumentsService(),
       _optionSelectionService =
           optionSelectionService ??
           const BookDeconstructionFollowupOptionSelectionService(),
       _structureService =
           structureService ?? const ReferenceSourceDocumentStructureService();

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final BookDeconstructionDerivedProjectPlanBuilderService _planBuilderService;
  final BookDeconstructionTargetPathService _targetPathService;
  final BookDeconstructionFollowupDocumentsService _documentsService;
  final BookDeconstructionFollowupOptionSelectionService
  _optionSelectionService;
  final ReferenceSourceDocumentStructureService _structureService;

  Future<BookDeconstructionFollowupPersistenceResult> persist({
    required ProjectDescriptor project,
    required BookDeconstructionDraftBuildResult buildResult,
    required String followupOptionId,
    bool writeBodyAsLiveNarrative = false,
  }) async {
    final option = _optionSelectionService.optionById(
      followupMenu: buildResult.followupMenu,
      optionId: followupOptionId,
    );
    if (option == null) {
      throw StateError('未找到拆书后续路线：$followupOptionId');
    }
    final plan = _planBuilderService.build(
      input: buildResult.input,
      followupMenu: buildResult.followupMenu,
      followupOptionId: option.id,
      narrativeArtifacts: buildResult.narrativeArtifacts,
    );
    final planPath = _targetPathService.followupPlanPath(option.id);
    final guidePath = _targetPathService.followupGuidePath(option.id);
    final inheritedRootPath = 'chapters/inherited/${_safeId(option.id)}';
    final planJson = _documentsService.renderPlanJson(
      plan: plan,
      option: option,
      buildResult: buildResult,
    );
    final guideMarkdown = _documentsService.renderGuideMarkdown(
      plan: plan,
      option: option,
      buildResult: buildResult,
      inheritedChapterRootPath: inheritedRootPath,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: planPath,
      content: planJson,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: guidePath,
      content: guideMarkdown,
    );

    // 中文注释: 续写路线（sourceInheritanceMode==continuation）下：
    // - 派生项目创建（writeBodyAsLiveNarrative=true）：把分好的正文写进正文区域 chapters/，续写在其后接写。
    // - 拆书项目确认（默认 false）：仍写 inherited/ 镜像（分析产物），不打扰正文层。
    // 同人路线（fanfic）按设计不继承正文，保持原行为。
    final inheritsBody =
        option.sourceInheritanceMode ==
            BookDeconstructionSourceInheritanceMode.continuation;
    final inheritedChapterPaths = inheritsBody
        ? await _persistInheritedChapters(
            project: project,
            followupOptionId: option.id,
            buildResult: buildResult,
            asLiveNarrative: writeBodyAsLiveNarrative,
          )
        : const <String>[];
    return BookDeconstructionFollowupPersistenceResult(
      plan: plan,
      option: option,
      planPath: planPath,
      guidePath: guidePath,
      inheritedChapterPaths: inheritedChapterPaths,
    );
  }

  Future<List<String>> _persistInheritedChapters({
    required ProjectDescriptor project,
    required String followupOptionId,
    required BookDeconstructionDraftBuildResult buildResult,
    required bool asLiveNarrative,
  }) async {
    final sourceContent = buildResult.input.sourceDocuments.isEmpty
        ? ''
        : buildResult.input.sourceDocuments.first.content;
    if (sourceContent.trim().isEmpty) {
      return const <String>[];
    }
    final structure = _structureService.analyze(sourceContent);
    final sections = structure.sections;
    if (sections.isEmpty) {
      return const <String>[];
    }
    final changedPaths = <String>[];
    for (final section in sections) {
      final title = section.heading.trim().isEmpty
          ? '原作片段 ${section.sectionIndex}'
          : section.heading.trim();
      // 中文注释: asLiveNarrative=true 走正文区域（chapters/第N章），否则走 inherited/ 镜像。
      final relativePath = asLiveNarrative
          ? _targetPathService.liveChapterPath(
              sequence: section.sectionIndex,
              title: title,
              storageStrategy: project.storageStrategy,
            )
          : _targetPathService.inheritedChapterPath(
              followupOptionId: followupOptionId,
              sequence: section.sectionIndex,
              title: title,
              storageStrategy: project.storageStrategy,
            );
      final buffer = StringBuffer()..writeln(title);
      if (section.content.trim().isNotEmpty) {
        buffer
          ..writeln()
          ..write(section.content.trim());
      }
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: relativePath,
        content: buffer.toString().trimRight(),
      );
      changedPaths.add(relativePath);
    }
    return changedPaths;
  }

  String _safeId(String value) {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) {
      return 'followup';
    }
    return cleanValue
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

class BookDeconstructionFollowupPersistenceResult {
  const BookDeconstructionFollowupPersistenceResult({
    required this.plan,
    required this.option,
    required this.planPath,
    required this.guidePath,
    required this.inheritedChapterPaths,
  });

  final BookDeconstructionDerivedProjectPlan plan;
  final BookDeconstructionFollowupOption option;
  final String planPath;
  final String guidePath;
  final List<String> inheritedChapterPaths;
}
