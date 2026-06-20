import '../../presentation/models/project_assets_view_data.dart';
import 'project_assets_catalog.dart';

class ProjectAssetsCatalogRefreshResult {
  const ProjectAssetsCatalogRefreshResult({
    required this.catalog,
    required this.availableAgentOptions,
    required this.availableModeOptions,
    required this.availableStageOptions,
    required this.statusMessage,
  });

  final ProjectAssetsCatalog catalog;
  final List<ExpressionConstraintSelectableOptionViewData> availableAgentOptions;
  final List<ExpressionConstraintSelectableOptionViewData> availableModeOptions;
  final List<ExpressionConstraintSelectableOptionViewData> availableStageOptions;
  final String statusMessage;
}
