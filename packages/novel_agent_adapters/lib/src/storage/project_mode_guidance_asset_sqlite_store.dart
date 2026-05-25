import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'project_sqlite_path_service.dart';

class ProjectModeGuidanceAssetSqliteStore {
  ProjectModeGuidanceAssetSqliteStore({
    ProjectSqlitePathService? sqlitePathService,
  }) : _sqlitePathService = sqlitePathService ?? ProjectSqlitePathService();

  final ProjectSqlitePathService _sqlitePathService;

  Future<void> save(
    String rootPath,
    ModeGuidanceAssetBundle bundle, {
    required String statePath,
    required String createdAt,
    required String updatedAt,
  }) async {
    // 中文注释: 这里把模式引导衍生出的共享资产拆表投影，供后续查询、图谱和上下文选择直接复用。
    final database = _open(rootPath);
    try {
      _ensureSchema(database);
      database.execute('BEGIN');
      _deleteModeRecords(database, bundle.modeId);
      _insertStyles(
        database,
        bundle,
        statePath: statePath,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      _insertWorlds(
        database,
        bundle,
        statePath: statePath,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      _insertEntities(
        database,
        bundle,
        statePath: statePath,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    } finally {
      database.dispose();
    }
  }

  Database _open(String rootPath) {
    final dbPath = _sqlitePathService.databasePath(rootPath);
    final dbFile = File(dbPath);
    dbFile.parent.createSync(recursive: true);
    return sqlite3.open(dbPath);
  }

  void _deleteModeRecords(Database database, String modeId) {
    final styleIds = database
        .select('SELECT id FROM style_profile WHERE mode_id = ?', <Object?>[
          modeId,
        ])
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final worldIds = database
        .select('SELECT id FROM world_rule_set WHERE mode_id = ?', <Object?>[
          modeId,
        ])
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final entityIds = database
        .select('SELECT id FROM entity_identity WHERE mode_id = ?', <Object?>[
          modeId,
        ])
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    for (final id in styleIds) {
      database.execute(
        'DELETE FROM style_rule WHERE style_profile_id = ?',
        <Object?>[id],
      );
    }
    for (final id in worldIds) {
      database.execute(
        'DELETE FROM world_rule_entry WHERE world_rule_set_id = ?',
        <Object?>[id],
      );
    }
    for (final id in entityIds) {
      database.execute(
        'DELETE FROM entity_alias WHERE entity_id = ?',
        <Object?>[id],
      );
    }
    database.execute('DELETE FROM style_profile WHERE mode_id = ?', <Object?>[
      modeId,
    ]);
    database.execute('DELETE FROM world_rule_set WHERE mode_id = ?', <Object?>[
      modeId,
    ]);
    database.execute('DELETE FROM entity_identity WHERE mode_id = ?', <Object?>[
      modeId,
    ]);
  }

  void _insertStyles(
    Database database,
    ModeGuidanceAssetBundle bundle, {
    required String statePath,
    required String createdAt,
    required String updatedAt,
  }) {
    for (final style in bundle.styleProfiles) {
      database.execute(
        '''
        INSERT INTO style_profile (
          id,
          mode_id,
          display_name,
          summary,
          markdown_path,
          state_path,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          style.id,
          bundle.modeId,
          style.displayName,
          style.summary,
          bundle.markdownPathFor(style.id),
          statePath,
          createdAt,
          updatedAt,
        ],
      );
      for (var index = 0; index < style.guardrails.length; index += 1) {
        database.execute(
          '''
          INSERT INTO style_rule (
            style_profile_id,
            ordinal,
            rule_text
          ) VALUES (?, ?, ?)
          ''',
          <Object?>[style.id, index, style.guardrails[index]],
        );
      }
    }
  }

  void _insertWorlds(
    Database database,
    ModeGuidanceAssetBundle bundle, {
    required String statePath,
    required String createdAt,
    required String updatedAt,
  }) {
    for (final world in bundle.worldRuleSets) {
      database.execute(
        '''
        INSERT INTO world_rule_set (
          id,
          mode_id,
          display_name,
          summary,
          markdown_path,
          state_path,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          world.id,
          bundle.modeId,
          world.displayName,
          world.summary,
          bundle.markdownPathFor(world.id),
          statePath,
          createdAt,
          updatedAt,
        ],
      );
      for (var index = 0; index < world.rules.length; index += 1) {
        database.execute(
          '''
          INSERT INTO world_rule_entry (
            world_rule_set_id,
            ordinal,
            entry_type,
            entry_text
          ) VALUES (?, ?, ?, ?)
          ''',
          <Object?>[world.id, index, 'rule', world.rules[index]],
        );
      }
      for (
        var index = 0;
        index < world.forbiddenAssumptions.length;
        index += 1
      ) {
        database.execute(
          '''
          INSERT INTO world_rule_entry (
            world_rule_set_id,
            ordinal,
            entry_type,
            entry_text
          ) VALUES (?, ?, ?, ?)
          ''',
          <Object?>[
            world.id,
            world.rules.length + index,
            'forbidden_assumption',
            world.forbiddenAssumptions[index],
          ],
        );
      }
    }
  }

  void _insertEntities(
    Database database,
    ModeGuidanceAssetBundle bundle, {
    required String statePath,
    required String createdAt,
    required String updatedAt,
  }) {
    for (final entity in bundle.entityIdentities) {
      database.execute(
        '''
        INSERT INTO entity_identity (
          id,
          mode_id,
          entity_kind,
          display_name,
          summary,
          markdown_path,
          state_path,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          entity.id,
          bundle.modeId,
          entity.kind,
          entity.displayName,
          entity.summary,
          bundle.markdownPathFor(entity.id),
          statePath,
          createdAt,
          updatedAt,
        ],
      );
      for (var index = 0; index < entity.aliases.length; index += 1) {
        database.execute(
          '''
          INSERT INTO entity_alias (
            entity_id,
            ordinal,
            alias_text,
            alias_type
          ) VALUES (?, ?, ?, ?)
          ''',
          <Object?>[entity.id, index, entity.aliases[index], 'display_alias'],
        );
      }
      for (var index = 0; index < entity.nameHistory.length; index += 1) {
        database.execute(
          '''
          INSERT INTO entity_alias (
            entity_id,
            ordinal,
            alias_text,
            alias_type
          ) VALUES (?, ?, ?, ?)
          ''',
          <Object?>[
            entity.id,
            entity.aliases.length + index,
            entity.nameHistory[index],
            'name_history',
          ],
        );
      }
    }
  }

  void _ensureSchema(Database database) {
    database.execute('''
      CREATE TABLE IF NOT EXISTS style_profile (
        id TEXT PRIMARY KEY,
        mode_id TEXT NOT NULL,
        display_name TEXT NOT NULL,
        summary TEXT NOT NULL,
        markdown_path TEXT NOT NULL,
        state_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS style_rule (
        style_profile_id TEXT NOT NULL,
        ordinal INTEGER NOT NULL,
        rule_text TEXT NOT NULL,
        PRIMARY KEY (style_profile_id, ordinal)
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS world_rule_set (
        id TEXT PRIMARY KEY,
        mode_id TEXT NOT NULL,
        display_name TEXT NOT NULL,
        summary TEXT NOT NULL,
        markdown_path TEXT NOT NULL,
        state_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS world_rule_entry (
        world_rule_set_id TEXT NOT NULL,
        ordinal INTEGER NOT NULL,
        entry_type TEXT NOT NULL,
        entry_text TEXT NOT NULL,
        PRIMARY KEY (world_rule_set_id, ordinal)
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS entity_identity (
        id TEXT PRIMARY KEY,
        mode_id TEXT NOT NULL,
        entity_kind TEXT NOT NULL,
        display_name TEXT NOT NULL,
        summary TEXT NOT NULL,
        markdown_path TEXT NOT NULL,
        state_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS entity_alias (
        entity_id TEXT NOT NULL,
        ordinal INTEGER NOT NULL,
        alias_text TEXT NOT NULL,
        alias_type TEXT NOT NULL,
        PRIMARY KEY (entity_id, ordinal, alias_type)
      )
      ''');
  }
}
