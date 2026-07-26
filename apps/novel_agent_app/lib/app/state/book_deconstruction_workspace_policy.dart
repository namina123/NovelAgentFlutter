import 'package:novel_agent_core/novel_agent_core.dart';

/// Separates a project's available deconstruction capability from its primary
/// workspace. A transitioned novel keeps the capability as a trait, but
/// should open in its writing workbench.
class BookDeconstructionWorkspacePolicy {
  const BookDeconstructionWorkspacePolicy();

  bool usesDeconstructionAsPrimaryWorkspace(ProjectDescriptor? project) {
    return project?.projectType.trim() ==
        BookDeconstructionConstants.projectTypeId;
  }
}
