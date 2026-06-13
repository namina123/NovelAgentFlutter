import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'reference_substrate_database_migrator.dart';
import 'reference_substrate_database_opener.dart';

class SqliteReferenceEvidenceSubstrate implements ReferenceEvidenceSubstrate {
  SqliteReferenceEvidenceSubstrate({
    required String substrateRootPath,
    ReferenceSubstrateDatabaseOpener? databaseOpener,
    ReferenceSubstrateDatabaseMigrator? migrator,
    ReferenceEntrySearchTextBuilderService? searchTextBuilderService,
  }) : _substrateRootPath = substrateRootPath,
       _databaseOpener = databaseOpener ?? ReferenceSubstrateDatabaseOpener(),
       _migrator = migrator ?? const ReferenceSubstrateDatabaseMigrator(),
       _searchTextBuilderService =
           searchTextBuilderService ??
           const ReferenceEntrySearchTextBuilderService();

  final String _substrateRootPath;
  final ReferenceSubstrateDatabaseOpener _databaseOpener;
  final ReferenceSubstrateDatabaseMigrator _migrator;
  final ReferenceEntrySearchTextBuilderService _searchTextBuilderService;

  @override
  Future<List<ReferenceEntryRecord>> listEntries({
    String? packageId,
    String? packageVersionId,
    String? entryKind,
  }) async {
    final database = _open();
    try {
      final whereClauses = <String>[];
      final parameters = <Object?>[];
      if (packageId != null && packageId.trim().isNotEmpty) {
        whereClauses.add('package_id = ?');
        parameters.add(packageId);
      }
      if (packageVersionId != null && packageVersionId.trim().isNotEmpty) {
        whereClauses.add('package_version_id = ?');
        parameters.add(packageVersionId);
      }
      if (entryKind != null && entryKind.trim().isNotEmpty) {
        whereClauses.add('entry_kind = ?');
        parameters.add(entryKind);
      }
      final sql = StringBuffer()..write('SELECT * FROM reference_entry');
      if (whereClauses.isNotEmpty) {
        sql
          ..write(' WHERE ')
          ..write(whereClauses.join(' AND '));
      }
      sql.write(
        ' ORDER BY package_id, package_version_id, entry_namespace, entry_id',
      );
      final rows = database.select(sql.toString(), parameters);
      return rows.map(_mapEntry).toList(growable: false);
    } finally {
      database.dispose();
    }
  }

  @override
  Future<List<ReferencePackageRecord>> listPackages({
    String? packageKind,
  }) async {
    final database = _open();
    try {
      final rows = packageKind == null || packageKind.trim().isEmpty
          ? database.select('''
              SELECT *
              FROM reference_package
              ORDER BY package_kind, package_id
              ''')
          : database.select(
              '''
              SELECT *
              FROM reference_package
              WHERE package_kind = ?
              ORDER BY package_id
              ''',
              <Object?>[packageKind],
            );
      return rows.map(_mapPackage).toList(growable: false);
    } finally {
      database.dispose();
    }
  }

