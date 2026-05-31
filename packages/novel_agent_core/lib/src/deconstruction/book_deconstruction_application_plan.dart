import 'book_deconstruction_application_item.dart';

class BookDeconstructionApplicationPlan {
  const BookDeconstructionApplicationPlan({
    required this.planId,
    required this.extractionId,
    required this.targetProjectTypeId,
    required this.targetProjectStrategyId,
    required this.modeId,
    required this.items,
  });

  final String planId;
  final String extractionId;
  final String targetProjectTypeId;
  final String targetProjectStrategyId;
  final String modeId;
  final List<BookDeconstructionApplicationItem> items;
}
