class UserOptionViewData {
  const UserOptionViewData({
    required this.label,
    required this.description,
    required this.prompt,
    required this.sourceQuestion,
    required this.allOptions,
    this.optionId = '',
    this.permissionApprovalId = '',
    this.permissionApprovalOptionId = '',
  });

  final String label;
  final String description;
  final String prompt;
  final String sourceQuestion;
  final List<Map<String, Object?>> allOptions;
  final String optionId;
  final String permissionApprovalId;
  final String permissionApprovalOptionId;
}
