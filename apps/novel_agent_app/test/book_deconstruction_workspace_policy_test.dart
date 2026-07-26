import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/state/book_deconstruction_workspace_policy.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  const policy = BookDeconstructionWorkspacePolicy();

  test(
    'pure book-deconstruction project uses the deconstruction workspace',
    () {
      const project = ProjectDescriptor(
        id: 'book-project',
        name: '拆书项目',
        rootPath: 'D:/projects/book-project',
        projectType: BookDeconstructionConstants.projectTypeId,
      );

      expect(policy.usesDeconstructionAsPrimaryWorkspace(project), isTrue);
    },
  );

  test(
    'transitioned writing project keeps its trait without changing primary workspace',
    () {
      const project = ProjectDescriptor(
        id: 'composite-project',
        name: '复合小说项目',
        rootPath: 'D:/projects/composite-project',
        projectType: 'long_novel',
        additionalTraitIds: <String>[BookDeconstructionConstants.projectTypeId],
      );

      expect(policy.usesDeconstructionAsPrimaryWorkspace(project), isFalse);
    },
  );
}
