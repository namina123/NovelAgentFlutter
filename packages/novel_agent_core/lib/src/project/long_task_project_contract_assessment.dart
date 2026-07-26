class LongTaskProjectContractAssessment {
  const LongTaskProjectContractAssessment.allowed()
    : isAllowed = true,
      errorCode = '',
      message = '';

  const LongTaskProjectContractAssessment.rejected({
    required this.errorCode,
    required this.message,
  }) : isAllowed = false;

  final bool isAllowed;
  final String errorCode;
  final String message;
}
