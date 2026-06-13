import 'reference_package_models.dart';

class ReferenceQuery {
  const ReferenceQuery({
    required this.queryText,
    this.packageIds = const <String>[],
    this.entryKinds = const <String>[],
    this.maxResults = 20,
  });

  final String queryText;
  final List<String> packageIds;
  final List<String> entryKinds;
  final int maxResults;
}

class ReferenceQueryResult {
  const ReferenceQueryResult({
    required this.entries,
    required this.totalCount,
    this.truncated = false,
  });

  final List<ReferenceEntryRecord> entries;
  final int totalCount;
  final bool truncated;

  List<String> get entryIds =>
      entries.map((entry) => entry.entryId).toList(growable: false);
}
