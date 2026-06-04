class OpenJsonStructureValidatorService {
  const OpenJsonStructureValidatorService();

  List<String> requireNonBlankString(String value, String code) {
    return value.trim().isEmpty ? <String>[code] : const <String>[];
  }

  List<String> requireNonEmptyCollection(
    Iterable<Object?> values,
    String code,
  ) {
    return values.isEmpty ? <String>[code] : const <String>[];
  }

  List<String> validateConfidence(double value, String code) {
    return value < 0 || value > 1 ? <String>[code] : const <String>[];
  }

  List<String> validateNonNegativeInt(int value, String code) {
    return value < 0 ? <String>[code] : const <String>[];
  }

  List<String> requireCondition(bool condition, String code) {
    return condition ? const <String>[] : <String>[code];
  }
}
