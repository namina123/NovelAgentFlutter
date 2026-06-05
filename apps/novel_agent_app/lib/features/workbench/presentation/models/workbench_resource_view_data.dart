import 'package:flutter/foundation.dart';

import 'workbench_information_view_data.dart';
import 'resource_entry_view_data.dart';

class WorkbenchResourceViewData {
  const WorkbenchResourceViewData({
    required this.projectName,
    required this.projectSubtitle,
    required this.resourceEntries,
    this.informationViewData = const WorkbenchInformationViewData(),
  });

  final String projectName;
  final String projectSubtitle;
  final List<ResourceEntryViewData> resourceEntries;
  final WorkbenchInformationViewData informationViewData;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkbenchResourceViewData &&
            other.projectName == projectName &&
            other.projectSubtitle == projectSubtitle &&
            listEquals(other.resourceEntries, resourceEntries) &&
            other.informationViewData == informationViewData;
  }

  @override
  int get hashCode => Object.hash(
    projectName,
    projectSubtitle,
    Object.hashAll(resourceEntries),
    informationViewData,
  );
}
