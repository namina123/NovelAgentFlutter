import 'dart:developer' as developer;

import 'package:flutter/scheduler.dart';

class UiStallProbe {
  UiStallProbe({
    this.stallThreshold = const Duration(milliseconds: 48),
    this.maxRecentStalls = 20,
  });

  final Duration stallThreshold;
  final int maxRecentStalls;
  final List<UiStallRecord> _recentStalls = <UiStallRecord>[];
  bool _started = false;
  int _frameCount = 0;
  int _stallCount = 0;

  bool get isRunning => _started;
  int get frameCount => _frameCount;
  int get stallCount => _stallCount;
  List<UiStallRecord> get recentStalls =>
      List<UiStallRecord>.unmodifiable(_recentStalls);

  void start() {
    // 中文注释: stall probe 只在调试/排障时收集帧时长，不改变应用本身的交互逻辑。
    if (_started) {
      return;
    }
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_handleTimings);
  }

  void stop() {
    // 中文注释: 停止探针时移除 timings 回调，避免退出或重建后重复采样。
    if (!_started) {
      return;
    }
    _started = false;
    SchedulerBinding.instance.removeTimingsCallback(_handleTimings);
  }

  void dispose() {
    // 中文注释: 统一释放入口只是 stop 的薄封装，便于后续在 composition root 里收口。
    stop();
  }

  void recordFrameDuration({
    required Duration totalSpan,
    Duration buildSpan = Duration.zero,
    Duration rasterSpan = Duration.zero,
    String label = 'manual',
  }) {
    // 中文注释: 单帧时长记录入口同时服务手工测试和真实 frame timing 回调。
    _frameCount += 1;
    if (totalSpan < stallThreshold) {
      return;
    }
    _stallCount += 1;
    final record = UiStallRecord(
      label: label,
      totalSpan: totalSpan,
      buildSpan: buildSpan,
      rasterSpan: rasterSpan,
      recordedAt: DateTime.now(),
    );
    _recentStalls.add(record);
    if (_recentStalls.length > maxRecentStalls) {
      _recentStalls.removeAt(0);
    }
    developer.log(
      '$label total=${totalSpan.inMilliseconds}ms build=${buildSpan.inMilliseconds}ms raster=${rasterSpan.inMilliseconds}ms',
      name: 'UiStallProbe',
    );
  }

  UiStallProbeSnapshot snapshot() {
    // 中文注释: 快照只输出计数和最近几次 stall，便于测试断言与手工排障。
    return UiStallProbeSnapshot(
      frameCount: _frameCount,
      stallCount: _stallCount,
      recentStalls: List<UiStallRecord>.unmodifiable(_recentStalls),
    );
  }

  void _handleTimings(List<FrameTiming> timings) {
    // 中文注释: Flutter frame timing 回调只负责把真实帧数据投射到统一的单帧记录入口。
    for (final timing in timings) {
      recordFrameDuration(
        totalSpan: timing.totalSpan,
        buildSpan: timing.buildDuration,
        rasterSpan: timing.rasterDuration,
        label: 'frame',
      );
    }
  }
}

class UiStallRecord {
  const UiStallRecord({
    required this.label,
    required this.totalSpan,
    required this.buildSpan,
    required this.rasterSpan,
    required this.recordedAt,
  });

  final String label;
  final Duration totalSpan;
  final Duration buildSpan;
  final Duration rasterSpan;
  final DateTime recordedAt;
}

class UiStallProbeSnapshot {
  const UiStallProbeSnapshot({
    required this.frameCount,
    required this.stallCount,
    required this.recentStalls,
  });

  final int frameCount;
  final int stallCount;
  final List<UiStallRecord> recentStalls;
}
