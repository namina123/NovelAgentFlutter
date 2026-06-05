enum EcosystemAssetSourceKind {
  builtin('builtin'),
  nonBuiltin('non_builtin');

  const EcosystemAssetSourceKind(this.id);

  final String id;

  static EcosystemAssetSourceKind fromId(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final value in EcosystemAssetSourceKind.values) {
      if (value.id == clean) {
        return value;
      }
    }
    return EcosystemAssetSourceKind.nonBuiltin;
  }
}
