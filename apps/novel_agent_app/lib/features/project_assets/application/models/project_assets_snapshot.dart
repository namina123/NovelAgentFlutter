import 'project_assets_catalog.dart';
import 'project_assets_tab_id.dart';
import '../../presentation/models/project_assets_view_data.dart';
import 'project_rag_extraction_snapshot.dart';

class ProjectAssetsSnapshot {
  const ProjectAssetsSnapshot({
    required this.activeTabId,
    required this.selectedStyleId,
    required this.selectedExpressionConstraintId,
    required this.selectedForeshadowId,
    required this.selectedTimelineId,
    required this.selectedRelationshipId,
    required this.selectedGraphReferenceKey,
    required this.selectedReferenceExtractionStrategyId,
    required this.ragExtraction,
    required this.entryAgentContextId,
    required this.availableAgentOptions,
    required this.availableModeOptions,
    required this.availableStageOptions,
    required this.catalog,
    required this.isLoading,
  });

  final String activeTabId;
  final String selectedStyleId;
  final String selectedExpressionConstraintId;
  final String selectedForeshadowId;
  final String selectedTimelineId;
  final String selectedRelationshipId;
  final String selectedGraphReferenceKey;
  final String selectedReferenceExtractionStrategyId;
  final ProjectRagExtractionSnapshot ragExtraction;
  final String entryAgentContextId;
  final List<ExpressionConstraintSelectableOptionViewData>
  availableAgentOptions;
  final List<ExpressionConstraintSelectableOptionViewData> availableModeOptions;
  final List<ExpressionConstraintSelectableOptionViewData>
  availableStageOptions;
  final ProjectAssetsCatalog catalog;
  final bool isLoading;

  factory ProjectAssetsSnapshot.initial() {
    return ProjectAssetsSnapshot(
      activeTabId: ProjectAssetsTabId.styles,
      selectedStyleId: '',
      selectedExpressionConstraintId: '',
      selectedForeshadowId: '',
      selectedTimelineId: '',
      selectedRelationshipId: '',
      selectedGraphReferenceKey: '',
      selectedReferenceExtractionStrategyId: '',
      ragExtraction: ProjectRagExtractionSnapshot.initial(),
      entryAgentContextId: '',
      availableAgentOptions: <ExpressionConstraintSelectableOptionViewData>[],
      availableModeOptions: <ExpressionConstraintSelectableOptionViewData>[],
      availableStageOptions: <ExpressionConstraintSelectableOptionViewData>[],
      catalog: ProjectAssetsCatalog(),
      isLoading: false,
    );
  }

  ProjectAssetsSnapshot copyWith({
    String? activeTabId,
    String? selectedStyleId,
    String? selectedExpressionConstraintId,
    String? selectedForeshadowId,
    String? selectedTimelineId,
    String? selectedRelationshipId,
    String? selectedGraphReferenceKey,
    String? selectedReferenceExtractionStrategyId,
    ProjectRagExtractionSnapshot? ragExtraction,
    String? entryAgentContextId,
    List<ExpressionConstraintSelectableOptionViewData>? availableAgentOptions,
    List<ExpressionConstraintSelectableOptionViewData>? availableModeOptions,
    List<ExpressionConstraintSelectableOptionViewData>? availableStageOptions,
    ProjectAssetsCatalog? catalog,
    bool? isLoading,
  }) {
    // 中文注释: 资产快照只保存读侧原始资产和选择状态，具体展示投影交给 view data service。
    return ProjectAssetsSnapshot(
      activeTabId: activeTabId ?? this.activeTabId,
      selectedStyleId: selectedStyleId ?? this.selectedStyleId,
      selectedExpressionConstraintId:
          selectedExpressionConstraintId ?? this.selectedExpressionConstraintId,
      selectedForeshadowId: selectedForeshadowId ?? this.selectedForeshadowId,
      selectedTimelineId: selectedTimelineId ?? this.selectedTimelineId,
      selectedRelationshipId:
          selectedRelationshipId ?? this.selectedRelationshipId,
      selectedGraphReferenceKey:
          selectedGraphReferenceKey ?? this.selectedGraphReferenceKey,
      selectedReferenceExtractionStrategyId:
          selectedReferenceExtractionStrategyId ??
          this.selectedReferenceExtractionStrategyId,
      ragExtraction: ragExtraction ?? this.ragExtraction,
      entryAgentContextId: entryAgentContextId ?? this.entryAgentContextId,
      availableAgentOptions:
          availableAgentOptions ?? this.availableAgentOptions,
      availableModeOptions: availableModeOptions ?? this.availableModeOptions,
      availableStageOptions:
          availableStageOptions ?? this.availableStageOptions,
      catalog: catalog ?? this.catalog,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
