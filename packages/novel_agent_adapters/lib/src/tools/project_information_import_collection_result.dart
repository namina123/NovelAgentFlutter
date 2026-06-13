import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectInformationImportCollectionResult {
  const ProjectInformationImportCollectionResult({
    required this.saved,
    this.researchNote,
    this.summary = '',
    this.changedPaths = const <String>[],
    this.blockedReason = '',
  });

  final bool saved;
  final ResearchNote? researchNote;
  final String summary;
  final List<String> changedPaths;
  final String blockedReason;
}
