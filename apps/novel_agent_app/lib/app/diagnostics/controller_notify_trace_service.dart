import 'dart:collection';
import 'dart:developer' as developer;

class ControllerNotifyTraceService {
  ControllerNotifyTraceService({this.maxRecentEvents = 50});

  final int maxRecentEvents;
  final List<ControllerNotifyTraceEvent> _recentEvents =
      <ControllerNotifyTraceEvent>[];
  final Map<String, int> _notifyCountByController = <String, int>{};
  int _totalNotifyCount = 0;

  int get totalNotifyCount => _totalNotifyCount;

  Map<String, int> get notifyCountByController =>
      UnmodifiableMapView<String, int>(_notifyCountByController);

  List<ControllerNotifyTraceEvent> get recentEvents =>
      List<ControllerNotifyTraceEvent>.unmodifiable(_recentEvents);

  void record({
    required String controllerName,
    required String reason,
    String destination = '',
    String projectPath = '',
  }) {
    // 中文注释: 这里记录控制器一次通知监听器的事实，方便后续判断是不是壳层过度回写。
    _totalNotifyCount += 1;
    _notifyCountByController.update(
      controllerName,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    final event = ControllerNotifyTraceEvent(
      controllerName: controllerName,
      reason: reason,
      destination: destination,
      projectPath: projectPath,
      recordedAt: DateTime.now(),
      sequence: _totalNotifyCount,
    );
    _recentEvents.add(event);
    if (_recentEvents.length > maxRecentEvents) {
      _recentEvents.removeAt(0);
    }
    developer.log(
      '#$_totalNotifyCount $controllerName reason=$reason destination=$destination project=$projectPath',
      name: 'ControllerNotifyTrace',
    );
  }

  ControllerNotifyTraceSnapshot snapshot() {
    // 中文注释: 快照对象只提供当前计数与最近事件，测试和手动排障都能直接消费。
    return ControllerNotifyTraceSnapshot(
      totalNotifyCount: _totalNotifyCount,
      notifyCountByController: Map<String, int>.unmodifiable(
        _notifyCountByController,
      ),
      recentEvents: List<ControllerNotifyTraceEvent>.unmodifiable(
        _recentEvents,
      ),
    );
  }
}

class ControllerNotifyTraceEvent {
  const ControllerNotifyTraceEvent({
    required this.controllerName,
    required this.reason,
    required this.destination,
    required this.projectPath,
    required this.recordedAt,
    required this.sequence,
  });

  final String controllerName;
  final String reason;
  final String destination;
  final String projectPath;
  final DateTime recordedAt;
  final int sequence;
}

class ControllerNotifyTraceSnapshot {
  const ControllerNotifyTraceSnapshot({
    required this.totalNotifyCount,
    required this.notifyCountByController,
    required this.recentEvents,
  });

  final int totalNotifyCount;
  final Map<String, int> notifyCountByController;
  final List<ControllerNotifyTraceEvent> recentEvents;
}
