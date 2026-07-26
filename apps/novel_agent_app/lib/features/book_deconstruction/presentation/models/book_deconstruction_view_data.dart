import '../../application/models/book_deconstruction_operation_kind.dart';
import '../../../workbench/presentation/models/selector_option_view_data.dart';
import 'book_deconstruction_plan_group_view_data.dart';
import 'book_deconstruction_continuity_view_data.dart';
import 'book_deconstruction_preview_section_view_data.dart';
import 'book_deconstruction_step_view_data.dart';

class BookDeconstructionViewData {
  const BookDeconstructionViewData({
    required this.projectTitle,
    required this.status,
    required this.isLoading,
    required this.operationKind,
    required this.activeStepId,
    required this.steps,
    required this.sourceAbsolutePath,
    required this.sourceTitle,
    required this.sourceContent,
    required this.previewSections,
    required this.planGroups,
    required this.selectedItemCount,
    required this.totalItemCount,
    required this.selectedFollowupOptionId,
    required this.selectedTargetWritingTypeId,
    required this.targetWritingTypeOptions,
    required this.selectedTargetRuntimeBaselineId,
    required this.targetRuntimeBaselineOptions,
    this.canSelectTargetRuntimeBaseline = true,
    required this.inheritAsLiveNarrative,
    required this.confirmedPreviewPath,
    required this.canConfirmSelection,
    required this.canCreateDerivedProject,
    required this.importActionLabel,
    required this.canSplit,
    required this.splitUseModel,
    required this.splitModelOptionKey,
    required this.splitModelOptions,
    required this.canUseSplitModel,
    required this.canAnalyze,
    required this.analysisUseModel,
    required this.analysisModelOptionKey,
    required this.analysisModelOptions,
    required this.analysisStatusMessage,
    required this.analysisCompleted,
    this.analysisStagingRunId = '',
    this.analysisStagingPackageId = '',
    this.analysisStagingPackageVersionId = '',
    this.applyStagedAnalysisResults = false,
    this.hasStagedAnalysis = false,
    this.continuity,
  });

  factory BookDeconstructionViewData.initial() {
    return const BookDeconstructionViewData(
      projectTitle: '',
      status: '',
      isLoading: false,
      operationKind: '',
      activeStepId: '',
      steps: <BookDeconstructionStepViewData>[],
      sourceAbsolutePath: '',
      sourceTitle: '',
      sourceContent: '',
      previewSections: <BookDeconstructionPreviewSectionViewData>[],
      planGroups: <BookDeconstructionPlanGroupViewData>[],
      selectedItemCount: 0,
      totalItemCount: 0,
      selectedFollowupOptionId: '',
      selectedTargetWritingTypeId: '',
      targetWritingTypeOptions: <SelectorOptionViewData>[],
      selectedTargetRuntimeBaselineId: '',
      targetRuntimeBaselineOptions: <SelectorOptionViewData>[],
      inheritAsLiveNarrative: false,
      confirmedPreviewPath: '',
      canConfirmSelection: false,
      canCreateDerivedProject: false,
      importActionLabel: '选择文件…',
      canSplit: false,
      splitUseModel: false,
      splitModelOptionKey: '',
      splitModelOptions: <SelectorOptionViewData>[],
      canUseSplitModel: false,
      canAnalyze: false,
      analysisUseModel: false,
      analysisModelOptionKey: '',
      analysisModelOptions: <SelectorOptionViewData>[],
      analysisStatusMessage: '',
      analysisCompleted: false,
      analysisStagingRunId: '',
      analysisStagingPackageId: '',
      analysisStagingPackageVersionId: '',
      applyStagedAnalysisResults: false,
      hasStagedAnalysis: false,
      continuity: null,
    );
  }

  final String projectTitle;
  final String status;
  final bool isLoading;
  final String operationKind;
  final String activeStepId;
  final List<BookDeconstructionStepViewData> steps;

  // 步骤①：导入
  final String sourceAbsolutePath;
  final String sourceTitle;
  final String sourceContent;
  final String importActionLabel;

  // 步骤②：拆书（纯净分章）——可选使用模型；模型与分析步独立不继承。
  final bool canSplit;
  final bool splitUseModel;
  final String splitModelOptionKey;
  final List<SelectorOptionViewData> splitModelOptions;
  final bool canUseSplitModel;
  // 拆书结果（只含分章；previewSections 在纯分章模式下仅渲染章节）。
  final List<BookDeconstructionPreviewSectionViewData> previewSections;
  final List<BookDeconstructionPlanGroupViewData> planGroups;
  final int selectedItemCount;
  final int totalItemCount;

  // 步骤③：分析（可选·需选模型；不选模型则跳过——本地分析质量过低）。
  final bool canAnalyze;
  final bool analysisUseModel;
  final String analysisModelOptionKey;
  final List<SelectorOptionViewData> analysisModelOptions;
  final String analysisStatusMessage;
  final bool analysisCompleted;
  final String analysisStagingRunId;
  final String analysisStagingPackageId;
  final String analysisStagingPackageVersionId;
  final bool applyStagedAnalysisResults;
  final bool hasStagedAnalysis;

  // 步骤④：确认（复合项目类型——选目标写作类型 + 续写开关）。
  final String selectedFollowupOptionId;
  final String selectedTargetWritingTypeId;
  final List<SelectorOptionViewData> targetWritingTypeOptions;
  final String selectedTargetRuntimeBaselineId;
  final List<SelectorOptionViewData> targetRuntimeBaselineOptions;
  final bool canSelectTargetRuntimeBaseline;
  final bool inheritAsLiveNarrative;
  final String confirmedPreviewPath;
  final bool canConfirmSelection;
  final bool canCreateDerivedProject;

