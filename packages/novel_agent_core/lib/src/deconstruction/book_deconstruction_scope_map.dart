import 'book_deconstruction_scope_hint.dart';

class BookDeconstructionScopeMap {
  const BookDeconstructionScopeMap({
    this.scopes = const <BookDeconstructionScopeHint>[],
    this.defaultScopeId = '',
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final List<BookDeconstructionScopeHint> scopes;
  final String defaultScopeId;
  final String notes;
  final Map<String, Object?> metadata;
}
