class BundleConflictItem {
  const BundleConflictItem({
    required this.entryKind,
    required this.entryId,
    required this.displayName,
    required this.targetPath,
    required this.status,
    required this.action,
    this.changedFields = const <String>[],
  });

  final String entryKind;
  final String entryId;
  final String displayName;
  final String targetPath;
  final String status;
  final String action;
  final List<String> changedFields;
}