  final BookDeconstructionContinuityViewData? continuity;

  /// Confirmation and derived-project creation have started durable writes.
  /// UI controls must not mutate the selected payload or cancel the commit.
  bool get isCommitInProgress {
    return operationKind ==
            BookDeconstructionOperationKind.confirmingSelection ||
        operationKind == BookDeconstructionOperationKind.creatingDerivedProject;
  }

  BookDeconstructionViewData copyWith({
    String? projectTitle,
    String? status,
    bool? isLoading,
    String? operationKind,
    String? activeStepId,
    List<BookDeconstructionStepViewData>? steps,
    String? sourceAbsolutePath,
    String? sourceTitle,
    String? sourceContent,
    String? importActionLabel,
    bool? canSplit,
    bool? splitUseModel,
    String? splitModelOptionKey,
    List<SelectorOptionViewData>? splitModelOptions,
    bool? canUseSplitModel,
    List<BookDeconstructionPreviewSectionViewData>? previewSections,
    List<BookDeconstructionPlanGroupViewData>? planGroups,
    int? selectedItemCount,
    int? totalItemCount,
    bool? canAnalyze,
    bool? analysisUseModel,
    String? analysisModelOptionKey,
    List<SelectorOptionViewData>? analysisModelOptions,
    String? analysisStatusMessage,
    bool? analysisCompleted,
    String? analysisStagingRunId,
    String? analysisStagingPackageId,
    String? analysisStagingPackageVersionId,
    bool? applyStagedAnalysisResults,
    bool? hasStagedAnalysis,
    String? selectedFollowupOptionId,
    String? selectedTargetWritingTypeId,
    List<SelectorOptionViewData>? targetWritingTypeOptions,
    String? selectedTargetRuntimeBaselineId,
    List<SelectorOptionViewData>? targetRuntimeBaselineOptions,
    bool? canSelectTargetRuntimeBaseline,
    bool? inheritAsLiveNarrative,
    String? confirmedPreviewPath,
    bool? canConfirmSelection,
    bool? canCreateDerivedProject,
    BookDeconstructionContinuityViewData? continuity,
  }) {
    return BookDeconstructionViewData(
      projectTitle: projectTitle ?? this.projectTitle,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      operationKind: operationKind ?? this.operationKind,
      activeStepId: activeStepId ?? this.activeStepId,
      steps: steps ?? this.steps,
      sourceAbsolutePath: sourceAbsolutePath ?? this.sourceAbsolutePath,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceContent: sourceContent ?? this.sourceContent,
      importActionLabel: importActionLabel ?? this.importActionLabel,
      canSplit: canSplit ?? this.canSplit,
      splitUseModel: splitUseModel ?? this.splitUseModel,
      splitModelOptionKey: splitModelOptionKey ?? this.splitModelOptionKey,
      splitModelOptions: splitModelOptions ?? this.splitModelOptions,
      canUseSplitModel: canUseSplitModel ?? this.canUseSplitModel,
      previewSections: previewSections ?? this.previewSections,
      planGroups: planGroups ?? this.planGroups,
      selectedItemCount: selectedItemCount ?? this.selectedItemCount,
      totalItemCount: totalItemCount ?? this.totalItemCount,
      canAnalyze: canAnalyze ?? this.canAnalyze,
      analysisUseModel: analysisUseModel ?? this.analysisUseModel,
      analysisModelOptionKey:
          analysisModelOptionKey ?? this.analysisModelOptionKey,
      analysisModelOptions: analysisModelOptions ?? this.analysisModelOptions,
      analysisStatusMessage:
          analysisStatusMessage ?? this.analysisStatusMessage,
      analysisCompleted: analysisCompleted ?? this.analysisCompleted,
      analysisStagingRunId: analysisStagingRunId ?? this.analysisStagingRunId,
      analysisStagingPackageId:
          analysisStagingPackageId ?? this.analysisStagingPackageId,
      analysisStagingPackageVersionId:
          analysisStagingPackageVersionId ??
          this.analysisStagingPackageVersionId,
      applyStagedAnalysisResults:
          applyStagedAnalysisResults ?? this.applyStagedAnalysisResults,
      hasStagedAnalysis: hasStagedAnalysis ?? this.hasStagedAnalysis,
      selectedFollowupOptionId:
          selectedFollowupOptionId ?? this.selectedFollowupOptionId,
      selectedTargetWritingTypeId:
          selectedTargetWritingTypeId ?? this.selectedTargetWritingTypeId,
      targetWritingTypeOptions:
          targetWritingTypeOptions ?? this.targetWritingTypeOptions,
      selectedTargetRuntimeBaselineId:
          selectedTargetRuntimeBaselineId ??
          this.selectedTargetRuntimeBaselineId,
      targetRuntimeBaselineOptions:
          targetRuntimeBaselineOptions ?? this.targetRuntimeBaselineOptions,
      canSelectTargetRuntimeBaseline:
          canSelectTargetRuntimeBaseline ?? this.canSelectTargetRuntimeBaseline,
      inheritAsLiveNarrative:
          inheritAsLiveNarrative ?? this.inheritAsLiveNarrative,
      confirmedPreviewPath: confirmedPreviewPath ?? this.confirmedPreviewPath,
      canConfirmSelection: canConfirmSelection ?? this.canConfirmSelection,
      canCreateDerivedProject:
          canCreateDerivedProject ?? this.canCreateDerivedProject,
      continuity: continuity ?? this.continuity,
    );
  }
}
