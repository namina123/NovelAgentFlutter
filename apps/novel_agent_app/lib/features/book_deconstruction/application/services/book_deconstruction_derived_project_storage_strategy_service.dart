import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionDerivedProjectStorageStrategyService {
  const BookDeconstructionDerivedProjectStorageStrategyService({
    ProjectTypeCatalogService projectTypeCatalogService =
        const ProjectTypeCatalogService(),
  }) : _projectTypeCatalogService = projectTypeCatalogService;

  final ProjectTypeCatalogService _projectTypeCatalogService;

  ProjectStorageStrategy resolve({
    required String targetProjectTypeId,
    required ProjectStorageStrategy preferredStrategy,
  }) {
    final definition = _projectTypeCatalogService.definitionOf(
      targetProjectTypeId,
    );
    final supported = definition.supportedStorageStrategies;
    if (supported.contains(preferredStrategy)) {
      return preferredStrategy;
    }
    return supported.isEmpty
        ? ProjectStorageStrategy.markdownProjectStore
        : supported.first;
  }
}
