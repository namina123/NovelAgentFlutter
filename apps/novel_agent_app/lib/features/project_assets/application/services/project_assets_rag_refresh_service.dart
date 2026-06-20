import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_rag_extraction_execution_result.dart';
import 'project_rag_extraction_execution_service.dart';

class ProjectAssetsRagRefreshService {
  ProjectAssetsRagRefreshService({
    required ProjectRagExtractionExecutionService ragExtractionExecutionService,
  }) : _ragExtractionExecutionService = ragExtractionExecutionService;

  final ProjectRagExtractionExecutionService _ragExtractionExecutionService;

  Future<ProjectRagExtractionExecutionResult> refresh({
    required ProjectDescriptor project,
    String selectedCorpusId = '',
  }) async {
    return _ragExtractionExecutionService.loadSnapshot(
      project: project,
      selectedCorpusId: selectedCorpusId,
    );
  }
}
