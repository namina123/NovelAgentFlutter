import '../information/information_link.dart';
import '../project/project_descriptor.dart';

abstract class InformationLinkRepository {
  Future<void> appendInformationLink(
    ProjectDescriptor project,
    InformationLink link,
  );

  Future<InformationLink?> readInformationLink(
    ProjectDescriptor project, {
    required String linkId,
  });

  Future<List<InformationLink>> listInformationLinks(
    ProjectDescriptor project, {
    String? linkType,
    String? sourceRefId,
    String? targetRefId,
  });

  Future<void> updateInformationLink(
    ProjectDescriptor project,
    InformationLink link,
  );
}
