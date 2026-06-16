import 'package:flutter/foundation.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_long_task_summary_view_data.dart';
import 'workbench_information_view_data.dart';
import 'resource_entry_view_data.dart';

class WorkbenchResourceViewData {
  const WorkbenchResourceViewData({
    required this.projectName,
    required this.projectSubtitle,
    this.projectTypeId = '',
    this.projectTypeTransitionAvailability =
        const EntryAvailabilityDecision.hiddenContract(
          entryId: 'workspace.transition_project_type',
        ),
    required this.resourceEntries,
    this.informationViewData = const WorkbenchInformationViewData(),
    this.projectLongTaskSummary,
  });

  final String projectName;
  final String projectSubtitle;
  final String projectTypeId;
  final EntryAvailabilityDecision projectTypeTransitionAvailability;
  final List<ResourceEntryViewData> resourceEntries;
  final WorkbenchInformationViewData informationViewData;
  final ProjectLongTaskSummaryViewData? projectLongTaskSummary;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkbenchResourceViewData &&
            other.projectName == projectName &&
            other.projectSubtitle == projectSubtitle &&
            other.projectTypeId == projectTypeId &&
            other.projectTypeTransitionAvailability ==
                projectTypeTransitionAvailability &&
            listEquals(other.resourceEntries, resourceEntries) &&
            other.informationViewData == informationViewData &&
            other.projectLongTaskSummary == projectLongTaskSummary;
  }

  @override
  int get hashCode => Object.hash(
    projectName,
    projectSubtitle,
    projectTypeId,
    projectTypeTransitionAvailability,
    Object.hashAll(resourceEntries),
    informationViewData,
    projectLongTaskSummary,
  );
}
