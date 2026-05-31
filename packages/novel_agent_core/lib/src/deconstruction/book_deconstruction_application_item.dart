class BookDeconstructionApplicationItem {
  const BookDeconstructionApplicationItem({
    required this.id,
    required this.sourceKind,
    required this.sourceId,
    required this.targetKind,
    required this.action,
    required this.displayName,
    this.summary = '',
    this.relativePathHint = '',
  });

  final String id;
  final String sourceKind;
  final String sourceId;
  final String targetKind;
  final String action;
  final String displayName;
  final String summary;
  final String relativePathHint;
}
