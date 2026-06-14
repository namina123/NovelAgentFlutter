import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_session_workspace_snapshot.dart';

class ProjectSessionWorkspaceService {
  ProjectSessionWorkspaceService({
    required ProjectToolHostPort hostPort,
    SessionHistoryService? sessionHistoryService,
    SessionRecordNormalizerService? sessionRecordNormalizerService,
    SessionModeService? sessionModeService,
    SessionMessageService? sessionMessageService,
  }) : _hostPort = hostPort,
       _messageService = sessionMessageService ?? SessionMessageService(),
       _modeService = sessionModeService ?? SessionModeService(),
       _sessionHistoryService =
           sessionHistoryService ??
           SessionHistoryService(
             messageService: sessionMessageService ?? SessionMessageService(),
           ),
       _sessionRecordNormalizerService =
           sessionRecordNormalizerService ??
           SessionRecordNormalizerService(
             modeService: sessionModeService ?? SessionModeService(),
             messageService: sessionMessageService ?? SessionMessageService(),
           );

  final ProjectToolHostPort _hostPort;
  final SessionMessageService _messageService;
  final SessionModeService _modeService;
  final SessionHistoryService _sessionHistoryService;
  final SessionRecordNormalizerService _sessionRecordNormalizerService;

  Future<void> saveSessions(
    ProjectDescriptor project, {
    required List<JsonMap> sessionRecords,
    required String activeSessionId,
  }) async {
    final normalizedRecords = sessionRecords
        .map(
          (record) => _sessionRecordNormalizerService.normalizeSessionRecord(
            record,
            defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
          ),
        )
        .where(
          (record) => ValueReaders.stringValue(record['id']).trim().isNotEmpty,
        )
        .toList(growable: false);
    await _hostPort.createDirectory(project.rootPath, 'sessions');
    for (final record in normalizedRecords) {
      final sessionId = ValueReaders.stringValue(record['id']).trim();
      if (sessionId.isEmpty) {
        continue;
      }
      final encoded = const JsonEncoder.withIndent('  ').convert(record);
      await _hostPort.writeTextFile(
        project.rootPath,
        _sessionFilePathForId(sessionId),
        encoded,
      );
    }
    final index = _sessionHistoryService.sessionIndexFromSessions(
      normalizedRecords,
      currentSessionId: activeSessionId,
    );
    final encodedIndex = const JsonEncoder.withIndent('  ').convert(index);
    await _hostPort.writeTextFile(
      project.rootPath,
      'sessions/session_index.json',
      encodedIndex,
    );
  }

  Future<ProjectSessionWorkspaceSnapshot> loadSessions(
    ProjectDescriptor project,
  ) async {
    final indexText = await _hostPort.readTextFile(
      project.rootPath,
      'sessions/session_index.json',
    );
    final indexedSessionIds = <String>[];
    var activeSessionId = '';
    if (indexText != null && indexText.trim().isNotEmpty) {
      try {
        final decoded = ValueReaders.mapValue(jsonDecode(indexText));
        activeSessionId = ValueReaders.stringValue(
          decoded['current_session_id'],
        ).trim();
        for (final raw in ValueReaders.objectList(decoded['sessions'])) {
          final entry = ValueReaders.mapValue(raw);
          final sessionId = ValueReaders.stringValue(entry['id']).trim();
          if (sessionId.isEmpty || indexedSessionIds.contains(sessionId)) {
            continue;
          }
          indexedSessionIds.add(sessionId);
        }
      } catch (_) {}
    }

    final records = <JsonMap>[];
    final seenIds = <String>{};
    for (final sessionId in indexedSessionIds) {
      final record = await _readSessionRecord(project, sessionId);
      if (record.isEmpty) {
        continue;
      }
      final recordId = ValueReaders.stringValue(record['id']).trim();
      if (recordId.isEmpty || !seenIds.add(recordId)) {
        continue;
      }
      records.add(record);
    }

    if (records.isEmpty) {
      final scannedRecords = await _scanSessionRecords(project);
      for (final record in scannedRecords) {
        final recordId = ValueReaders.stringValue(record['id']).trim();
        if (recordId.isEmpty || !seenIds.add(recordId)) {
          continue;
        }
        records.add(record);
      }
    }

    records.sort((left, right) {
      final leftUpdated = ValueReaders.stringValue(left['updated_at']);
      final rightUpdated = ValueReaders.stringValue(right['updated_at']);
      return rightUpdated.compareTo(leftUpdated);
    });

    final resolvedActiveSessionId =
        activeSessionId.isNotEmpty &&
            records.any(
              (record) =>
                  ValueReaders.stringValue(record['id']) == activeSessionId,
            )
        ? activeSessionId
        : (records.isEmpty
              ? ''
              : ValueReaders.stringValue(records.first['id']).trim());

    return ProjectSessionWorkspaceSnapshot(
      sessionRecords: List<JsonMap>.unmodifiable(records),
      activeSessionId: resolvedActiveSessionId,
    );
  }

  Future<JsonMap> _readSessionRecord(
    ProjectDescriptor project,
    String sessionId,
  ) async {
    final content = await _hostPort.readTextFile(
      project.rootPath,
      _sessionFilePathForId(sessionId),
    );
    return _decodeSessionRecord(content);
  }

  Future<List<JsonMap>> _scanSessionRecords(ProjectDescriptor project) async {
    final entries = await _hostPort.listEntries(project.rootPath);
    final records = <JsonMap>[];
    for (final raw in entries) {
      final entry = ValueReaders.mapValue(raw);
      final relativePath = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) ||
          !relativePath.startsWith('sessions/') ||
          relativePath == 'sessions/session_index.json' ||
          !relativePath.endsWith('.json')) {
        continue;
      }
      final content = await _hostPort.readTextFile(
        project.rootPath,
        relativePath,
      );
      final record = _decodeSessionRecord(content);
      if (record.isNotEmpty) {
        records.add(record);
      }
    }
    return records;
  }

  JsonMap _decodeSessionRecord(String? content) {
    if (content == null || content.trim().isEmpty) {
      return const <String, Object?>{};
    }
    try {
      final decoded = ValueReaders.mapValue(jsonDecode(content));
      final normalized = _sessionRecordNormalizerService.normalizeSessionRecord(
        decoded,
        defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
      );
      final sessionId = ValueReaders.stringValue(normalized['id']).trim();
      if (sessionId.isEmpty) {
        return const <String, Object?>{};
      }
      normalized['context_messages'] = _messageService.normalizeMessages(
        normalized['context_messages'],
      );
      normalized['mode'] = _modeService.cleanMode(
        ValueReaders.stringValue(normalized['mode']),
      );
      return normalized;
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  String _sessionFilePathForId(String sessionId) {
    final safeId = sessionId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'sessions/$safeId.json';
  }
}
