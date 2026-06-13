import 'dart:convert';

import 'reference_package_models.dart';

class ReferenceEntrySearchTextBuilderService {
  const ReferenceEntrySearchTextBuilderService();

  String build(ReferenceEntryRecord entry) {
    final segments = <String>[
      entry.entryNamespace,
      entry.entryKind,
      entry.title,
      entry.summary,
      ...entry.tags,
      jsonEncode(entry.payload),
    ].where((segment) => segment.trim().isNotEmpty).toList(growable: false);
    return segments.join('\n').toLowerCase();
  }
}
