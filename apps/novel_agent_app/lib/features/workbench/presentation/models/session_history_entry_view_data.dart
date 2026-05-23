class SessionHistoryEntryViewData {
  const SessionHistoryEntryViewData({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
    required this.isSelected,
  });

  final String id;
  final String title;
  final String status;
  final String updatedAt;
  final bool isSelected;
}
