class UserOptionViewData {
  const UserOptionViewData({
    required this.label,
    required this.description,
    required this.prompt,
    required this.sourceQuestion,
    required this.allOptions,
  });

  final String label;
  final String description;
  final String prompt;
  final String sourceQuestion;
  final List<Map<String, Object?>> allOptions;
}
