import 'book_deconstruction_draft_build_result.dart';
import 'book_deconstruction_step_id.dart';

class BookDeconstructionSnapshot {
  const BookDeconstructionSnapshot({
    required this.projectRootPath,
    required this.activeStepId,
    required this.sourceAbsolutePath,
    required this.sourceTitle,
    required this.sourceContent,
    required this.operatorNotes,
    required this.styleSummary,
    required this.worldRulesText,
    required this.characterLinesText,
    required this.organizationLinesText,
    required this.isLoading,
    required this.buildResult,
    required this.selectedItemIds,
    required this.confirmedPreviewPath,
  });

  factory BookDeconstructionSnapshot.initial() {
    return const BookDeconstructionSnapshot(
      projectRootPath: '',
      activeStepId: BookDeconstructionStepId.importSource,
      sourceAbsolutePath: '',
      sourceTitle: '',
      sourceContent: '',
      operatorNotes: '',
      styleSummary: '',
      worldRulesText: '',
      characterLinesText: '',
      organizationLinesText: '',
      isLoading: false,
      buildResult: null,
      selectedItemIds: <String>{},
      confirmedPreviewPath: '',
    );
  }

  final String projectRootPath;
  final String activeStepId;
  final String sourceAbsolutePath;
  final String sourceTitle;
  final String sourceContent;
  final String operatorNotes;
  final String styleSummary;
  final String worldRulesText;
  final String characterLinesText;
  final String organizationLinesText;
  final bool isLoading;
  final BookDeconstructionDraftBuildResult? buildResult;
  final Set<String> selectedItemIds;
  final String confirmedPreviewPath;

  BookDeconstructionSnapshot copyWith({
    String? projectRootPath,
    String? activeStepId,
    String? sourceAbsolutePath,
    String? sourceTitle,
    String? sourceContent,
    String? operatorNotes,
    String? styleSummary,
    String? worldRulesText,
    String? characterLinesText,
    String? organizationLinesText,
    bool? isLoading,
    Object? buildResult = _buildResultSentinel,
    Set<String>? selectedItemIds,
    String? confirmedPreviewPath,
  }) {
    // 中文注释: 拆书向导快照集中保存表单与预览状态，避免页面层自己维护多份临时副本。
    return BookDeconstructionSnapshot(
      projectRootPath: projectRootPath ?? this.projectRootPath,
      activeStepId: activeStepId ?? this.activeStepId,
      sourceAbsolutePath: sourceAbsolutePath ?? this.sourceAbsolutePath,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceContent: sourceContent ?? this.sourceContent,
      operatorNotes: operatorNotes ?? this.operatorNotes,
      styleSummary: styleSummary ?? this.styleSummary,
      worldRulesText: worldRulesText ?? this.worldRulesText,
      characterLinesText: characterLinesText ?? this.characterLinesText,
      organizationLinesText:
          organizationLinesText ?? this.organizationLinesText,
      isLoading: isLoading ?? this.isLoading,
      buildResult: identical(buildResult, _buildResultSentinel)
          ? this.buildResult
          : buildResult as BookDeconstructionDraftBuildResult?,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      confirmedPreviewPath: confirmedPreviewPath ?? this.confirmedPreviewPath,
    );
  }
}

const Object _buildResultSentinel = Object();
