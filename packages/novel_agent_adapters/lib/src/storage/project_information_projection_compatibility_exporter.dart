import 'package:novel_agent_core/novel_agent_core.dart';

abstract class ProjectInformationProjectionCompatibilityExporter {
  Future<void> exportDraftBundle(
    ProjectDescriptor project,
    InformationProjectionDraftBundle bundle,
  );
}