  @override
  Future<List<ReferenceSourceAssetLinkRecord>> listSourceAssetLinks({
    String? packageId,
    String? packageVersionId,
    String? entryId,
    String? sourceAssetId,
  }) async {
    final database = _open();
    try {
      final whereClauses = <String>[];
      final parameters = <Object?>[];
      if (packageId != null && packageId.trim().isNotEmpty) {
        whereClauses.add('link.package_id = ?');
        parameters.add(packageId);
      }
      if (packageVersionId != null && packageVersionId.trim().isNotEmpty) {
        whereClauses.add('link.package_version_id = ?');
        parameters.add(packageVersionId);
      }
      if (entryId != null && entryId.trim().isNotEmpty) {
        whereClauses.add('link.entry_id = ?');
        parameters.add(entryId);
      }
      if (sourceAssetId != null && sourceAssetId.trim().isNotEmpty) {
        whereClauses.add('link.source_asset_id = ?');
        parameters.add(sourceAssetId);
      }
      final sql = StringBuffer()
        ..write('''
          SELECT
            asset.source_asset_id,
            asset.source_kind,
            asset.display_name,
            asset.resolver_uri,
            asset.local_hint_path,
            asset.metadata_json AS asset_metadata_json,
            link.package_id,
            link.package_version_id,
            link.entry_id,
            link.relation_role,
            link.metadata_json AS link_metadata_json
          FROM reference_entry_source_asset link
          INNER JOIN reference_source_asset asset
            ON asset.source_asset_id = link.source_asset_id
        ''');
      if (whereClauses.isNotEmpty) {
        sql
          ..write(' WHERE ')
          ..write(whereClauses.join(' AND '));
      }
      sql.write(
        ' ORDER BY link.package_id, link.package_version_id, link.entry_id, link.relation_role, asset.source_asset_id',
      );
      final rows = database.select(sql.toString(), parameters);
      return rows
          .map((row) {
            return ReferenceSourceAssetLinkRecord(
              sourceAsset: SourceAssetIdentity.fromJson(<String, Object?>{
                'source_asset_id': row['source_asset_id'],
                'source_kind': row['source_kind'],
                'display_name': row['display_name'],
                'resolver_uri': row['resolver_uri'],
                'local_hint_path': row['local_hint_path'],
                'metadata': _decodeJsonMap(row['asset_metadata_json']),
              }),
              packageId: row['package_id']?.toString() ?? '',
              packageVersionId: row['package_version_id']?.toString() ?? '',
              entryId: row['entry_id']?.toString() ?? '',
              relationRole: row['relation_role']?.toString() ?? '',
              metadata: _decodeJsonMap(row['link_metadata_json']),
            );
          })
          .toList(growable: false);
    } finally {
      database.dispose();
    }
  }

  @override
  Future<ReferencePackageRecord?> readPackage(String packageId) async {
    final database = _open();
    try {
      final rows = database.select(
        '''
        SELECT *
        FROM reference_package
        WHERE package_id = ?
        LIMIT 1
        ''',
        <Object?>[packageId],
      );
      if (rows.isEmpty) {
        return null;
      }
      return _mapPackage(rows.first);
    } finally {
      database.dispose();
    }
  }

  @override
  Future<ReferencePackageSnapshot?> readPackageSnapshot({
    required String packageId,
    required String packageVersionId,
  }) async {
    final database = _open();
    try {
      final packageRows = database.select(
        '''
        SELECT *
        FROM reference_package
        WHERE package_id = ?
        LIMIT 1
        ''',
        <Object?>[packageId],
      );
      final versionRows = database.select(
        '''
        SELECT *
        FROM reference_package_version
        WHERE package_id = ? AND package_version_id = ?
        LIMIT 1
        ''',
        <Object?>[packageId, packageVersionId],
      );
      if (packageRows.isEmpty || versionRows.isEmpty) {
        return null;
      }
      final entryRows = database.select(
        '''
        SELECT *
        FROM reference_entry
        WHERE package_id = ? AND package_version_id = ?
        ORDER BY entry_namespace, entry_id
        ''',
        <Object?>[packageId, packageVersionId],
      );
      final dependencyRows = database.select(
        '''
        SELECT *
        FROM reference_dependency
        WHERE package_version_id = ?
        ORDER BY dependency_package_id, dependency_version_id
        ''',
        <Object?>[packageVersionId],
      );
      final promotionRows = database.select(
        '''
        SELECT *
        FROM reference_promotion_record
        WHERE target_package_id = ? AND target_package_version_id = ?
        ORDER BY promoted_at, promotion_id
        ''',
        <Object?>[packageId, packageVersionId],
      );
      return ReferencePackageSnapshot(
        packageRecord: _mapPackage(packageRows.first),
        packageVersionRecord: _mapVersion(versionRows.first),
        entries: entryRows.map(_mapEntry).toList(growable: false),
        dependencies: dependencyRows
            .map(_mapDependency)
            .toList(growable: false),
        promotionRecords: promotionRows
            .map(_mapPromotionRecord)
            .toList(growable: false),
      );
    } finally {
      database.dispose();
    }
  }

