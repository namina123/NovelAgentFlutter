import 'package:novel_agent_core/novel_agent_core.dart';
import 'book_deconstruction_operation_kind.dart';
import 'book_deconstruction_step_id.dart';

class BookDeconstructionSnapshot {
  const BookDeconstructionSnapshot({
    required this.projectRootPath,
    required this.activeStepId,
    required this.sourceAbsolutePath,
    required this.sourceTitle,
    required this.sourceContent,
    required this.splitUseModel,
    required this.splitModelOptionKey,
    required this.analysisUseModel,
    required this.analysisModelOptionKey,
    required this.analysisCompleted,
    required this.analysisStatusMessage,
    this.analysisStagingRunId = '',
    this.analysisStagingPackageId = '',
    this.analysisStagingPackageVersionId = '',
    this.applyStagedAnalysisResults = false,
    required this.structuredSourceProjectionReady,
    required this.isLoading,
    required this.operationKind,
    required this.buildResult,
    required this.selectedItemIds,
    required this.selectedFollowupOptionId,
    required this.selectedTargetWritingTypeId,
    required this.selectedTargetRuntimeBaselineId,
    required this.inheritAsLiveNarrative,
    required this.confirmedPreviewPath,
  });

  factory BookDeconstructionSnapshot.initial() {
    return const BookDeconstructionSnapshot(
      projectRootPath: '',
      activeStepId: BookDeconstructionStepId.importSource,
      sourceAbsolutePath: '',
      sourceTitle: '',
      sourceContent: '',
      splitUseModel: false,
      splitModelOptionKey: '',
      analysisUseModel: false,
      analysisModelOptionKey: '',
      analysisCompleted: false,
      analysisStatusMessage: '',
      analysisStagingRunId: '',
      analysisStagingPackageId: '',
      analysisStagingPackageVersionId: '',
      applyStagedAnalysisResults: false,
      structuredSourceProjectionReady: false,
      isLoading: false,
      operationKind: BookDeconstructionOperationKind.idle,
      buildResult: null,
      selectedItemIds: <String>{},
      selectedFollowupOptionId: '',
      selectedTargetWritingTypeId: '',
      selectedTargetRuntimeBaselineId: '',
      inheritAsLiveNarrative: false,
      confirmedPreviewPath: '',
    );
  }

  final String projectRootPath;
  final String activeStepId;
  final String sourceAbsolutePath;
  final String sourceTitle;
  final String sourceContent;
  // 中文注释: 拆书步的"使用模型"开关与所选模型键（"providerId::modelId"）；与"分析"步独立。
  final bool splitUseModel;
  final String splitModelOptionKey;
  // 中文注释: 分析步的"使用模型"开关与所选模型键；模型不继承自拆书步。未选模型则不分析。
  final bool analysisUseModel;
  final String analysisModelOptionKey;
  final bool analysisCompleted;
  final String analysisStatusMessage;

  /// Exact identities produced by the optional analysis run. They are only
  /// mounted when `applyStagedAnalysisResults` is explicitly enabled at
  /// confirmation time.
  final String analysisStagingRunId;
  final String analysisStagingPackageId;
  final String analysisStagingPackageVersionId;
  final bool applyStagedAnalysisResults;
  final bool structuredSourceProjectionReady;

  final bool isLoading;
  final String operationKind;
  final BookDeconstructionDraftBuildResult? buildResult;
  final Set<String> selectedItemIds;
  final String selectedFollowupOptionId;
  // 中文注释: 复合项目类型——第④步选的目标写作类型（novel/long_novel）+ 是否把分章作为续写正文基础。
  final String selectedTargetWritingTypeId;
  final String selectedTargetRuntimeBaselineId;
  final bool inheritAsLiveNarrative;
  final String confirmedPreviewPath;

  BookDeconstructionSnapshot copyWith({
    String? projectRootPath,
    String? activeStepId,
    String? sourceAbsolutePath,
    String? sourceTitle,
    String? sourceContent,
    bool? splitUseModel,
    String? splitModelOptionKey,
    bool? analysisUseModel,
    String? analysisModelOptionKey,
    bool? analysisCompleted,
    String? analysisStatusMessage,
    String? analysisStagingRunId,
    String? analysisStagingPackageId,
    String? analysisStagingPackageVersionId,
    bool? applyStagedAnalysisResults,
    bool? structuredSourceProjectionReady,
    bool? isLoading,
    String? operationKind,
    Object? buildResult = _buildResultSentinel,
    Set<String>? selectedItemIds,
    String? selectedFollowupOptionId,
    String? selectedTargetWritingTypeId,
    String? selectedTargetRuntimeBaselineId,
    bool? inheritAsLiveNarrative,
    String? confirmedPreviewPath,
  }) {
    // 中文注释: 拆书向导快照集中保存表单与预览状态，避免页面层自己维护多份临时副本。
    return BookDeconstructionSnapshot(
      projectRootPath: projectRootPath ?? this.projectRootPath,
      activeStepId: activeStepId ?? this.activeStepId,
      sourceAbsolutePath: sourceAbsolutePath ?? this.sourceAbsolutePath,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceContent: sourceContent ?? this.sourceContent,
      splitUseModel: splitUseModel ?? this.splitUseModel,
      splitModelOptionKey: splitModelOptionKey ?? this.splitModelOptionKey,
      analysisUseModel: analysisUseModel ?? this.analysisUseModel,
      analysisModelOptionKey:
          analysisModelOptionKey ?? this.analysisModelOptionKey,
      analysisCompleted: analysisCompleted ?? this.analysisCompleted,
      analysisStatusMessage:
          analysisStatusMessage ?? this.analysisStatusMessage,
      analysisStagingRunId: analysisStagingRunId ?? this.analysisStagingRunId,
      analysisStagingPackageId:
          analysisStagingPackageId ?? this.analysisStagingPackageId,
      analysisStagingPackageVersionId:
          analysisStagingPackageVersionId ??
          this.analysisStagingPackageVersionId,
      applyStagedAnalysisResults:
          applyStagedAnalysisResults ?? this.applyStagedAnalysisResults,
      structuredSourceProjectionReady:
          structuredSourceProjectionReady ??
          this.structuredSourceProjectionReady,
      isLoading: isLoading ?? this.isLoading,
      operationKind: operationKind == null
          ? this.operationKind
          : BookDeconstructionOperationKind.normalize(operationKind),
      buildResult: identical(buildResult, _buildResultSentinel)
          ? this.buildResult
          : buildResult as BookDeconstructionDraftBuildResult?,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      selectedFollowupOptionId:
          selectedFollowupOptionId ?? this.selectedFollowupOptionId,
      selectedTargetWritingTypeId:
          selectedTargetWritingTypeId ?? this.selectedTargetWritingTypeId,
      selectedTargetRuntimeBaselineId:
          selectedTargetRuntimeBaselineId ??
          this.selectedTargetRuntimeBaselineId,
      inheritAsLiveNarrative:
          inheritAsLiveNarrative ?? this.inheritAsLiveNarrative,
      confirmedPreviewPath: confirmedPreviewPath ?? this.confirmedPreviewPath,
    );
  }
}

const Object _buildResultSentinel = Object();
