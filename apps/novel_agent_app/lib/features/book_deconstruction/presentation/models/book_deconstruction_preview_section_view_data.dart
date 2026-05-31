import 'book_deconstruction_preview_item_view_data.dart';

class BookDeconstructionPreviewSectionViewData {
  const BookDeconstructionPreviewSectionViewData({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
  });

  final String id;
  final String title;
  final String description;
  final List<BookDeconstructionPreviewItemViewData> items;
}