  @override
  Future<ReferenceEvidenceBatchExecutionState?> readBatchExecutionState({
    required String packageId,
    required String packageVersionId,
  }) async {
    final database = _open();
    try {
      final rows = database.select(
        '''
        SELECT *
        FROM reference_extraction_batch_state
        WHERE package_id = ? AND package_version_id = ?
        LIMIT 1
        ''',
        <Object?>[packageId, packageVersionId],
      );
      if (rows.isEmpty) {
        return null;
      }
      final row = rows.first;
      return ReferenceEvidenceBatchExecutionState.fromJson(<String, Object?>{
        'package_id': row['package_id'],
        'package_version_id': row['package_version_id'],
        'batch_plan': _decodeJsonMap(row['batch_plan_json']),
        'batch_progress': _decodeJsonMap(row['batch_progress_json']),
        'coverage_state': _decodeOptionalJsonMap(row['coverage_state_json']),
        'coverage_ledger': _decodeOptionalJsonMap(row['coverage_ledger_json']),
        'updated_at': row['updated_at'],
        'metadata': _decodeJsonMap(row['metadata_json']),
      });
    } finally {
      database.dispose();
    }
  }

  @override
  Future<ReferenceEvidenceContinuityLedger?> readContinuityLedger({
    required String packageId,
    required String packageVersionId,
  }) async {
    final database = _open();
    try {
      final headerRows = database.select(
        '''
        SELECT updated_at, metadata_json
        FROM reference_continuity_ledger
        WHERE package_id = ? AND package_version_id = ?
        LIMIT 1
        ''',
        <Object?>[packageId, packageVersionId],
      );
      final clusterRows = database.select(
        '''
        SELECT cluster_json
        FROM reference_continuity_conflict_cluster
        WHERE package_id = ? AND package_version_id = ?
        ORDER BY cluster_id
        ''',
        <Object?>[packageId, packageVersionId],
      );
      final decisionRows = database.select(
        '''
        SELECT decision_json
        FROM reference_canon_decision
        WHERE package_id = ? AND package_version_id = ?
        ORDER BY decision_id
        ''',
        <Object?>[packageId, packageVersionId],
      );
      final alertRows = database.select(
        '''
        SELECT alert_json
        FROM reference_continuity_review_alert
        WHERE package_id = ? AND package_version_id = ?
        ORDER BY alert_id
        ''',
        <Object?>[packageId, packageVersionId],
      );
      if (headerRows.isEmpty &&
          clusterRows.isEmpty &&
          decisionRows.isEmpty &&
          alertRows.isEmpty) {
        return null;
      }
      final header = headerRows.isEmpty ? null : headerRows.first;
      return ReferenceEvidenceContinuityLedger.fromJson(<String, Object?>{
        'package_id': packageId,
        'package_version_id': packageVersionId,
        'conflict_clusters': clusterRows
            .map((row) => _decodeJsonMap(row['cluster_json']))
            .toList(growable: false),
        'canon_decisions': decisionRows
            .map((row) => _decodeJsonMap(row['decision_json']))
            .toList(growable: false),
        'review_alerts': alertRows
            .map((row) => _decodeJsonMap(row['alert_json']))
            .toList(growable: false),
        'updated_at': header?['updated_at'],
        'metadata': header == null
            ? const <String, Object?>{}
            : _decodeJsonMap(header['metadata_json']),
      });
    } finally {
      database.dispose();
    }
  }

  @override
  Future<ReferenceQueryResult> queryEntries(ReferenceQuery query) async {
    final database = _open();
    try {
      final whereClauses = <String>['search_text LIKE ?'];
      final parameters = <Object?>['%${query.queryText.toLowerCase()}%'];
      if (query.packageIds.isNotEmpty) {
        whereClauses.add(
          'package_id IN (${List.filled(query.packageIds.length, '?').join(', ')})',
        );
        parameters.addAll(query.packageIds);
      }
      if (query.entryKinds.isNotEmpty) {
        whereClauses.add(
          'entry_kind IN (${List.filled(query.entryKinds.length, '?').join(', ')})',
        );
        parameters.addAll(query.entryKinds);
      }
      final rows = database.select(
        '''
        SELECT *
        FROM reference_entry
        WHERE ${whereClauses.join(' AND ')}
        ORDER BY package_id, package_version_id, entry_id
        LIMIT ?
        ''',
        <Object?>[...parameters, query.maxResults],
      );
      return ReferenceQueryResult(
        entries: rows.map(_mapEntry).toList(growable: false),
        totalCount: rows.length,
        truncated: rows.length >= query.maxResults,
      );
    } finally {
      database.dispose();
    }
  }

