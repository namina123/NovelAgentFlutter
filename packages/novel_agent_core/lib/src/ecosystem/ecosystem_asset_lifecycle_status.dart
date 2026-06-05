enum EcosystemAssetLifecycleStatus {
  proposal('proposal'),
  validated('validated'),
  confirmed('confirmed'),
  installed('installed'),
  rejected('rejected');

  const EcosystemAssetLifecycleStatus(this.id);

  final String id;

  static EcosystemAssetLifecycleStatus fromId(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final value in EcosystemAssetLifecycleStatus.values) {
      if (value.id == clean) {
        return value;
      }
    }
    return EcosystemAssetLifecycleStatus.proposal;
  }
}
