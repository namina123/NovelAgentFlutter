class InformationProjectionDocument {
  const InformationProjectionDocument({
    required this.projectionId,
    required this.relativePath,
    required this.title,
    required this.markdown,
  });

  static const String knowledgeSummaryProjectionId =
      'project_knowledge_summary';
  static const String knowledgeSummaryRelativePath = 'knowledge/项目知识摘要.md';
  static const String designSummaryProjectionId = 'design_element_summary';
  static const String designSummaryRelativePath = 'knowledge/设计元素摘要.md';
  static const String researchSummaryProjectionId = 'research_note_summary';
  static const String researchSummaryRelativePath = 'research/资料研究摘要.md';
  static const String referenceBoundaryProjectionId =
      'reference_work_boundary_summary';
  static const String referenceBoundaryRelativePath = 'references/引用作品边界.md';

  final String projectionId;
  final String relativePath;
  final String title;
  final String markdown;
}
