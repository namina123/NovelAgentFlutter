import 'project_reference_extraction_strategy_picker_view_data.dart';
import 'project_rag_extraction_view_data.dart';

class ProjectAssetsViewData {
  const ProjectAssetsViewData({
    required this.title,
    required this.description,
    required this.status,
    required this.useDedicatedRagWorkspace,
    required this.activeTabId,
    required this.entryAgentContextId,
    required this.tabs,
    required this.entries,
    required this.inspector,
    required this.timeline,
    required this.graph,
    required this.styleEditor,
    required this.expressionConstraintEditor,
    required this.foreshadowEditor,
    required this.referenceExtractionStrategyPicker,
    required this.ragExtraction,
    required this.isLoading,
  });

  final String title;
  final String description;
  final String status;
  final bool useDedicatedRagWorkspace;
  final String activeTabId;
  final String entryAgentContextId;
  final List<ProjectAssetsTabViewData> tabs;
  final List<ProjectAssetEntryViewData> entries;
  final ProjectAssetsInspectorViewData inspector;
  final ProjectAssetsTimelineViewData timeline;
  final ProjectAssetsGraphViewData graph;
  final StyleProfileEditorViewData styleEditor;
  final ExpressionConstraintBindingEditorViewData expressionConstraintEditor;
  final ForeshadowRecordEditorViewData foreshadowEditor;
  final ProjectReferenceExtractionStrategyPickerViewData
  referenceExtractionStrategyPicker;
  final ProjectRagExtractionViewData ragExtraction;
  final bool isLoading;

  factory ProjectAssetsViewData.initial() {
    return ProjectAssetsViewData(
      title: '项目资产',
      description: '集中管理知识提取结果、风格、表达限制、伏笔与项目资产包。',
      status: '',
      useDedicatedRagWorkspace: false,
      activeTabId: 'styles',
      entryAgentContextId: '',
      tabs: const <ProjectAssetsTabViewData>[
        ProjectAssetsTabViewData(id: 'reference_extraction', label: '知识提取'),
        ProjectAssetsTabViewData(id: 'styles', label: '风格'),
        ProjectAssetsTabViewData(id: 'expression_constraints', label: '表达限制'),
        ProjectAssetsTabViewData(id: 'rag_extraction', label: '语料提取'),
        ProjectAssetsTabViewData(id: 'foreshadows', label: '伏笔'),
        ProjectAssetsTabViewData(id: 'timelines', label: '时间线'),
        ProjectAssetsTabViewData(id: 'relationships', label: '关系'),
        ProjectAssetsTabViewData(id: 'graph', label: '图谱'),
      ],
      entries: const <ProjectAssetEntryViewData>[],
      inspector: ProjectAssetsInspectorViewData.empty(),
      timeline: ProjectAssetsTimelineViewData.empty(),
      graph: ProjectAssetsGraphViewData.empty(),
      styleEditor: StyleProfileEditorViewData.empty(),
      expressionConstraintEditor:
          ExpressionConstraintBindingEditorViewData.empty(),
      foreshadowEditor: ForeshadowRecordEditorViewData.empty(),
      referenceExtractionStrategyPicker:
          ProjectReferenceExtractionStrategyPickerViewData.empty(),
      ragExtraction: ProjectRagExtractionViewData.empty(),
      isLoading: false,
    );
  }
}

class ProjectAssetsTabViewData {
  const ProjectAssetsTabViewData({required this.id, required this.label});

  final String id;
  final String label;
}

class ProjectAssetEntryViewData {
  const ProjectAssetEntryViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.relativePath,
    required this.meta,
    required this.isSelected,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String relativePath;
  final String meta;
  final bool isSelected;
}

class ProjectAssetsInspectorViewData {
  const ProjectAssetsInspectorViewData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.sourcePath,
    required this.sections,
    required this.relatedAssets,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String sourcePath;
  final List<ProjectAssetsInspectorSectionViewData> sections;
  final List<ProjectAssetsRelatedAssetViewData> relatedAssets;
  final String emptyMessage;

