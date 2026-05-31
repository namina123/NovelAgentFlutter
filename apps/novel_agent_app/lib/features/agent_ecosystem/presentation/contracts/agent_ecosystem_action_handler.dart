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

  void onProjectExpressionConstraintsRequested();

  void onProjectSkillLoadoutSkillGroupToggled(
    String agentId,
    String groupId,
    bool selected,
  );

  void onProjectSkillLoadoutExtraSkillToggled(
    String agentId,
    String skillId,
    bool selected,
  );

  void onProjectSkillLoadoutDisabledSkillToggled(
    String agentId,
    String skillId,
    bool disabled,
  );

  void onProjectSkillLoadoutApplyRequested(String agentId);

  void onProjectSkillLoadoutResetRequested(String agentId);

  void onProjectSkillLoadoutHistoryRestoreRequested(
    String agentId,
    String historyEntryId,
  );

  void onProjectSkillLoadoutHistoryCaptureRequested(
    String agentId,
    String title,
  );

  void onProjectSkillLoadoutSaveAsGroupRequested(
    String agentId,
    String groupId,
    String displayName,
    String description,
  );
}
