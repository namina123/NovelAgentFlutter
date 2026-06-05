import 'ecosystem_import_command_view_data.dart';
import 'ecosystem_editor_view_data.dart';
import 'project_skill_loadout_view_data.dart';

class AgentEcosystemViewData {
  const AgentEcosystemViewData({
    required this.activeTabId,
    required this.tabs,
    required this.entries,
    this.statusMessage = '',
    this.importCommand,
    this.editorViewData,
    this.projectSkillLoadoutViewData,
  });

  final String activeTabId;
  final List<EcosystemTabViewData> tabs;
  final List<EcosystemEntryViewData> entries;
  final String statusMessage;
  final EcosystemImportCommandViewData? importCommand;
  final EcosystemEditorViewData? editorViewData;
  final ProjectSkillLoadoutWorkspaceViewData? projectSkillLoadoutViewData;

  factory AgentEcosystemViewData.initial() {
    return const AgentEcosystemViewData(
      activeTabId: 'agents',
      tabs: [
        EcosystemTabViewData(id: 'agents', label: '智能体'),
        EcosystemTabViewData(id: 'skills', label: '技能'),
        EcosystemTabViewData(id: 'skill-groups', label: '技能组'),
        EcosystemTabViewData(id: 'agent-groups', label: '智能体组'),
        EcosystemTabViewData(id: 'skill-loadouts', label: '技能装载'),
      ],
      entries: [],
      statusMessage: '',
      importCommand: null,
      editorViewData: null,
      projectSkillLoadoutViewData: null,
    );
  }

  factory AgentEcosystemViewData.demo() {
    return AgentEcosystemViewData.initial();
  }

  AgentEcosystemViewData copyWith({
    String? activeTabId,
    List<EcosystemTabViewData>? tabs,
    List<EcosystemEntryViewData>? entries,
    String? statusMessage,
    Object? importCommand = _importCommandSentinel,
    Object? editorViewData = _editorViewDataSentinel,
    Object? projectSkillLoadoutViewData = _projectSkillLoadoutSentinel,
  }) {
    // 中文注释: 生态状态通过局部 copy 保持稳定边界，避免某个 tab 行为影响整个应用壳层。
    return AgentEcosystemViewData(
      activeTabId: activeTabId ?? this.activeTabId,
      tabs: tabs ?? this.tabs,
      entries: entries ?? this.entries,
      statusMessage: statusMessage ?? this.statusMessage,
      importCommand: identical(importCommand, _importCommandSentinel)
          ? this.importCommand
          : importCommand as EcosystemImportCommandViewData?,
      editorViewData: identical(editorViewData, _editorViewDataSentinel)
          ? this.editorViewData
          : editorViewData as EcosystemEditorViewData?,
      projectSkillLoadoutViewData:
          identical(projectSkillLoadoutViewData, _projectSkillLoadoutSentinel)
          ? this.projectSkillLoadoutViewData
          : projectSkillLoadoutViewData
                as ProjectSkillLoadoutWorkspaceViewData?,
    );
  }
}

const Object _importCommandSentinel = Object();
const Object _editorViewDataSentinel = Object();
const Object _projectSkillLoadoutSentinel = Object();

class EcosystemTabViewData {
  const EcosystemTabViewData({required this.id, required this.label});

  final String id;
  final String label;
}

class EcosystemEntryViewData {
  const EcosystemEntryViewData({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.description,
    required this.sourcePath,
    required this.projectRelativePath,
    required this.isEditable,
    this.isSelected = false,
    this.metadataRows = const <EcosystemMetadataRow>[],
    this.memberLabels = const <String>[],
    this.permissionBoundarySummary = '',
    this.validationIssues = const <String>[],
    this.canDuplicateBuiltin = false,
  });

  final String id;
  final String kind;
  final String title;
  final String subtitle;
  final String badge;
  final String description;
  final String sourcePath;
  final String projectRelativePath;
  final bool isEditable;
  final bool isSelected;
  final List<EcosystemMetadataRow> metadataRows;
  final List<String> memberLabels;
  final String permissionBoundarySummary;
  final List<String> validationIssues;
  final bool canDuplicateBuiltin;
}

class EcosystemMetadataRow {
  const EcosystemMetadataRow({required this.label, required this.value});

  final String label;
  final String value;
}
