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
    required this.isLoading,
    required this.operationKind,
    required this.buildResult,
    required this.selectedItemIds,
    required this.selectedFollowupOptionId,
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
      isLoading: false,
      operationKind: BookDeconstructionOperationKind.idle,
      buildResult: null,
      selectedItemIds: <String>{},
      selectedFollowupOptionId: '',
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

  final bool isLoading;
  final String operationKind;
  final BookDeconstructionDraftBuildResult? buildResult;
  final Set<String> selectedItemIds;
  final String selectedFollowupOptionId;
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
    bool? isLoading,
    String? operationKind,
    Object? buildResult = _buildResultSentinel,
    Set<String>? selectedItemIds,
    String? selectedFollowupOptionId,
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
      confirmedPreviewPath: confirmedPreviewPath ?? this.confirmedPreviewPath,
    );
  }
}

const Object _buildResultSentinel = Object();
