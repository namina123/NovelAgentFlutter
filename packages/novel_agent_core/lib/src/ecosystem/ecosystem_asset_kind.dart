enum EcosystemAssetKind {
  skill('skill'),
  skillGroup('skill-group'),
  agent('agent'),
  agentGroup('agent-group');

  const EcosystemAssetKind(this.id);

  final String id;

  static EcosystemAssetKind fromId(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final value in EcosystemAssetKind.values) {
      if (value.id == clean) {
        return value;
      }
    }
    return EcosystemAssetKind.skill;
  }
}
