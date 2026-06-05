class SubAgentRunViewData {
  const SubAgentRunViewData({
    required this.id,
    required this.agentName,
    required this.task,
    required this.status,
    required this.summary,
    required this.content,
    required this.reasoning,
    required this.toolCount,
    required this.events,
    this.expertOpinion = '',
    this.evidenceItems = const <String>[],
    this.adoptionSummary = '',
    this.degradationSummary = '',
    this.diagnosticItems = const <String>[],
  });

  final String id;
  final String agentName;
  final String task;
  final String status;
  final String summary;
  final String content;
  final String reasoning;
  final int toolCount;
  final List<String> events;
  final String expertOpinion;
  final List<String> evidenceItems;
  final String adoptionSummary;
  final String degradationSummary;
  final List<String> diagnosticItems;
}
