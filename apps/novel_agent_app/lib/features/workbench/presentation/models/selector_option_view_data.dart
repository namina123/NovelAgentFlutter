class SelectorOptionViewData {
  const SelectorOptionViewData({
    required this.id,
    required this.label,
    this.note = '',
  });

  final String id;
  final String label;
  final String note;
}
