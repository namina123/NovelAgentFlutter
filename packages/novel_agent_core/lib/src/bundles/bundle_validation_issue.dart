class BundleValidationIssue {
  const BundleValidationIssue({
    required this.code,
    required this.message,
    this.fieldPath = '',
    this.severity = 'error',
  });

  final String code;
  final String message;
  final String fieldPath;
  final String severity;
}
