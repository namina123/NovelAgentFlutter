import 'package:sqlite3/sqlite3.dart';

class ReferenceSubstrateDatabaseMigrator {
  static const String schemaVersion = '3';

  const ReferenceSubstrateDatabaseMigrator();

  void migrate(Database database) {
    database.execute('PRAGMA foreign_keys = ON;');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_substrate_meta (
        meta_key TEXT PRIMARY KEY,
        value_text TEXT NOT NULL
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_package (
        package_id TEXT PRIMARY KEY,
        package_kind TEXT NOT NULL,
        display_name TEXT NOT NULL,
        package_namespace TEXT NOT NULL,
        source_language TEXT NOT NULL,
        target_language TEXT NOT NULL,
        description TEXT NOT NULL,
        latest_version_id TEXT NOT NULL,
        lifecycle_status TEXT NOT NULL,
        source_summary TEXT NOT NULL,
        license_summary TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        metadata_json TEXT NOT NULL
      );
      ''');
    _addColumnIfMissing(
      database,
      tableName: 'reference_package',
      columnName: 'source_language',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    _addColumnIfMissing(
      database,
      tableName: 'reference_package',
      columnName: 'target_language',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_package_version (
        package_version_id TEXT PRIMARY KEY,
        package_id TEXT NOT NULL,
        version_label TEXT NOT NULL,
        created_at TEXT NOT NULL,
        created_by TEXT NOT NULL,
        source_summary TEXT NOT NULL,
        license_summary TEXT NOT NULL,
        dependency_summary TEXT NOT NULL,
        integrity_hash TEXT NOT NULL,
        metadata_json TEXT NOT NULL,
        FOREIGN KEY(package_id) REFERENCES reference_package(package_id)
          ON DELETE CASCADE
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_entry (
        entry_id TEXT PRIMARY KEY,
        package_id TEXT NOT NULL,
        package_version_id TEXT NOT NULL,
        entry_namespace TEXT NOT NULL,
        entry_kind TEXT NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        source_refs_json TEXT NOT NULL,
        evidence_refs_json TEXT NOT NULL,
        tags_json TEXT NOT NULL,
        attachments_json TEXT NOT NULL,
        activation_policy_json TEXT NOT NULL,
        usage_policy_json TEXT NOT NULL,
        confidence REAL NOT NULL,
        lifecycle_status TEXT NOT NULL,
        search_text TEXT NOT NULL,
        metadata_json TEXT NOT NULL,
        FOREIGN KEY(package_id) REFERENCES reference_package(package_id)
          ON DELETE CASCADE,
        FOREIGN KEY(package_version_id)
          REFERENCES reference_package_version(package_version_id)
          ON DELETE CASCADE
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_dependency (
        package_version_id TEXT NOT NULL,
        dependency_package_id TEXT NOT NULL,
        dependency_version_id TEXT NOT NULL,
        relationship_kind TEXT NOT NULL,
        metadata_json TEXT NOT NULL,
        PRIMARY KEY(package_version_id, dependency_package_id, dependency_version_id),
        FOREIGN KEY(package_version_id)
          REFERENCES reference_package_version(package_version_id)
          ON DELETE CASCADE
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_promotion_record (
        promotion_id TEXT PRIMARY KEY,
        source_project_id TEXT NOT NULL,
        source_artifact_kind TEXT NOT NULL,
        source_artifact_id TEXT NOT NULL,
        target_package_id TEXT NOT NULL,
        target_package_version_id TEXT NOT NULL,
        target_entry_id TEXT NOT NULL,
        promoted_at TEXT NOT NULL,
        promoted_by TEXT NOT NULL,
        metadata_json TEXT NOT NULL
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_source_asset (
        source_asset_id TEXT PRIMARY KEY,
        source_kind TEXT NOT NULL,
        display_name TEXT NOT NULL,
        resolver_uri TEXT NOT NULL,
        local_hint_path TEXT NOT NULL,
        metadata_json TEXT NOT NULL
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_entry_source_asset (
        entry_id TEXT NOT NULL,
        package_id TEXT NOT NULL,
        package_version_id TEXT NOT NULL,
        source_asset_id TEXT NOT NULL,
        relation_role TEXT NOT NULL,
        relation_index INTEGER NOT NULL,
        metadata_json TEXT NOT NULL,
        PRIMARY KEY(entry_id, source_asset_id, relation_role, relation_index),
        FOREIGN KEY(entry_id) REFERENCES reference_entry(entry_id)
          ON DELETE CASCADE,
        FOREIGN KEY(source_asset_id) REFERENCES reference_source_asset(source_asset_id)
          ON DELETE CASCADE
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_extraction_batch_state (
        package_id TEXT NOT NULL,
        package_version_id TEXT NOT NULL,
        plan_id TEXT NOT NULL,
        batch_plan_json TEXT NOT NULL,
        batch_progress_json TEXT NOT NULL,
        coverage_state_json TEXT NOT NULL,
        coverage_ledger_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        metadata_json TEXT NOT NULL,
        PRIMARY KEY(package_id, package_version_id)
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_continuity_conflict_cluster (
        cluster_id TEXT PRIMARY KEY,
        package_id TEXT NOT NULL,
        package_version_id TEXT NOT NULL,
        subject_ref_type TEXT NOT NULL,
        subject_ref_id TEXT NOT NULL,
        attribute_key TEXT NOT NULL,
        classification TEXT NOT NULL,
        cluster_status TEXT NOT NULL,
        current_decision_id TEXT NOT NULL,
        cluster_json TEXT NOT NULL,
        metadata_json TEXT NOT NULL
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_continuity_ledger (
        package_id TEXT NOT NULL,
        package_version_id TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        metadata_json TEXT NOT NULL,
        PRIMARY KEY(package_id, package_version_id)
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_canon_decision (
        decision_id TEXT PRIMARY KEY,
        package_id TEXT NOT NULL,
        package_version_id TEXT NOT NULL,
        cluster_id TEXT NOT NULL,
        decision_kind TEXT NOT NULL,
        decided_at TEXT NOT NULL,
        review_required INTEGER NOT NULL,
        decision_json TEXT NOT NULL,
        metadata_json TEXT NOT NULL
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reference_continuity_review_alert (
        alert_id TEXT PRIMARY KEY,
        package_id TEXT NOT NULL,
        package_version_id TEXT NOT NULL,
        cluster_id TEXT NOT NULL,
        related_decision_id TEXT NOT NULL,
        alert_kind TEXT NOT NULL,
        severity TEXT NOT NULL,
        requires_manual_review INTEGER NOT NULL,
        alert_json TEXT NOT NULL,
        metadata_json TEXT NOT NULL
      );
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_entry_package
      ON reference_entry(package_id, package_version_id);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_entry_kind
      ON reference_entry(entry_kind, entry_namespace);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_entry_search
      ON reference_entry(search_text);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_package_kind
      ON reference_package(package_kind);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_entry_source_asset_package
      ON reference_entry_source_asset(package_id, package_version_id, entry_id);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_entry_source_asset_source
      ON reference_entry_source_asset(source_asset_id, relation_role);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_batch_state_package
      ON reference_extraction_batch_state(package_id, package_version_id);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_conflict_cluster_package
      ON reference_continuity_conflict_cluster(package_id, package_version_id, cluster_status);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_continuity_ledger_package
      ON reference_continuity_ledger(package_id, package_version_id);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_canon_decision_package
      ON reference_canon_decision(package_id, package_version_id, cluster_id);
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reference_review_alert_package
      ON reference_continuity_review_alert(package_id, package_version_id, severity);
      ''');
    database.execute(
      '''
      INSERT OR REPLACE INTO reference_substrate_meta(meta_key, value_text)
      VALUES ('schema_version', ?);
      ''',
      <Object?>[schemaVersion],
    );
  }

  void _addColumnIfMissing(
    Database database, {
    required String tableName,
    required String columnName,
    required String definition,
  }) {
    final rows = database.select('PRAGMA table_info($tableName);');
    final exists = rows.any(
      (row) => row['name']?.toString().trim() == columnName,
    );
    if (exists) {
      return;
    }
    database.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnName $definition;',
    );
  }
}
