import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectCollectionSnapshot {
  const ProjectCollectionSnapshot({
    required this.kind,
    required this.title,
    required this.description,
    required this.entries,
    required this.selectedEntryId,
  });

  final String kind;
  final String title;
  final String description;
  final List<JsonMap> entries;
  final String selectedEntryId;

  factory ProjectCollectionSnapshot.initial() {
    return const ProjectCollectionSnapshot(
      kind: 'tasks',
      title: '任务',
      description: '',
      entries: <JsonMap>[],
      selectedEntryId: '',
    );
  }
}
