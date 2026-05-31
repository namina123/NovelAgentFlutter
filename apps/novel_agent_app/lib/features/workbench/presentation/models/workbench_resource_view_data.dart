import 'package:flutter/foundation.dart';

import 'resource_entry_view_data.dart';

class WorkbenchResourceViewData {
  const WorkbenchResourceViewData({
    required this.projectName,
    required this.projectSubtitle,
    required this.resourceEntries,
  });

  final String projectName;
  final String projectSubtitle;
  final List<ResourceEntryViewData> resourceEntries;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkbenchResourceViewData &&
            other.projectName == projectName &&
            other.projectSubtitle == projectSubtitle &&
            listEquals(other.resourceEntries, resourceEntries);
  }

  @override
  int get hashCode => Object.hash(
    projectName,
    projectSubtitle,
    Object.hashAll(resourceEntries),
  );
}
