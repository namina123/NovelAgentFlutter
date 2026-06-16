class CliExitCodes {
  const CliExitCodes._();

  static const int success = 0;
  static const int executionFailure = 1;
  static const int invalidInput = 2;
  static const int notFound = 3;
  static const int configError = 5;
  static const int unavailable = 6;
  static const int userAborted = 7;
}
