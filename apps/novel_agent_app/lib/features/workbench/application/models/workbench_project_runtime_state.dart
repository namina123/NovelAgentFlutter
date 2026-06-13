import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'open_document_state.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class WorkbenchProjectRuntimeState {
  const WorkbenchProjectRuntimeState({
    this.currentProject,
    this.currentRuntimeProfile,
    this.resourceSnapshotEntries = const <JsonMap>[],
    this.expandedResourceDirectories = const <String>{},
    this.openDocuments = const <OpenDocumentState>[],
    this.activeOpenDocumentId = '',
    this.currentProjectLongTaskRuns = const <RunInstance>[],
    this.currentProjectLongTaskRunDetails =
        const <String, ProjectLongTaskStationDetail>{},
    this.isProjectLongTaskSummaryLoading = false,
    this.isSavingWorkbenchSnapshot = false,
  });

  final ProjectDescriptor? currentProject;
  final ProjectRuntimeProfile? currentRuntimeProfile;
  final List<JsonMap> resourceSnapshotEntries;
  final Set<String> expandedResourceDirectories;
  final List<OpenDocumentState> openDocuments;
  final String activeOpenDocumentId;
  final List<RunInstance> currentProjectLongTaskRuns;
  final Map<String, ProjectLongTaskStationDetail>
  currentProjectLongTaskRunDetails;
  final bool isProjectLongTaskSummaryLoading;
  final bool isSavingWorkbenchSnapshot;

  WorkbenchProjectRuntimeState copyWith({
    Object? currentProject = _projectSentinel,
    Object? currentRuntimeProfile = _runtimeProfileSentinel,
    List<JsonMap>? resourceSnapshotEntries,
    Set<String>? expandedResourceDirectories,
    List<OpenDocumentState>? openDocuments,
    String? activeOpenDocumentId,
    List<RunInstance>? currentProjectLongTaskRuns,
    Map<String, ProjectLongTaskStationDetail>? currentProjectLongTaskRunDetails,
    bool? isProjectLongTaskSummaryLoading,
    bool? isSavingWorkbenchSnapshot,
  }) {
    // 中文注释: 工作台项目运行时状态独立成快照，避免控制器直接维护一大串分散字段。
    return WorkbenchProjectRuntimeState(
      currentProject: identical(currentProject, _projectSentinel)
          ? this.currentProject
          : currentProject as ProjectDescriptor?,
      currentRuntimeProfile:
          identical(currentRuntimeProfile, _runtimeProfileSentinel)
          ? this.currentRuntimeProfile
          : currentRuntimeProfile as ProjectRuntimeProfile?,
      resourceSnapshotEntries:
          resourceSnapshotEntries ?? this.resourceSnapshotEntries,
      expandedResourceDirectories:
          expandedResourceDirectories ?? this.expandedResourceDirectories,
      openDocuments: openDocuments ?? this.openDocuments,
      activeOpenDocumentId: activeOpenDocumentId ?? this.activeOpenDocumentId,
      currentProjectLongTaskRuns:
          currentProjectLongTaskRuns ?? this.currentProjectLongTaskRuns,
      currentProjectLongTaskRunDetails:
          currentProjectLongTaskRunDetails ??
          this.currentProjectLongTaskRunDetails,
      isProjectLongTaskSummaryLoading:
          isProjectLongTaskSummaryLoading ??
          this.isProjectLongTaskSummaryLoading,
      isSavingWorkbenchSnapshot:
          isSavingWorkbenchSnapshot ?? this.isSavingWorkbenchSnapshot,
    );
  }
}

const Object _projectSentinel = Object();
const Object _runtimeProfileSentinel = Object();
