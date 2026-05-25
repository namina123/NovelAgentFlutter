import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'project_sqlite_path_service.dart';

class ProjectModeGuidanceSqliteStore {
  ProjectModeGuidanceSqliteStore({
    ProjectSqlitePathService? sqlitePathService,
  }) : _sqlitePathService = sqlitePathService ?? ProjectSqlitePathService();

  final ProjectSqlitePathService _sqlitePathService;

  Future<void> save(
    String rootPath,
    ModeGuidanceState state, {
    required String markdownPath,
    required String statePath,
  }) async {
    // 中文注释: SQLite 只做结构化投影，不当主编辑入口，因此这里按表结构平铺保存状态与答案。
    final database = _open(rootPath);
    try {
      _ensureSchema(database);
      database.execute('BEGIN');
      database.execute(
        '''
        INSERT INTO mode_guidance_state (
          mode_id,
          project_strategy_id,
          workflow_strategy_id,
          status,
          current_stage_id,
          created_at,
          updated_at,
          markdown_path,
          state_path
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(mode_id) DO UPDATE SET
          project_strategy_id = excluded.project_strategy_id,
          workflow_strategy_id = excluded.workflow_strategy_id,
          status = excluded.status,
          current_stage_id = excluded.current_stage_id,
          created_at = excluded.created_at,
          updated_at = excluded.updated_at,
          markdown_path = excluded.markdown_path,
          state_path = excluded.state_path
        ''',
        <Object?>[
          state.modeId,
          state.projectStrategyId,
          state.workflowStrategyId,
          state.status,
          state.currentStageId,
          state.createdAt,
          state.updatedAt,
          markdownPath,
          statePath,
        ],
      );
      database.execute(
        'DELETE FROM mode_guidance_answer WHERE mode_id = ?',
        <Object?>[state.modeId],
      );
      for (final answer in state.answers) {
        database.execute(
          '''
          INSERT INTO mode_guidance_answer (
            mode_id,
            stage_id,
            field_key,
            value_text,
            label_text,
            source_type,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            state.modeId,
            answer.stageId,
            answer.fieldKey,
            answer.value,
            answer.label,
            answer.source,
            answer.updatedAt,
          ],
        );
      }
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    } finally {
      database.dispose();
    }
  }

  Future<ModeGuidanceState?> load(String rootPath, String modeId) async {
    // 中文注释: 读取时优先按平铺表恢复，避免依赖大 JSON blob。
    final dbPath = _sqlitePathService.databasePath(rootPath);
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      return null;
    }
    final database = sqlite3.open(dbPath);
    try {
      _ensureSchema(database);
      final stateRows = database.select(
        '''
        SELECT
          mode_id,
          project_strategy_id,
          workflow_strategy_id,
          status,
          current_stage_id,
          created_at,
          updated_at
        FROM mode_guidance_state
        WHERE mode_id = ?
        ''',
        <Object?>[modeId],
      );
      if (stateRows.isEmpty) {
        return null;
      }
      final row = stateRows.first;
      final answerRows = database.select(
        '''
        SELECT
          stage_id,
          field_key,
          value_text,
          label_text,
          source_type,
          updated_at
        FROM mode_guidance_answer
        WHERE mode_id = ?
        ORDER BY stage_id, field_key
        ''',
        <Object?>[modeId],
      );
      final answers = answerRows
          .map(
            (answerRow) => ModeGuidanceAnswer(
              stageId: answerRow['stage_id']?.toString() ?? '',
              fieldKey: answerRow['field_key']?.toString() ?? '',
              value: answerRow['value_text']?.toString() ?? '',
              label: answerRow['label_text']?.toString() ?? '',
              source: answerRow['source_type']?.toString() ?? 'free_text',
              updatedAt: answerRow['updated_at']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
      final completedStageIds = <String>[];
      for (final answer in answers) {
        if (!completedStageIds.contains(answer.stageId)) {
          completedStageIds.add(answer.stageId);
        }
      }
      return ModeGuidanceState(
        modeId: row['mode_id']?.toString() ?? modeId,
        projectStrategyId: row['project_strategy_id']?.toString() ?? '',
        workflowStrategyId: row['workflow_strategy_id']?.toString() ?? '',
        status: row['status']?.toString() ?? ModeGuidanceState.statusCollecting,
        currentStageId: row['current_stage_id']?.toString() ?? '',
        answers: answers,
        completedStageIds: completedStageIds,
        createdAt: row['created_at']?.toString() ?? '',
        updatedAt: row['updated_at']?.toString() ?? '',
      );
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

  void _ensureSchema(Database database) {
    database.execute(
      '''
      CREATE TABLE IF NOT EXISTS mode_guidance_state (
        mode_id TEXT PRIMARY KEY,
        project_strategy_id TEXT NOT NULL,
        workflow_strategy_id TEXT NOT NULL,
        status TEXT NOT NULL,
        current_stage_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        markdown_path TEXT NOT NULL,
        state_path TEXT NOT NULL
      )
      ''',
    );
    database.execute(
      '''
      CREATE TABLE IF NOT EXISTS mode_guidance_answer (
        mode_id TEXT NOT NULL,
        stage_id TEXT NOT NULL,
        field_key TEXT NOT NULL,
        value_text TEXT NOT NULL,
        label_text TEXT NOT NULL,
        source_type TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (mode_id, stage_id, field_key)
      )
      ''',
    );
  }
}
