import 'book_deconstruction_followup_option_view_data.dart';

class BookDeconstructionFollowupGroupViewData {
  const BookDeconstructionFollowupGroupViewData({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
    this.isFutureExtensionGroup = false,
  });

  final String id;
  final String title;
  final String description;
  final List<BookDeconstructionFollowupOptionViewData> options;
  final bool isFutureExtensionGroup;
}
