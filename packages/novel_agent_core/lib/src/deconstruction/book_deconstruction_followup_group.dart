import 'book_deconstruction_followup_option.dart';

class BookDeconstructionFollowupGroup {
  const BookDeconstructionFollowupGroup({
    required this.id,
    required this.title,
    required this.description,
    this.options = const <BookDeconstructionFollowupOption>[],
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String description;
  final List<BookDeconstructionFollowupOption> options;
  final Map<String, Object?> metadata;
}
