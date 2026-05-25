class InspirationConvergenceStage {
  const InspirationConvergenceStage({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    this.fieldKeys = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final int order;
  final List<String> fieldKeys;
}
