class ProjectRagMountSummary {
  const ProjectRagMountSummary({
    required this.projectId,
    required this.bindingCount,
    required this.corpusIds,
    required this.topCorpusId,
    required this.topBindingId,
    required this.topMountScope,
    required this.topUsagePolicy,
    required this.topActivationPolicy,
  });

  final String projectId;
  final int bindingCount;
  final List<String> corpusIds;
  final String topCorpusId;
  final String topBindingId;
  final String topMountScope;
  final String topUsagePolicy;
  final String topActivationPolicy;

  factory ProjectRagMountSummary.empty() {
    // 中文注释: 空摘要用于尚未构建或尚未挂载的项目状态，不代表失败。
    return const ProjectRagMountSummary(
      projectId: '',
      bindingCount: 0,
      corpusIds: <String>[],
      topCorpusId: '',
      topBindingId: '',
      topMountScope: '',
      topUsagePolicy: '',
      topActivationPolicy: '',
    );
  }

  bool get hasBindings => bindingCount > 0;

  ProjectRagMountSummary copyWith({
    String? projectId,
    int? bindingCount,
    List<String>? corpusIds,
    String? topCorpusId,
    String? topBindingId,
    String? topMountScope,
    String? topUsagePolicy,
    String? topActivationPolicy,
  }) {
    // 中文注释: 挂载摘要在构建与挂载后会被局部刷新，因此提供薄 copy 入口。
    return ProjectRagMountSummary(
      projectId: projectId ?? this.projectId,
      bindingCount: bindingCount ?? this.bindingCount,
      corpusIds: corpusIds ?? this.corpusIds,
      topCorpusId: topCorpusId ?? this.topCorpusId,
      topBindingId: topBindingId ?? this.topBindingId,
      topMountScope: topMountScope ?? this.topMountScope,
      topUsagePolicy: topUsagePolicy ?? this.topUsagePolicy,
      topActivationPolicy: topActivationPolicy ?? this.topActivationPolicy,
    );
  }
}
