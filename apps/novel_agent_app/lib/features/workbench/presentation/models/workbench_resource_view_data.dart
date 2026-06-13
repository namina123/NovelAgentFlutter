import 'package:flutter/foundation.dart';

import 'project_long_task_summary_view_data.dart';
import 'workbench_information_view_data.dart';
import 'resource_entry_view_data.dart';

class WorkbenchResourceViewData {
  const WorkbenchResourceViewData({
    required this.projectName,
    required this.projectSubtitle,
    required this.resourceEntries,
    this.informationViewData = const WorkbenchInformationViewData(),
    this.projectLongTaskSummary,
  });

  final String projectName;
  final String projectSubtitle;
  final List<ResourceEntryViewData> resourceEntries;
  final WorkbenchInformationViewData informationViewData;
  final ProjectLongTaskSummaryViewData? projectLongTaskSummary;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkbenchResourceViewData &&
            other.projectName == projectName &&
            other.projectSubtitle == projectSubtitle &&
            listEquals(other.resourceEntries, resourceEntries) &&
            other.informationViewData == informationViewData &&
            other.projectLongTaskSummary == projectLongTaskSummary;
  }

  @override
  int get hashCode => Object.hash(
    projectName,
    projectSubtitle,
    Object.hashAll(resourceEntries),
    informationViewData,
    projectLongTaskSummary,
  );
}