  @override
  Future<void> upsertPackageSnapshot(ReferencePackageSnapshot snapshot) async {
    final database = _open();
    try {
      database.execute('BEGIN IMMEDIATE TRANSACTION;');
      database.execute(
        '''
        INSERT OR REPLACE INTO reference_package (
          package_id,
          package_kind,
          display_name,
          package_namespace,
          source_language,
          target_language,
          description,
          latest_version_id,
          lifecycle_status,
          source_summary,
          license_summary,
          created_at,
          updated_at,
          metadata_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          snapshot.packageRecord.packageId,
          snapshot.packageRecord.packageKind,
          snapshot.packageRecord.displayName,
          snapshot.packageRecord.packageNamespace,
          snapshot.packageRecord.sourceLanguage,
          snapshot.packageRecord.targetLanguage,
          snapshot.packageRecord.description,
          snapshot.packageRecord.latestVersionId,
          snapshot.packageRecord.lifecycleStatus,
          snapshot.packageRecord.sourceSummary,
          snapshot.packageRecord.licenseSummary,
          snapshot.packageRecord.createdAt,
          snapshot.packageRecord.updatedAt,
          jsonEncode(snapshot.packageRecord.metadata),
        ],
      );
      database.execute(
        '''
        INSERT OR REPLACE INTO reference_package_version (
          package_version_id,
          package_id,
          version_label,
          created_at,
          created_by,
          source_summary,
          license_summary,
          dependency_summary,
          integrity_hash,
          metadata_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          snapshot.packageVersionRecord.packageVersionId,
          snapshot.packageVersionRecord.packageId,
          snapshot.packageVersionRecord.versionLabel,
          snapshot.packageVersionRecord.createdAt,
          snapshot.packageVersionRecord.createdBy,
          snapshot.packageVersionRecord.sourceSummary,
          snapshot.packageVersionRecord.licenseSummary,
          snapshot.packageVersionRecord.dependencySummary,
          snapshot.packageVersionRecord.integrityHash,
          jsonEncode(snapshot.packageVersionRecord.metadata),
        ],
      );
      database.execute(
        'DELETE FROM reference_entry WHERE package_version_id = ?',
        <Object?>[snapshot.packageVersionRecord.packageVersionId],
      );
      database.execute(
        'DELETE FROM reference_dependency WHERE package_version_id = ?',
        <Object?>[snapshot.packageVersionRecord.packageVersionId],
      );
      database.execute(
        'DELETE FROM reference_entry_source_asset WHERE package_version_id = ?',
        <Object?>[snapshot.packageVersionRecord.packageVersionId],
      );
      for (final entry in snapshot.entries) {
        database.execute(
          '''
          INSERT OR REPLACE INTO reference_entry (
            entry_id,
            package_id,
            package_version_id,
            entry_namespace,
            entry_kind,
            title,
            summary,
            payload_json,
            source_refs_json,
            evidence_refs_json,
            tags_json,
            attachments_json,
            activation_policy_json,
            usage_policy_json,
            confidence,
            lifecycle_status,
            search_text,
            metadata_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            entry.entryId,
            entry.packageId,
            entry.packageVersionId,
            entry.entryNamespace,
            entry.entryKind,
            entry.title,
            entry.summary,
            jsonEncode(entry.payload),
            jsonEncode(
              entry.sourceRefs
                  .map((item) => item.toJson())
                  .toList(growable: false),
            ),
            jsonEncode(
              entry.evidenceRefs
                  .map((item) => item.toJson())
                  .toList(growable: false),
            ),
            jsonEncode(entry.tags),
            jsonEncode(
              entry.attachments
                  .map((item) => item.toJson())
                  .toList(growable: false),
            ),
            jsonEncode(entry.activationPolicy.toJson()),
            jsonEncode(entry.usagePolicy.toJson()),
            entry.confidence,
            entry.lifecycleStatus,
            _searchTextBuilderService.build(entry),
            jsonEncode(entry.metadata),
          ],
        );
      }
      final sourceLinks = _buildSourceAssetLinks(snapshot);
      final sourceAssetsById = <String, SourceAssetIdentity>{
        for (final link in sourceLinks)
          link.sourceAsset.sourceAssetId: link.sourceAsset,
      };
      for (final sourceAsset in sourceAssetsById.values) {
        database.execute(
          '''
          INSERT OR REPLACE INTO reference_source_asset (
            source_asset_id,
            source_kind,
            display_name,
            resolver_uri,
            local_hint_path,
            metadata_json
          ) VALUES (?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            sourceAsset.sourceAssetId,
            sourceAsset.sourceKind,
            sourceAsset.displayName,
            sourceAsset.resolverUri,
            sourceAsset.localHintPath,
            jsonEncode(sourceAsset.metadata),
          ],
        );
      }
      for (var index = 0; index < sourceLinks.length; index += 1) {
        final link = sourceLinks[index];
        database.execute(
          '''
          INSERT OR REPLACE INTO reference_entry_source_asset (
            entry_id,
            package_id,
            package_version_id,
            source_asset_id,
            relation_role,
            relation_index,
            metadata_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            link.entryId,
            link.packageId,
            link.packageVersionId,
            link.sourceAsset.sourceAssetId,
            link.relationRole,
            index,
            jsonEncode(link.metadata),
          ],
        );
      }
      for (final dependency in snapshot.dependencies) {
        database.execute(
          '''
          INSERT OR REPLACE INTO reference_dependency (
            package_version_id,
            dependency_package_id,
            dependency_version_id,
            relationship_kind,
            metadata_json
          ) VALUES (?, ?, ?, ?, ?)
          ''',
          <Object?>[
            dependency.packageVersionId,
            dependency.dependencyPackageId,
            dependency.dependencyVersionId,
            dependency.relationshipKind,
            jsonEncode(dependency.metadata),
          ],
        );
      }
      for (final promotion in snapshot.promotionRecords) {
        database.execute(
          '''
          INSERT OR REPLACE INTO reference_promotion_record (
            promotion_id,
            source_project_id,
            source_artifact_kind,
            source_artifact_id,
            target_package_id,
            target_package_version_id,
            target_entry_id,
            promoted_at,
            promoted_by,
            metadata_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            promotion.promotionId,
            promotion.sourceProjectId,
            promotion.sourceArtifactKind,
            promotion.sourceArtifactId,
            promotion.targetPackageId,
            promotion.targetPackageVersionId,
            promotion.targetEntryId,
            promotion.promotedAt,
            promotion.promotedBy,
            jsonEncode(promotion.metadata),
          ],
        );
      }
      database.execute('COMMIT;');
    } catch (_) {
      database.execute('ROLLBACK;');
      rethrow;
    } finally {
      database.dispose();
    }
  }

