import 'reference_extraction_constants.dart';

class ReferenceExtractionWorkflowPhaseCatalogService {
  const ReferenceExtractionWorkflowPhaseCatalogService();

  List<String> orderedPhaseIds() {
    return const <String>[
      ReferenceExtractionWorkflowPhases.seedExtraction,
      ReferenceExtractionWorkflowPhases.groupResolution,
      ReferenceExtractionWorkflowPhases.batchPlanning,
      ReferenceExtractionWorkflowPhases.batchExecution,
      ReferenceExtractionWorkflowPhases.proposalGeneration,
      ReferenceExtractionWorkflowPhases.reviewGate,
      ReferenceExtractionWorkflowPhases.packageFinalize,
    ];
  }
}
