import 'book_deconstruction_coverage_hint.dart';
import 'book_deconstruction_hint_source_kind.dart';
import 'book_deconstruction_identity_mapping_hint.dart';
import 'book_deconstruction_mechanic_hint.dart';
import 'book_deconstruction_scope_map.dart';

class BookDeconstructionContinuityHints {
  const BookDeconstructionContinuityHints({
    this.coverage = const BookDeconstructionCoverageHint(),
    this.scopeMap = const BookDeconstructionScopeMap(),
    this.identityMappings = const <BookDeconstructionIdentityMappingHint>[],
    this.mechanicHints = const <BookDeconstructionMechanicHint>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final BookDeconstructionCoverageHint coverage;
  final BookDeconstructionScopeMap scopeMap;
  final List<BookDeconstructionIdentityMappingHint> identityMappings;
  final List<BookDeconstructionMechanicHint> mechanicHints;
  final String notes;
  final Map<String, Object?> metadata;

  bool get hasContent {
    return coverage.sourceLabel.trim().isNotEmpty ||
        coverage.sourcePaths.isNotEmpty ||
        coverage.sourceRanges.isNotEmpty ||
        scopeMap.scopes.isNotEmpty ||
        identityMappings.isNotEmpty ||
        mechanicHints.isNotEmpty ||
        notes.trim().isNotEmpty;
  }

  bool get hasInferredHints {
    if (scopeMap.scopes.any(
      (item) =>
          item.sourceKind == BookDeconstructionHintSourceKind.inferredHint,
    )) {
      return true;
    }
    if (identityMappings.any(
      (item) =>
          item.sourceKind == BookDeconstructionHintSourceKind.inferredHint,
    )) {
      return true;
    }
    if (mechanicHints.any(
      (item) =>
          item.sourceKind == BookDeconstructionHintSourceKind.inferredHint,
    )) {
      return true;
    }
    if (coverage.sourceRanges.any(
      (item) =>
          item.sourceKind == BookDeconstructionHintSourceKind.inferredHint,
    )) {
      return true;
    }
    return false;
  }
}
