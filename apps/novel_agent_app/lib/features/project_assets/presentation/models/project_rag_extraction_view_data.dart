class ProjectRagExtractionViewData {
  const ProjectRagExtractionViewData({
    required this.title,
    required this.description,
    required this.status,
    required this.activeModeId,
    required this.modes,
    required this.corpusSummary,
    required this.mountSummary,
    required this.recentSourcePath,
    required this.canBuildTxt,
    required this.canMountCorpus,
    required this.isLoading,
  });

  final String title;
  final String description;
  final String status;
  final String activeModeId;
  final List<ProjectRagExtractionModeViewData> modes;
  final ProjectRagExtractionCorpusSummaryViewData corpusSummary;
  final ProjectRagExtractionMountSummaryViewData mountSummary;
  final String recentSourcePath;
  final bool canBuildTxt;
  final bool canMountCorpus;
  final bool isLoading;

  factory ProjectRagExtractionViewData.empty() {
    // 中文注释: 空视图用于项目未打开时的占位展示，不把任何构建操作误导成可用。
    return ProjectRagExtractionViewData(
      title: '语料提取',
      description: '第一阶段只开放 txt 语料提取与项目挂载。结构化知识与混合提取保留为合同占位。',
      status: '',
      activeModeId: '',
      modes: <ProjectRagExtractionModeViewData>[],
      corpusSummary: ProjectRagExtractionCorpusSummaryViewData.empty(),
      mountSummary: ProjectRagExtractionMountSummaryViewData.empty(),
      recentSourcePath: '',
      canBuildTxt: false,
      canMountCorpus: false,
      isLoading: false,
    );
  }
}

class ProjectRagExtractionModeViewData {
  const ProjectRagExtractionModeViewData({
    required this.id,
    required this.title,
    required this.summary,
    required this.badge,
    required this.isSelected,
    required this.isImplemented,
  });

  final String id;
  final String title;
  final String summary;
  final String badge;
  final bool isSelected;
  final bool isImplemented;
}

class ProjectRagExtractionCorpusSummaryViewData {
  const ProjectRagExtractionCorpusSummaryViewData({
    required this.title,
    required this.corpusId,
    required this.sourceKind,
    required this.buildMode,
    required this.language,
    required this.chapterCountLabel,
    required this.chunkCountLabel,
    required this.modelAssistedLabel,
    required this.indexBackendLabel,
    required this.updatedAt,
    required this.sourcePath,
  });

  final String title;
  final String corpusId;
  final String sourceKind;
  final String buildMode;
  final String language;
  final String chapterCountLabel;
  final String chunkCountLabel;
  final String modelAssistedLabel;
  final String indexBackendLabel;
  final String updatedAt;
  final String sourcePath;

  factory ProjectRagExtractionCorpusSummaryViewData.empty() {
    // 中文注释: 语料摘要为空时只展示占位，不伪造已有 corpus。
    return ProjectRagExtractionCorpusSummaryViewData(
      title: '尚未构建语料',
      corpusId: '',
      sourceKind: '',
      buildMode: '',
      language: '',
      chapterCountLabel: '0',
      chunkCountLabel: '0',
      modelAssistedLabel: '否',
      indexBackendLabel: '',
      updatedAt: '',
      sourcePath: '',
    );
  }
}

class ProjectRagExtractionMountSummaryViewData {
  const ProjectRagExtractionMountSummaryViewData({
    required this.bindingCount,
    required this.corpusIds,
    required this.topCorpusId,
    required this.topBindingId,
    required this.topMountScope,
    required this.topUsagePolicy,
    required this.topActivationPolicy,
    required this.emptyMessage,
  });

  final int bindingCount;
  final List<String> corpusIds;
  final String topCorpusId;
  final String topBindingId;
  final String topMountScope;
  final String topUsagePolicy;
  final String topActivationPolicy;
  final String emptyMessage;

  factory ProjectRagExtractionMountSummaryViewData.empty() {
    // 中文注释: 挂载摘要为空时不生成额外状态，只提示用户尚未绑定。
    return ProjectRagExtractionMountSummaryViewData(
      bindingCount: 0,
      corpusIds: <String>[],
      topCorpusId: '',
      topBindingId: '',
      topMountScope: '',
      topUsagePolicy: '',
      topActivationPolicy: '',
      emptyMessage: '当前项目尚未挂载任何语料。',
    );
  }
}
