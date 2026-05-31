import '../models/project_assets_view_data.dart';

abstract class ProjectAssetsActionHandler {
  void onProjectAssetsBackRequested();

  void onProjectAssetsRefreshRequested();

  void onProjectAssetsTabSelected(String tabId);

  void onProjectAssetsEntrySelected(String entryId);

  void onProjectAssetsReferenceSelected(String referenceKey);

  void onProjectAssetsNewRequested();

  void onProjectAssetsSaveStyleRequested(
    StyleProfileEditorRequestViewData request,
  );

  void onProjectAssetsSaveExpressionConstraintBindingRequested(
    ExpressionConstraintBindingEditorRequestViewData request,
  );

  void onProjectAssetsRemoveExpressionConstraintBindingRequested(
    String profileId,
  );

  void onProjectAssetsSaveForeshadowRequested(
    ForeshadowRecordEditorRequestViewData request,
  );

  void onProjectAssetsDeleteRequested({
    required String kind,
    required String id,
  });

  void onProjectAssetsImportBundleRequested(
    ProjectAssetBundleImportRequestViewData request,
  );

  void onProjectAssetsExportBundleRequested(
    ProjectAssetBundleExportRequestViewData request,
  );
}