  factory ProjectAssetsInspectorViewData.empty() {
    return const ProjectAssetsInspectorViewData(
      title: '',
      subtitle: '',
      badge: '',
      sourcePath: '',
      sections: <ProjectAssetsInspectorSectionViewData>[],
      relatedAssets: <ProjectAssetsRelatedAssetViewData>[],
      emptyMessage: '当前没有可浏览的资产内容。',
    );
  }
}

class ProjectAssetsInspectorSectionViewData {
  const ProjectAssetsInspectorSectionViewData({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;
}

class ProjectAssetsRelatedAssetViewData {
  const ProjectAssetsRelatedAssetViewData({
    required this.referenceKey,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.isSelected,
  });

  final String referenceKey;
  final String title;
  final String badge;
  final String subtitle;
  final bool isSelected;
}

class ProjectAssetsTimelineViewData {
  const ProjectAssetsTimelineViewData({
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<ProjectAssetsTimelineItemViewData> items;

  factory ProjectAssetsTimelineViewData.empty() {
    return const ProjectAssetsTimelineViewData(
      title: '时间线概览',
      description: '',
      items: <ProjectAssetsTimelineItemViewData>[],
    );
  }
}

class ProjectAssetsTimelineItemViewData {
  const ProjectAssetsTimelineItemViewData({
    required this.id,
    required this.title,
    required this.phaseLabel,
    required this.statusLabel,
    required this.sequenceLabel,
    required this.relatedCount,
    required this.isSelected,
  });

  final String id;
  final String title;
  final String phaseLabel;
  final String statusLabel;
  final String sequenceLabel;
  final int relatedCount;
  final bool isSelected;
}

class ProjectAssetsGraphViewData {
  const ProjectAssetsGraphViewData({
    required this.totalNodeCount,
    required this.totalEdgeCount,
    required this.focusTitle,
    required this.focusSummary,
    required this.focusKindLabel,
    required this.nodes,
    required this.relatedAssets,
    required this.missingReferenceKeys,
  });

  final int totalNodeCount;
  final int totalEdgeCount;
  final String focusTitle;
  final String focusSummary;
  final String focusKindLabel;
  final List<ProjectAssetsGraphNodeViewData> nodes;
  final List<ProjectAssetsRelatedAssetViewData> relatedAssets;
  final List<String> missingReferenceKeys;

  factory ProjectAssetsGraphViewData.empty() {
    return const ProjectAssetsGraphViewData(
      totalNodeCount: 0,
      totalEdgeCount: 0,
      focusTitle: '共享资产图谱',
      focusSummary: '',
      focusKindLabel: '',
      nodes: <ProjectAssetsGraphNodeViewData>[],
      relatedAssets: <ProjectAssetsRelatedAssetViewData>[],
      missingReferenceKeys: <String>[],
    );
  }
}

class ProjectAssetsGraphNodeViewData {
  const ProjectAssetsGraphNodeViewData({
    required this.referenceKey,
    required this.title,
    required this.kindLabel,
    required this.degree,
    required this.hasMissingLinks,
    required this.isSelected,
  });

  final String referenceKey;
  final String title;
  final String kindLabel;
  final int degree;
  final bool hasMissingLinks;
  final bool isSelected;
}

class StyleProfileEditorViewData {
  const StyleProfileEditorViewData({
    required this.id,
    required this.displayName,
    required this.summary,
    required this.genre,
    required this.tone,
    required this.audience,
    required this.tagsText,
    required this.guardrailsText,
    required this.examplePathsText,
    required this.inheritedIdsText,
    required this.defaultForProject,
    required this.relativePath,
  });

  final String id;
  final String displayName;
  final String summary;
  final String genre;
  final String tone;
  final String audience;
  final String tagsText;
  final String guardrailsText;
  final String examplePathsText;
  final String inheritedIdsText;
  final bool defaultForProject;
  final String relativePath;

  factory StyleProfileEditorViewData.empty() {
    return const StyleProfileEditorViewData(
      id: '',
      displayName: '',
      summary: '',
      genre: '',
      tone: '',
      audience: '',
      tagsText: '',
      guardrailsText: '',
      examplePathsText: '',
      inheritedIdsText: '',
      defaultForProject: false,
      relativePath: '',
    );
  }
}

class ForeshadowRecordEditorViewData {
  const ForeshadowRecordEditorViewData({
    required this.id,
    required this.title,
    required this.status,
    required this.summary,
    required this.plantedChapterPath,
    required this.targetPayoffPath,
    required this.relatedEntityIdsText,
    required this.relatedPathsText,
    required this.triggerConditionsText,
    required this.payoffExpectationsText,
    required this.tagsText,
    required this.notes,
    required this.relativePath,
  });

  final String id;
  final String title;
  final String status;
  final String summary;
  final String plantedChapterPath;
  final String targetPayoffPath;
  final String relatedEntityIdsText;
  final String relatedPathsText;
  final String triggerConditionsText;
  final String payoffExpectationsText;
  final String tagsText;
  final String notes;
  final String relativePath;

  factory ForeshadowRecordEditorViewData.empty() {
    return const ForeshadowRecordEditorViewData(
      id: '',
      title: '',
      status: 'planted',
      summary: '',
      plantedChapterPath: '',
      targetPayoffPath: '',
      relatedEntityIdsText: '',
      relatedPathsText: '',
      triggerConditionsText: '',
      payoffExpectationsText: '',
      tagsText: '',
      notes: '',
      relativePath: '',
    );
  }
}

class StyleProfileEditorRequestViewData {
  const StyleProfileEditorRequestViewData({
    required this.id,
    required this.displayName,
    required this.summary,
    required this.genre,
    required this.tone,
    required this.audience,
    required this.tagsText,
    required this.guardrailsText,
    required this.examplePathsText,
    required this.inheritedIdsText,
    required this.defaultForProject,
  });

  final String id;
  final String displayName;
  final String summary;
  final String genre;
  final String tone;
  final String audience;
  final String tagsText;
  final String guardrailsText;
  final String examplePathsText;
  final String inheritedIdsText;
  final bool defaultForProject;
}

class ExpressionConstraintBindingEditorViewData {
  const ExpressionConstraintBindingEditorViewData({
    required this.profileId,
    required this.bindingId,
    required this.displayName,
    required this.summary,
    required this.kindLabel,
    required this.originLabel,
    required this.sourcePath,
    required this.entryAgentContextId,
    required this.selectedPolicyMode,
    required this.availablePolicyOptions,
    required this.scopeSummary,
    required this.strengthSummary,
    required this.usageStrategySummary,
    required this.recommendedScopeText,
    required this.rules,
    required this.riskSignals,
    required this.diagnosticFields,
    required this.enabled,
    required this.defaultForProject,
    required this.availableAgentOptions,
    required this.availableModeOptions,
    required this.availableStageOptions,
    required this.selectedAgentIds,
    required this.selectedModeIds,
    required this.selectedStageIds,
    required this.targetAgentIdsText,
    required this.targetModeIdsText,
    required this.targetStageIdsText,
    required this.weightText,
    required this.hasBinding,
    required this.isBuiltin,
  });

  final String profileId;
  final String bindingId;
  final String displayName;
  final String summary;
  final String kindLabel;
  final String originLabel;
  final String sourcePath;
  final String entryAgentContextId;
  final String selectedPolicyMode;
  final List<ExpressionConstraintPolicyOptionViewData> availablePolicyOptions;
  final String scopeSummary;
  final String strengthSummary;
  final String usageStrategySummary;
  final String recommendedScopeText;
  final List<String> rules;
  final List<String> riskSignals;
  final List<ExpressionConstraintDiagnosticFieldViewData> diagnosticFields;
  final bool enabled;
  final bool defaultForProject;
  final List<ExpressionConstraintSelectableOptionViewData>
  availableAgentOptions;
  final List<ExpressionConstraintSelectableOptionViewData> availableModeOptions;
  final List<ExpressionConstraintSelectableOptionViewData>
  availableStageOptions;
  final List<String> selectedAgentIds;
  final List<String> selectedModeIds;
  final List<String> selectedStageIds;
  final String targetAgentIdsText;
  final String targetModeIdsText;
  final String targetStageIdsText;
  final String weightText;
  final bool hasBinding;
  final bool isBuiltin;

  factory ExpressionConstraintBindingEditorViewData.empty() {
    return const ExpressionConstraintBindingEditorViewData(
      profileId: '',
      bindingId: '',
      displayName: '',
      summary: '',
      kindLabel: '',
      originLabel: '',
      sourcePath: '',
      entryAgentContextId: '',
      selectedPolicyMode: 'adaptive',
      availablePolicyOptions: <ExpressionConstraintPolicyOptionViewData>[],
      scopeSummary: '',
      strengthSummary: '',
      usageStrategySummary: '',
      recommendedScopeText: '',
      rules: <String>[],
      riskSignals: <String>[],
      diagnosticFields: <ExpressionConstraintDiagnosticFieldViewData>[],
      enabled: false,
      defaultForProject: false,
      availableAgentOptions: <ExpressionConstraintSelectableOptionViewData>[],
      availableModeOptions: <ExpressionConstraintSelectableOptionViewData>[],
      availableStageOptions: <ExpressionConstraintSelectableOptionViewData>[],
      selectedAgentIds: <String>[],
      selectedModeIds: <String>[],
      selectedStageIds: <String>[],
      targetAgentIdsText: '',
      targetModeIdsText: '',
      targetStageIdsText: '',
      weightText: '100',
      hasBinding: false,
      isBuiltin: false,
    );
  }
}

class ExpressionConstraintBindingEditorRequestViewData {
  const ExpressionConstraintBindingEditorRequestViewData({
    required this.profileId,
    required this.selectedPolicyMode,
    required this.enabled,
    required this.defaultForProject,
    required this.selectedAgentIds,
    required this.selectedModeIds,
    required this.selectedStageIds,
    required this.targetAgentIdsText,
    required this.targetModeIdsText,
    required this.targetStageIdsText,
    required this.weightText,
  });

  final String profileId;
  final String selectedPolicyMode;
  final bool enabled;
  final bool defaultForProject;
  final List<String> selectedAgentIds;
  final List<String> selectedModeIds;
  final List<String> selectedStageIds;
  final String targetAgentIdsText;
  final String targetModeIdsText;
  final String targetStageIdsText;
  final String weightText;
}

class ExpressionConstraintPolicyOptionViewData {
  const ExpressionConstraintPolicyOptionViewData({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class ExpressionConstraintDiagnosticFieldViewData {
  const ExpressionConstraintDiagnosticFieldViewData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class ExpressionConstraintSelectableOptionViewData {
  const ExpressionConstraintSelectableOptionViewData({
    required this.id,
    required this.label,
    this.note = '',
    this.groupId = '',
  });

  final String id;
  final String label;
  final String note;
  final String groupId;
}

class ForeshadowRecordEditorRequestViewData {
  const ForeshadowRecordEditorRequestViewData({
    required this.id,
    required this.title,
    required this.status,
    required this.summary,
    required this.plantedChapterPath,
    required this.targetPayoffPath,
    required this.relatedEntityIdsText,
    required this.relatedPathsText,
    required this.triggerConditionsText,
    required this.payoffExpectationsText,
    required this.tagsText,
    required this.notes,
  });

  final String id;
  final String title;
  final String status;
  final String summary;
  final String plantedChapterPath;
  final String targetPayoffPath;
  final String relatedEntityIdsText;
  final String relatedPathsText;
  final String triggerConditionsText;
  final String payoffExpectationsText;
  final String tagsText;
  final String notes;
}

class ProjectAssetBundleImportRequestViewData {
  const ProjectAssetBundleImportRequestViewData({
    required this.absolutePath,
    required this.overwrite,
  });

  final String absolutePath;
  final bool overwrite;
}

class ProjectAssetBundleExportRequestViewData {
  const ProjectAssetBundleExportRequestViewData({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
