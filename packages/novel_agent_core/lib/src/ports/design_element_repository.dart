import '../information/design_element_card.dart';
import '../project/project_descriptor.dart';

abstract class DesignElementRepository {
  Future<void> appendDesignElement(
    ProjectDescriptor project,
    DesignElementCard card,
  );

  Future<DesignElementCard?> readDesignElement(
    ProjectDescriptor project, {
    required String designId,
  });

  Future<List<DesignElementCard>> listDesignElements(
    ProjectDescriptor project, {
    String? designNamespace,
  });

  Future<void> updateDesignElement(
    ProjectDescriptor project,
    DesignElementCard card,
  );
}
