bool containsProbableAbsolutePathLeak(String content) {
  final normalized = content.replaceAll('\\', '/');
  return RegExp(r'(^|[^A-Za-z0-9+.-])[A-Za-z]:/').hasMatch(normalized);
}
