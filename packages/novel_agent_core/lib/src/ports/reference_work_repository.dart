import '../information/reference_work_record.dart';
import '../project/project_descriptor.dart';

abstract class ReferenceWorkRepository {
  Future<void> appendReferenceWork(
    ProjectDescriptor project,
    ReferenceWorkRecord record,
  );

  Future<ReferenceWorkRecord?> readReferenceWork(
    ProjectDescriptor project, {
    required String referenceWorkId,
  });

  Future<List<ReferenceWorkRecord>> listReferenceWorks(
    ProjectDescriptor project, {
    String? relationshipToProject,
  });

  Future<void> updateReferenceWork(
    ProjectDescriptor project,
    ReferenceWorkRecord record,
  );
}
