class ModeStageOption {
  const ModeStageOption({
    required this.id,
    required this.fieldKey,
    required this.label,
    required this.value,
    this.description = '',
  });

  final String id;
  final String fieldKey;
  final String label;
  final String value;
  final String description;
}
