import 'dart:developer' as developer;

import '../routing/app_destination.dart';

class NavigationTraceService {
  NavigationTraceService({this.maxRecentEvents = 60});

  final int maxRecentEvents;
  final Map<AppDestination, _NavigationTraceSession> _sessionsByDestination =
      <AppDestination, _NavigationTraceSession>{};
  final List<NavigationTraceEvent> _recentEvents =
      <NavigationTraceEvent>[];
  int _nextSessionId = 0;
  int _navigationBeginCount = 0;
  int _destinationVisibleCount = 0;
  int _pageInitializedCount = 0;
  int _pageRefreshCompletedCount = 0;
  int _pageRefreshFailedCount = 0;

  int beginNavigation({
    required AppDestination from,
    required AppDestination to,
    required String reason,
  }) {
    // 中文注释: 这里记录一次切页开始，后续页面可见和刷新完成都会挂回同一条导航会话。
    final session = _NavigationTraceSession(
      id: ++_nextSessionId,
      from: from,
      to: to,
      reason: reason,
      startedAt: DateTime.now(),
    );
    _sessionsByDestination[to] = session;
    _navigationBeginCount += 1;
    _record(
      NavigationTraceEventKind.begin,
      session: session,
      label: reason,
    );
    return session.id;
  }

  void markDestinationVisible(
    AppDestination destination, {
    String label = 'visible',
  }) {
    // 中文注释: 这里记录页面真正进入可见状态，便于区分“切页动作”与“页面实际渲染完成”。
    final session = _sessionForDestination(
      destination,
      reason: label,
    );
    if (session.destinationVisibleRecorded) {
      return;
    }
    session.destinationVisibleRecorded = true;
    _destinationVisibleCount += 1;
    _record(
      NavigationTraceEventKind.visible,
      session: session,
      label: label,
    );
  }

  void markPageInitialized(
    AppDestination destination, {
    String label = 'page_initialized',
  }) {
    // 中文注释: 这里记录页面首次初始化，避免我们只看到切页却看不到首帧初始化链。
    final session = _sessionForDestination(
      destination,
      reason: label,
    );
    if (session.pageInitializedRecorded) {
      return;
    }
    session.pageInitializedRecorded = true;
    _pageInitializedCount += 1;
    _record(
      NavigationTraceEventKind.pageInitialized,
      session: session,
      label: label,
    );
  }

  void markPageRefreshCompleted(
    AppDestination destination, {
    String label = 'page_refresh_completed',
  }) {
    // 中文注释: 这里记录页面刷新完成，方便之后核对一次切页到底引发了多少次子域刷新。
    final session = _sessionForDestination(
      destination,
      reason: label,
    );
    session.pageRefreshCompletedCount += 1;
    _pageRefreshCompletedCount += 1;
    _record(
      NavigationTraceEventKind.pageRefreshCompleted,
      session: session,
      label: label,
    );
  }

  void markPageRefreshFailed(
    AppDestination destination, {
    required Object error,
    String label = 'page_refresh_failed',
  }) {
    // 中文注释: 这里记录页面刷新失败，便于把“没有完成”与“完成但结果为空”区分开。
    final session = _sessionForDestination(
      destination,
      reason: label,
    );
    session.pageRefreshFailedCount += 1;
    _pageRefreshFailedCount += 1;
    _record(
      NavigationTraceEventKind.pageRefreshFailed,
      session: session,
      label: '$label:$error',
    );
  }

  _NavigationTraceSession _sessionForDestination(
    AppDestination destination, {
    required String reason,
  }) {
    // 中文注释: 如果页面先发出了可见或刷新事件，再补切页起点，这里会帮忙补一条隐式会话，避免 trace 断链。
    final existing = _sessionsByDestination[destination];
    if (existing != null) {
      return existing;
    }
    beginNavigation(
      from: destination,
      to: destination,
      reason: reason,
    );
    return _sessionsByDestination[destination]!;
  }

  NavigationTraceSnapshot snapshot() {
    // 中文注释: 快照对象让测试可以直接检查切页、可见、初始化与刷新完成的计数。
    return NavigationTraceSnapshot(
      navigationBeginCount: _navigationBeginCount,
      destinationVisibleCount: _destinationVisibleCount,
      pageInitializedCount: _pageInitializedCount,
      pageRefreshCompletedCount: _pageRefreshCompletedCount,
      pageRefreshFailedCount: _pageRefreshFailedCount,
      recentEvents: List<NavigationTraceEvent>.unmodifiable(_recentEvents),
    );
  }

  void _record(
    NavigationTraceEventKind kind, {
    required _NavigationTraceSession session,
    required String label,
  }) {
    // 中文注释: 统一的记录入口保证日志格式稳定，后续排障时不用在多个地方拼字符串。
    final event = NavigationTraceEvent(
      kind: kind,
      sessionId: session.id,
      from: session.from,
      to: session.to,
      label: label,
      recordedAt: DateTime.now(),
    );
    _recentEvents.add(event);
    if (_recentEvents.length > maxRecentEvents) {
      _recentEvents.removeAt(0);
    }
    developer.log(
      '#${session.id} $kind ${session.from.name}->${session.to.name} $label',
      name: 'NavigationTrace',
    );
  }
}

class _NavigationTraceSession {
  _NavigationTraceSession({
    required this.id,
    required this.from,
    required this.to,
    required this.reason,
    required this.startedAt,
  });

  final int id;
  final AppDestination from;
  final AppDestination to;
  final String reason;
  final DateTime startedAt;
  bool destinationVisibleRecorded = false;
  bool pageInitializedRecorded = false;
  int pageRefreshCompletedCount = 0;
  int pageRefreshFailedCount = 0;
}

enum NavigationTraceEventKind {
  begin,
  visible,
  pageInitialized,
  pageRefreshCompleted,
  pageRefreshFailed,
}

class NavigationTraceEvent {
  const NavigationTraceEvent({
    required this.kind,
    required this.sessionId,
    required this.from,
    required this.to,
    required this.label,
    required this.recordedAt,
  });

  final NavigationTraceEventKind kind;
  final int sessionId;
  final AppDestination from;
  final AppDestination to;
  final String label;
  final DateTime recordedAt;
}

class NavigationTraceSnapshot {
  const NavigationTraceSnapshot({
    required this.navigationBeginCount,
    required this.destinationVisibleCount,
    required this.pageInitializedCount,
    required this.pageRefreshCompletedCount,
    required this.pageRefreshFailedCount,
    required this.recentEvents,
  });

  final int navigationBeginCount;
  final int destinationVisibleCount;
  final int pageInitializedCount;
  final int pageRefreshCompletedCount;
  final int pageRefreshFailedCount;
  final List<NavigationTraceEvent> recentEvents;
}
