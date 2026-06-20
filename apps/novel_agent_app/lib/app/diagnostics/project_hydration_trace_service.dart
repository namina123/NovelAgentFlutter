import 'dart:developer' as developer;

import '../routing/app_destination.dart';

class ProjectHydrationTraceService {
  ProjectHydrationTraceService({this.maxRecentEvents = 80});

  final int maxRecentEvents;
  final Map<int, _ProjectHydrationSession> _sessionsByToken =
      <int, _ProjectHydrationSession>{};
  final List<ProjectHydrationTraceEvent> _recentEvents =
      <ProjectHydrationTraceEvent>[];
  int _beginCount = 0;
  int _stageStartCount = 0;
  int _stageWriteCount = 0;
  int _stageCompleteCount = 0;
  int _destinationChangeCount = 0;
  int _completeCount = 0;
  _ProjectHydrationSession? _activeSession;
  final List<_ProjectHydrationSession> _completedSessions =
      <_ProjectHydrationSession>[];

  bool get isActive => _activeSession != null;
  int? get activeToken => _activeSession?.token;

  void beginHydration({
    required int token,
    required String projectPath,
  }) {
    // 中文注释: 这里记录一次项目 hydration 的开始，后续每个阶段的回写都会挂回同一个 token。
    final session = _ProjectHydrationSession(
      token: token,
      projectPath: projectPath,
      startedAt: DateTime.now(),
    );
    _sessionsByToken[token] = session;
    _activeSession = session;
    _beginCount += 1;
    _record(
      ProjectHydrationTraceEventKind.begin,
      session: session,
      label: 'hydrate:start',
    );
  }

  void markStageStarted({
    required int token,
    required String projectPath,
    required String stageLabel,
  }) {
    // 中文注释: 这里记录 hydration 的阶段起点，方便后续核对每一段恢复到底走了几次。
    final session = _requireActiveSession(
      token: token,
      projectPath: projectPath,
    );
    session.currentStageLabel = stageLabel;
    session.stageStartCount += 1;
    _stageStartCount += 1;
    _record(
      ProjectHydrationTraceEventKind.stageStarted,
      session: session,
      label: stageLabel,
    );
  }

  void recordStageWrite({
    required int token,
    required String projectPath,
    required String stageLabel,
    required String detail,
  }) {
    // 中文注释: 这里记录阶段内的一次状态回写，后续可以直接看到 hydration 把壳层刷新了多少次。
    final session = _requireActiveSession(
      token: token,
      projectPath: projectPath,
    );
    session.stageWriteCount += 1;
    session.writeCountByStage.update(
      stageLabel,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    _stageWriteCount += 1;
    _record(
      ProjectHydrationTraceEventKind.stageWrite,
      session: session,
      label: '$stageLabel:$detail',
    );
  }

  void markStageCompleted({
    required int token,
    required String projectPath,
    required String stageLabel,
    required Duration elapsed,
  }) {
    // 中文注释: 这里记录阶段结束，便于把“阶段有多重”和“阶段到底花了多久”分开看。
    final session = _requireActiveSession(
      token: token,
      projectPath: projectPath,
    );
    session.stageCompleteCount += 1;
    session.lastStageElapsed = elapsed;
    _stageCompleteCount += 1;
    _record(
      ProjectHydrationTraceEventKind.stageCompleted,
      session: session,
      label: '$stageLabel:${elapsed.inMilliseconds}ms',
    );
  }

  void recordDestinationChangeDuringHydration({
    required int token,
    required String projectPath,
    required AppDestination from,
    required AppDestination to,
  }) {
    // 中文注释: 这里记录 hydration 进行中又发生了导航切换，后面就能直接看见壳层是否在互相打架。
    final session = _requireActiveSession(
      token: token,
      projectPath: projectPath,
    );
    session.destinationChangeCount += 1;
    _destinationChangeCount += 1;
    _record(
      ProjectHydrationTraceEventKind.destinationChanged,
      session: session,
      label: '${from.name}->${to.name}',
    );
  }

  void completeHydration({
    required int token,
    required String projectPath,
    required Duration elapsed,
  }) {
    // 中文注释: 这里收束 hydration 会话，确保完成后的统计快照不会继续挂着活跃状态。
    final session = _requireActiveSession(
      token: token,
      projectPath: projectPath,
    );
    session.completed = true;
    session.totalElapsed = elapsed;
    _completeCount += 1;
    _record(
      ProjectHydrationTraceEventKind.completed,
      session: session,
      label: 'hydrate:done:${elapsed.inMilliseconds}ms',
    );
    _completedSessions.add(session);
    _sessionsByToken.remove(token);
    if (identical(_activeSession, session)) {
      _activeSession = null;
    }
  }

  ProjectHydrationTraceSnapshot snapshot() {
    // 中文注释: 快照把活跃会话、已完成会话和最近事件统一暴露给测试和排障。
    return ProjectHydrationTraceSnapshot(
      beginCount: _beginCount,
      stageStartCount: _stageStartCount,
      stageWriteCount: _stageWriteCount,
      stageCompleteCount: _stageCompleteCount,
      destinationChangeCount: _destinationChangeCount,
      completeCount: _completeCount,
      activeSession: _activeSession?.snapshot(),
      completedSessions: _completedSessions
          .map((session) => session.snapshot())
          .toList(growable: false),
      recentEvents: List<ProjectHydrationTraceEvent>.unmodifiable(
        _recentEvents,
      ),
    );
  }

  _ProjectHydrationSession _requireActiveSession({
    required int token,
    required String projectPath,
  }) {
    // 中文注释: 阶段事件必须落在当前活跃 hydration 会话上，否则说明调用顺序已经错位。
    final session = _sessionsByToken[token];
    if (session == null || session.projectPath != projectPath) {
      throw StateError(
        '未找到对应的 hydration 会话：token=$token projectPath=$projectPath',
      );
    }
    _activeSession = session;
    return session;
  }

  void _record(
    ProjectHydrationTraceEventKind kind, {
    required _ProjectHydrationSession session,
    required String label,
  }) {
    // 中文注释: 统一记录入口保证 hydration trace 的日志格式稳定且可回放。
    final event = ProjectHydrationTraceEvent(
      kind: kind,
      token: session.token,
      projectPath: session.projectPath,
      label: label,
      recordedAt: DateTime.now(),
    );
    _recentEvents.add(event);
    if (_recentEvents.length > maxRecentEvents) {
      _recentEvents.removeAt(0);
    }
    developer.log(
      '#${session.token} $kind ${session.projectPath} $label',
      name: 'ProjectHydrationTrace',
    );
  }
}

class _ProjectHydrationSession {
  _ProjectHydrationSession({
    required this.token,
    required this.projectPath,
    required this.startedAt,
  });

