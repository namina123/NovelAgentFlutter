class CustomModelReasoningEffortEntryViewData {
  const CustomModelReasoningEffortEntryViewData({
    required this.id,
    required this.keyName,
    required this.valueText,
  });

  final String id;
  final String keyName;
  final String valueText;

  CustomModelReasoningEffortEntryViewData copyWith({
    String? id,
    String? keyName,
    String? valueText,
  }) {
    return CustomModelReasoningEffortEntryViewData(
      id: id ?? this.id,
      keyName: keyName ?? this.keyName,
      valueText: valueText ?? this.valueText,
    );
  }
}
