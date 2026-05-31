import 'book_deconstruction_plan_item_view_data.dart';

class BookDeconstructionPlanGroupViewData {
  const BookDeconstructionPlanGroupViewData({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
  });

  final String id;
  final String title;
  final String description;
  final List<BookDeconstructionPlanItemViewData> items;
}
