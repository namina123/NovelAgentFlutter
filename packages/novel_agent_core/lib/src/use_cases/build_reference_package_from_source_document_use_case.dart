import '../ports/reference_evidence_substrate.dart';
import '../reference_substrate/reference_source_document_extraction_service.dart';
import '../reference_substrate/reference_source_document_models.dart';

class BuildReferencePackageFromSourceDocumentUseCase {
  BuildReferencePackageFromSourceDocumentUseCase({
    required ReferenceEvidenceSubstrate substrate,
    ReferenceSourceDocumentExtractionService? extractionService,
  }) : _substrate = substrate,
       _extractionService =
           extractionService ??
           const ReferenceSourceDocumentExtractionService();

  final ReferenceEvidenceSubstrate _substrate;
  final ReferenceSourceDocumentExtractionService _extractionService;

  Future<ReferenceSourceDocumentIngestionResult> execute(
    ReferenceSourceDocumentIngestionRequest request,
  ) async {
    final result = _extractionService.extract(request);
    await _substrate.upsertPackageSnapshot(result.snapshot);
    return result;
  }
}
