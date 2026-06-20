import 'project_assets_snapshot.dart';

class ProjectAssetsRefreshOutcome {
  const ProjectAssetsRefreshOutcome({
    required this.snapshot,
    required this.statusMessage,
  });

  final ProjectAssetsSnapshot snapshot;
  final String statusMessage;
}
