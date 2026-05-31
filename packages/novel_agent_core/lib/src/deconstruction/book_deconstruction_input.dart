import 'book_deconstruction_constants.dart';
import 'book_deconstruction_continuation_direction.dart';
import 'book_deconstruction_source_document.dart';

class BookDeconstructionInput {
  const BookDeconstructionInput({
    required this.extractionId,
    required this.title,
    required this.sourceDocuments,
    this.projectStrategyId = BookDeconstructionConstants.projectStrategyId,
    this.targetProjectTypeId = BookDeconstructionConstants.projectTypeId,
    this.modeId = BookDeconstructionConstants.modeAssetExtraction,
    this.preferredContinuationDirection =
        BookDeconstructionContinuationDirection.analysisFirst,
    this.sourceLanguage = '',
    this.operatorNotes = '',
    this.metadata = const <String, Object?>{},
  });

  final String extractionId;
  final String title;
  final List<BookDeconstructionSourceDocument> sourceDocuments;
  final String projectStrategyId;
  final String targetProjectTypeId;
  final String modeId;
  final BookDeconstructionContinuationDirection preferredContinuationDirection;
  final String sourceLanguage;
  final String operatorNotes;
  final Map<String, Object?> metadata;
}
