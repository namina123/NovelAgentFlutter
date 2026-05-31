class BookDeconstructionStepViewData {
  const BookDeconstructionStepViewData({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.isComplete,
  });

  final String id;
  final String title;
  final String description;
  final bool isActive;
  final bool isComplete;
}
