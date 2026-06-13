import 'reference_extraction_run_models.dart';

abstract class ReferenceExtractionStagingWorkspace {
  Future<void> upsertRun(ReferenceExtractionStagingRun run);

  Future<ReferenceExtractionStagingRun?> readRun(String runId);
}
