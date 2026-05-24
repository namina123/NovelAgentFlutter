import '../models/ecosystem_editor_view_data.dart';

abstract class EcosystemEditorActionHandler {
  void onEcosystemEditorDismissed();

  void onEcosystemEditorSubmitted(EcosystemEditorRequestViewData request);

  void onEcosystemEditorDeleteRequested(EcosystemEditorRequestViewData request);
}
