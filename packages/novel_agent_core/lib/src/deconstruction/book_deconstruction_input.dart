import 'book_deconstruction_constants.dart';
import 'book_deconstruction_continuation_direction.dart';
import 'book_deconstruction_source_document.dart';
import '../imports/source_import_normalized_document.dart';

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

  factory BookDeconstructionInput.fromSourceImportDocuments({
    required String extractionId,
    required String title,
    required List<SourceImportNormalizedDocument> sourceDocuments,
    String projectStrategyId = BookDeconstructionConstants.projectStrategyId,
    String targetProjectTypeId = BookDeconstructionConstants.projectTypeId,
    String modeId = BookDeconstructionConstants.modeAssetExtraction,
    BookDeconstructionContinuationDirection preferredContinuationDirection =
        BookDeconstructionContinuationDirection.analysisFirst,
    String sourceLanguage = '',
    String operatorNotes = '',
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    // 中文注释: 这个工厂让拆书输入直接接住共享 normalized document，而不是再复制一套中间转换逻辑。
    return BookDeconstructionInput(
      extractionId: extractionId,
      title: title,
      sourceDocuments: sourceDocuments
          .map(BookDeconstructionSourceDocument.fromSourceImportDocument)
          .toList(growable: false),
      projectStrategyId: projectStrategyId,
      targetProjectTypeId: targetProjectTypeId,
      modeId: modeId,
      preferredContinuationDirection: preferredContinuationDirection,
      sourceLanguage: sourceLanguage,
      operatorNotes: operatorNotes,
      metadata: metadata,
    );
  }
}
