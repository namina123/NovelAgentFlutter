class ForeshadowRecord {
  const ForeshadowRecord({
    required this.id,
    required this.title,
    required this.status,
    this.summary = '',
  });

  final String id;
  final String title;
  final String status;
  final String summary;
}
