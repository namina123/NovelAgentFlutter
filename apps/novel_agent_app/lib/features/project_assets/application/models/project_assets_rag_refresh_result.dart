import 'project_rag_extraction_snapshot.dart';

class ProjectAssetsRagRefreshResult {
  const ProjectAssetsRagRefreshResult({
    required this.ragExtraction,
    required this.statusMessage,
  });

  final ProjectRagExtractionSnapshot ragExtraction;
  final String statusMessage;
}
