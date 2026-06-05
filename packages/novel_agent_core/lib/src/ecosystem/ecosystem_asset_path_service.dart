import '../project/project_entry_path_service.dart';
import 'ecosystem_asset_kind.dart';

class EcosystemAssetPathService {
  EcosystemAssetPathService({ProjectEntryPathService? projectEntryPathService})
    : _projectEntryPathService =
          projectEntryPathService ?? const ProjectEntryPathService();

  final ProjectEntryPathService _projectEntryPathService;

  String proposalPath({
    required EcosystemAssetKind kind,
    required String proposalId,
  }) {
    final cleanProposalId = _safeFileName(
      proposalId,
      fallback: '${kind.id}_proposal',
    );
    return '.novel_agent/ecosystem/proposals/${kind.id}/$cleanProposalId.json';
  }

  String installPath({
    required EcosystemAssetKind kind,
    required String assetId,
  }) {
    final cleanAssetId = _safeFileName(assetId, fallback: 'custom_entry');
    switch (kind) {
      case EcosystemAssetKind.skill:
        return 'skills/$cleanAssetId/SKILL.md';
      case EcosystemAssetKind.skillGroup:
        return 'skill_groups/$cleanAssetId/skill_group.json';
      case EcosystemAssetKind.agent:
        return 'agents/$cleanAssetId/AGENT.md';
      case EcosystemAssetKind.agentGroup:
        return 'agent_groups/$cleanAssetId/agent_group.json';
    }
  }

  String defaultProposalId({
    required EcosystemAssetKind kind,
    required String assetId,
  }) {
    final cleanAssetId = _safeFileName(assetId, fallback: 'custom_entry');
    return '${kind.id}-$cleanAssetId-proposal';
  }

  String _safeFileName(String value, {required String fallback}) {
    return _projectEntryPathService.safeFileName(value, fallback: fallback);
  }
}