  final int token;
  final String projectPath;
  final DateTime startedAt;
  String currentStageLabel = '';
  int stageStartCount = 0;
  int stageWriteCount = 0;
  int stageCompleteCount = 0;
  int destinationChangeCount = 0;
  Duration? lastStageElapsed;
  Duration? totalElapsed;
  bool completed = false;
  final Map<String, int> writeCountByStage = <String, int>{};

  ProjectHydrationTraceSession snapshot() {
    // 中文注释: 会话快照对外只暴露稳定统计，不泄露内部可变状态。
    return ProjectHydrationTraceSession(
      token: token,
      projectPath: projectPath,
      startedAt: startedAt,
      currentStageLabel: currentStageLabel,
      stageStartCount: stageStartCount,
      stageWriteCount: stageWriteCount,
      stageCompleteCount: stageCompleteCount,
      destinationChangeCount: destinationChangeCount,
      lastStageElapsed: lastStageElapsed,
      totalElapsed: totalElapsed,
      completed: completed,
      writeCountByStage: Map<String, int>.unmodifiable(writeCountByStage),
    );
  }
}

enum ProjectHydrationTraceEventKind {
  begin,
  stageStarted,
  stageWrite,
  stageCompleted,
  destinationChanged,
  completed,
}

class ProjectHydrationTraceEvent {
  const ProjectHydrationTraceEvent({
    required this.kind,
    required this.token,
    required this.projectPath,
    required this.label,
    required this.recordedAt,
  });

  final ProjectHydrationTraceEventKind kind;
  final int token;
  final String projectPath;
  final String label;
  final DateTime recordedAt;
}

class ProjectHydrationTraceSession {
  const ProjectHydrationTraceSession({
    required this.token,
    required this.projectPath,
    required this.startedAt,
    required this.currentStageLabel,
    required this.stageStartCount,
    required this.stageWriteCount,
    required this.stageCompleteCount,
    required this.destinationChangeCount,
    required this.lastStageElapsed,
    required this.totalElapsed,
    required this.completed,
    required this.writeCountByStage,
  });

  final int token;
  final String projectPath;
  final DateTime startedAt;
  final String currentStageLabel;
  final int stageStartCount;
  final int stageWriteCount;
  final int stageCompleteCount;
  final int destinationChangeCount;
  final Duration? lastStageElapsed;
  final Duration? totalElapsed;
  final bool completed;
  final Map<String, int> writeCountByStage;
}

class ProjectHydrationTraceSnapshot {
  const ProjectHydrationTraceSnapshot({
    required this.beginCount,
    required this.stageStartCount,
    required this.stageWriteCount,
    required this.stageCompleteCount,
    required this.destinationChangeCount,
    required this.completeCount,
    required this.activeSession,
    required this.completedSessions,
    required this.recentEvents,
  });

  final int beginCount;
  final int stageStartCount;
  final int stageWriteCount;
  final int stageCompleteCount;
  final int destinationChangeCount;
  final int completeCount;
  final ProjectHydrationTraceSession? activeSession;
  final List<ProjectHydrationTraceSession> completedSessions;
  final List<ProjectHydrationTraceEvent> recentEvents;
}
