class ReferenceSubstratePathService {
  const ReferenceSubstratePathService();

  String databasePath(String substrateRootPath) {
    return '$substrateRootPath/evidence.db';
  }

  String legacyDatabasePath(String substrateRootPath) {
    return '$substrateRootPath/reference_substrate/reference_evidence.db';
  }
}
