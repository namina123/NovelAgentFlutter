import 'ecosystem_editor_action_handler.dart';
import '../models/ecosystem_import_command_view_data.dart';

abstract class AgentEcosystemActionHandler
    implements EcosystemEditorActionHandler {
  void onAgentEcosystemBackRequested();

  void onEcosystemRefreshRequested();

  void onImportEcosystemPackageRequested();

  void onEcosystemImportDismissed();

  void onEcosystemImportSubmitted(EcosystemImportRequestViewData request);

  void onGenerateIndexRequested();

  void onEcosystemTabSelected(String tabId);

  void onEcosystemEntrySelected(String entryId);

  void onOpenEcosystemEntrySourceRequested(String entryId);

  void onEditEcosystemEntryRequested(String entryId);

  void onCreateAgentRequested();

  void onCreateSkillRequested();

  void onCreateSkillGroupRequested();

  void onCreateAgentGroupRequested();
}