  @override
  Future<void> upsertBatchExecutionState(
    ReferenceEvidenceBatchExecutionState state,
  ) async {
    final database = _open();
    try {
      database.execute(
        '''
        INSERT OR REPLACE INTO reference_extraction_batch_state (
          package_id,
          package_version_id,
          plan_id,
          batch_plan_json,
          batch_progress_json,
          coverage_state_json,
          coverage_ledger_json,
          updated_at,
          metadata_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          state.packageId,
          state.packageVersionId,
          state.batchPlan.planId,
          jsonEncode(state.batchPlan.toJson()),
          jsonEncode(state.batchProgress.toJson()),
          state.coverageState == null
              ? ''
              : jsonEncode(state.coverageState!.toJson()),
          state.coverageLedger == null
              ? ''
              : jsonEncode(state.coverageLedger!.toJson()),
          state.updatedAt.trim().isEmpty
              ? DateTime.now().toIso8601String()
              : state.updatedAt,
          jsonEncode(state.metadata),
        ],
      );
    } finally {
      database.dispose();
    }
  }

  @override
  Future<void> upsertContinuityLedger(
    ReferenceEvidenceContinuityLedger ledger,
  ) async {
    final database = _open();
    try {
      database.execute('BEGIN IMMEDIATE TRANSACTION;');
      database.execute(
        '''
        INSERT OR REPLACE INTO reference_continuity_ledger (
          package_id,
          package_version_id,
          updated_at,
          metadata_json
        ) VALUES (?, ?, ?, ?)
        ''',
        <Object?>[
          ledger.packageId,
          ledger.packageVersionId,
          ledger.updatedAt.trim().isEmpty
              ? DateTime.now().toIso8601String()
              : ledger.updatedAt,
          jsonEncode(ledger.metadata),
        ],
      );
      database.execute(
        '''
        DELETE FROM reference_continuity_conflict_cluster
        WHERE package_id = ? AND package_version_id = ?
        ''',
        <Object?>[ledger.packageId, ledger.packageVersionId],
      );
      database.execute(
        '''
        DELETE FROM reference_canon_decision
        WHERE package_id = ? AND package_version_id = ?
        ''',
        <Object?>[ledger.packageId, ledger.packageVersionId],
      );
      database.execute(
        '''
        DELETE FROM reference_continuity_review_alert
        WHERE package_id = ? AND package_version_id = ?
        ''',
        <Object?>[ledger.packageId, ledger.packageVersionId],
      );
      for (final cluster in ledger.conflictClusters) {
        database.execute(
          '''
          INSERT OR REPLACE INTO reference_continuity_conflict_cluster (
            cluster_id,
            package_id,
            package_version_id,
            subject_ref_type,
            subject_ref_id,
            attribute_key,
            classification,
            cluster_status,
            current_decision_id,
            cluster_json,
            metadata_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            cluster.clusterId,
            ledger.packageId,
            ledger.packageVersionId,
            cluster.subjectRef.refType,
            cluster.subjectRef.refId,
            cluster.attributeKey,
            cluster.classification,
            cluster.clusterStatus,
            cluster.currentDecisionId,
            jsonEncode(cluster.toJson()),
            jsonEncode(cluster.metadata),
          ],
        );
      }
      for (final decision in ledger.canonDecisions) {
        database.execute(
          '''
          INSERT OR REPLACE INTO reference_canon_decision (
            decision_id,
            package_id,
            package_version_id,
            cluster_id,
            decision_kind,
            decided_at,
            review_required,
            decision_json,
            metadata_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            decision.decisionId,
            ledger.packageId,
            ledger.packageVersionId,
            decision.clusterId,
            decision.decisionKind,
            decision.decidedAt,
            decision.reviewRequired ? 1 : 0,
            jsonEncode(decision.toJson()),
            jsonEncode(decision.metadata),
          ],
        );
      }
      for (final alert in ledger.reviewAlerts) {
        database.execute(
          '''
          INSERT OR REPLACE INTO reference_continuity_review_alert (
            alert_id,
            package_id,
            package_version_id,
            cluster_id,
            related_decision_id,
            alert_kind,
            severity,
            requires_manual_review,
            alert_json,
            metadata_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            alert.alertId,
            ledger.packageId,
            ledger.packageVersionId,
            alert.clusterId,
            alert.relatedDecisionId,
            alert.alertKind,
            alert.severity,
            alert.requiresManualReview ? 1 : 0,
            jsonEncode(alert.toJson()),
            jsonEncode(alert.metadata),
          ],
        );
      }
      database.execute('COMMIT;');
    } catch (_) {
      database.execute('ROLLBACK;');
      rethrow;
    } finally {
      database.dispose();
    }
  }

  Database _open() {
    final database = _databaseOpener.open(_substrateRootPath);
    _migrator.migrate(database);
    return database;
  }

  ReferencePackageRecord _mapPackage(Row row) {
    return ReferencePackageRecord.fromJson(<String, Object?>{
      'package_id': row['package_id'],
      'package_kind': row['package_kind'],
      'display_name': row['display_name'],
      'package_namespace': row['package_namespace'],
      'source_language': row['source_language'],
      'target_language': row['target_language'],
      'description': row['description'],
      'latest_version_id': row['latest_version_id'],
      'lifecycle_status': row['lifecycle_status'],
      'source_summary': row['source_summary'],
      'license_summary': row['license_summary'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      'metadata': _decodeJsonMap(row['metadata_json']),
    });
  }

  ReferencePackageVersionRecord _mapVersion(Row row) {
    return ReferencePackageVersionRecord.fromJson(<String, Object?>{
      'package_version_id': row['package_version_id'],
      'package_id': row['package_id'],
      'version_label': row['version_label'],
      'created_at': row['created_at'],
      'created_by': row['created_by'],
      'source_summary': row['source_summary'],
      'license_summary': row['license_summary'],
      'dependency_summary': row['dependency_summary'],
      'integrity_hash': row['integrity_hash'],
      'metadata': _decodeJsonMap(row['metadata_json']),
    });
  }

  ReferenceEntryRecord _mapEntry(Row row) {
    return ReferenceEntryRecord.fromJson(<String, Object?>{
      'entry_id': row['entry_id'],
      'package_id': row['package_id'],
      'package_version_id': row['package_version_id'],
      'entry_namespace': row['entry_namespace'],
      'entry_kind': row['entry_kind'],
      'title': row['title'],
      'summary': row['summary'],
      'payload': _decodeJsonMap(row['payload_json']),
      'source_refs': _decodeJsonList(row['source_refs_json']),
      'evidence_refs': _decodeJsonList(row['evidence_refs_json']),
      'tags': _decodeJsonList(row['tags_json']),
      'attachments': _decodeJsonList(row['attachments_json']),
      'activation_policy': _decodeJsonMap(row['activation_policy_json']),
      'usage_policy': _decodeJsonMap(row['usage_policy_json']),
      'confidence': row['confidence'],
      'lifecycle_status': row['lifecycle_status'],
      'metadata': _decodeJsonMap(row['metadata_json']),
    });
  }

  ReferenceDependencyRecord _mapDependency(Row row) {
    return ReferenceDependencyRecord.fromJson(<String, Object?>{
      'package_version_id': row['package_version_id'],
      'dependency_package_id': row['dependency_package_id'],
      'dependency_version_id': row['dependency_version_id'],
      'relationship_kind': row['relationship_kind'],
      'metadata': _decodeJsonMap(row['metadata_json']),
    });
  }

  ReferencePromotionRecord _mapPromotionRecord(Row row) {
    return ReferencePromotionRecord.fromJson(<String, Object?>{
      'promotion_id': row['promotion_id'],
      'source_project_id': row['source_project_id'],
      'source_artifact_kind': row['source_artifact_kind'],
      'source_artifact_id': row['source_artifact_id'],
      'target_package_id': row['target_package_id'],
      'target_package_version_id': row['target_package_version_id'],
      'target_entry_id': row['target_entry_id'],
      'promoted_at': row['promoted_at'],
      'promoted_by': row['promoted_by'],
      'metadata': _decodeJsonMap(row['metadata_json']),
    });
  }

  Map<String, Object?> _decodeJsonMap(Object? value) {
    return ValueReaders.mapValue(jsonDecode(value?.toString() ?? '{}'));
  }

  Map<String, Object?> _decodeOptionalJsonMap(Object? value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return const <String, Object?>{};
    }
    return ValueReaders.mapValue(jsonDecode(raw));
  }

  List<Object?> _decodeJsonList(Object? value) {
    return ValueReaders.objectList(jsonDecode(value?.toString() ?? '[]'));
  }

  List<_SourceAssetLink> _buildSourceAssetLinks(
    ReferencePackageSnapshot snapshot,
  ) {
    final result = <_SourceAssetLink>[];
    for (final entry in snapshot.entries) {
      for (final sourceRef in entry.sourceRefs) {
        final sourceAsset = sourceRef.sourceIdentity;
        if (sourceAsset.sourceAssetId.trim().isEmpty) {
          continue;
        }
        result.add(
          _SourceAssetLink(
            sourceAsset: sourceAsset,
            packageId: entry.packageId,
            packageVersionId: entry.packageVersionId,
            entryId: entry.entryId,
            relationRole: 'entry_source_ref',
            metadata: <String, Object?>{
              'source_authority': sourceRef.sourceAuthority,
              'role_authority': sourceRef.roleAuthority,
              'research_depth': sourceRef.researchDepth,
            },
          ),
        );
      }
      for (final evidenceRef in entry.evidenceRefs) {
        final sourceRef = evidenceRef.sourceRef;
        if (sourceRef == null) {
          continue;
        }
        final sourceAsset = sourceRef.sourceIdentity;
        if (sourceAsset.sourceAssetId.trim().isEmpty) {
          continue;
        }
        result.add(
          _SourceAssetLink(
            sourceAsset: sourceAsset,
            packageId: entry.packageId,
            packageVersionId: entry.packageVersionId,
            entryId: entry.entryId,
            relationRole: 'evidence_source_ref',
            metadata: <String, Object?>{
              'evidence_id': evidenceRef.evidenceId,
              'evidence_type': evidenceRef.evidenceType,
              'target_ref_id': evidenceRef.targetRef?.refId ?? '',
            },
          ),
        );
      }
    }
    return result;
  }
}

class _SourceAssetLink {
  const _SourceAssetLink({
    required this.sourceAsset,
    required this.packageId,
    required this.packageVersionId,
    required this.entryId,
    required this.relationRole,
    this.metadata = const <String, Object?>{},
  });

  final SourceAssetIdentity sourceAsset;
  final String packageId;
  final String packageVersionId;
  final String entryId;
  final String relationRole;
  final Map<String, Object?> metadata;
}
