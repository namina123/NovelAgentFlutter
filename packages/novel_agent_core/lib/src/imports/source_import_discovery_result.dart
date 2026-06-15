import 'source_import_selection.dart';

class SourceImportDiscoveryResult {
  const SourceImportDiscoveryResult({
    required this.selections,
    this.skippedPaths = const <String>[],
  });

  final List<SourceImportSelection> selections;
  final List<String> skippedPaths;
}
