import 'open_document_state.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class WorkbenchProjectRuntimeState {
  const WorkbenchProjectRuntimeState({
    this.currentProject,
    this.resourceSnapshotEntries = const <JsonMap>[],
    this.expandedResourceDirectories = const <String>{},
    this.openDocuments = const <OpenDocumentState>[],
    this.activeOpenDocumentId = '',
    this.isSavingWorkbenchSnapshot = false,
  });

  final ProjectDescriptor? currentProject;
  final List<JsonMap> resourceSnapshotEntries;
  final Set<String> expandedResourceDirectories;
  final List<OpenDocumentState> openDocuments;
  final String activeOpenDocumentId;
  final bool isSavingWorkbenchSnapshot;

  WorkbenchProjectRuntimeState copyWith({
    Object? currentProject = _projectSentinel,
    List<JsonMap>? resourceSnapshotEntries,
    Set<String>? expandedResourceDirectories,
    List<OpenDocumentState>? openDocuments,
    String? activeOpenDocumentId,
    bool? isSavingWorkbenchSnapshot,
  }) {
    // 中文注释: 工作台项目运行时状态独立成快照，避免控制器直接维护一大串分散字段。
    return WorkbenchProjectRuntimeState(
      currentProject: identical(currentProject, _projectSentinel)
          ? this.currentProject
          : currentProject as ProjectDescriptor?,
      resourceSnapshotEntries:
          resourceSnapshotEntries ?? this.resourceSnapshotEntries,
      expandedResourceDirectories:
          expandedResourceDirectories ?? this.expandedResourceDirectories,
      openDocuments: openDocuments ?? this.openDocuments,
      activeOpenDocumentId: activeOpenDocumentId ?? this.activeOpenDocumentId,
      isSavingWorkbenchSnapshot:
          isSavingWorkbenchSnapshot ?? this.isSavingWorkbenchSnapshot,
    );
  }
}

const Object _projectSentinel = Object();
