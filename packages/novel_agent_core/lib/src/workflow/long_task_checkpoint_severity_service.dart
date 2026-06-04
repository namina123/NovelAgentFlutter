import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskCheckpointSeverityService {
  JsonMap assess(JsonMap review) {
    // 中文注释: 严重度判断只依赖复盘合同本身，给 GUI/CLI 和后续策略一个统一风险刻度。
    final reasons = <String>[];
    final taskType = ValueReaders.stringValue(review['task_type']).trim();
    final stage = ValueReaders.stringValue(review['stage']).trim();
    final resultOk = ValueReaders.boolValue(review['result_ok']);
    final outputPaths = ValueReaders.stringList(review['output_paths']);
    final driftWatchItems = ValueReaders.stringList(
      review['drift_watch_items'],
    );
    final driftSignals = ValueReaders.mapList(review['drift_signals']);
    final confirmationFocus = ValueReaders.stringList(
      review['confirmation_focus'],
    );
    final toolNames = ValueReaders.stringList(review['tool_names']);
    final error = ValueReaders.stringValue(review['error']).trim();
    final narrativeRisk = ValueReaders.mapValue(review['narrative_supervisor_risk']);
    final overallRisk = ValueReaders.mapValue(narrativeRisk['overall']);
    final reviewRisk = ValueReaders.mapValue(narrativeRisk['review']);
    final permissionRisk = ValueReaders.mapValue(narrativeRisk['permission']);

    var severity = 'low';
    if (!resultOk || error.isNotEmpty) {
      severity = 'critical';
      reasons.add('当前单步没有稳定成功，必须先处理错误或缺失产物。');
    } else {
      final highestSignalSeverity = _highestSignalSeverity(driftSignals);
      if (highestSignalSeverity == 'high') {
        severity = 'high';
      } else if (highestSignalSeverity == 'medium') {
        severity = 'medium';
      }
      if ((taskType == 'chapter' && stage == 'sample') ||
          (outputPaths.isEmpty &&
              <String>['chapter', 'planning'].contains(taskType))) {
        severity = 'high';
      } else if (taskType == 'checkpoint' ||
          taskType == 'planning' ||
          driftWatchItems.isNotEmpty ||
          confirmationFocus.length >= 2) {
        severity = 'medium';
      }
    }
    severity = _maxSeverity(
      severity,
      switch (ValueReaders.stringValue(overallRisk['category'])) {
        'manual_attention' => 'critical',
        'repair' => 'high',
        'checkpoint_user' => 'medium',
        _ => 'low',
      },
    );

    if (taskType == 'chapter' && stage == 'sample') {
      reasons.add('样章阶段决定长期可写性，建议提高人工确认强度。');
    }
    if (taskType == 'planning') {
      reasons.add('规划节点会影响后续整条任务链，适合至少做中等级确认。');
    }
    if (taskType == 'checkpoint') {
      reasons.add('显式检查点本身就是人工决策闸口，不宜按低风险处理。');
    }
    if (outputPaths.isEmpty &&
        <String>['chapter', 'planning'].contains(taskType)) {
      reasons.add('当前没有稳定产物文件，需要先判断是否补写还是退回上游。');
    }
    if (driftWatchItems.length >= 3) {
      reasons.add('当前长期约束警戒项较多，建议补额外审视。');
      if (severity == 'low') {
        severity = 'medium';
      }
    }
    if (driftSignals.any(
      (signal) => ValueReaders.stringValue(signal['severity']) == 'high',
    )) {
      reasons.add('至少有一类核心资产漂移信号达到高等级，应优先做额外审视。');
    }
    if (toolNames.isEmpty && resultOk && outputPaths.isNotEmpty) {
      reasons.add('本轮虽然有产物，但工具轨迹较少，建议人工检查实际落盘内容。');
    }
    final riskSummary = ValueReaders.stringValue(overallRisk['summary']).trim();
    if (riskSummary.isNotEmpty) {
      reasons.add(riskSummary);
    }
    if (ValueReaders.boolValue(permissionRisk['waiting_for_user'])) {
      reasons.add('本轮存在真实权限确认等待，waiting_user 应只保留给这种用户确认场景。');
    }
    if (ValueReaders.intValue(reviewRisk['questioned_claim_count']) > 0) {
      reasons.add('语义复核对部分 claim 给出了 questioned disposition，建议把它纳入继续推进前的确认范围。');
      severity = _maxSeverity(severity, 'medium');
    }
    if (reasons.isEmpty) {
      reasons.add('当前节点风险较低，可在确认产物后继续推进。');
    }

    return <String, Object?>{
      'severity': severity,
      'severity_label': _labelFor(severity),
      'reasons': reasons,
    };
  }

  String _labelFor(String severity) {
    switch (severity) {
      case 'critical':
        return '关键';
      case 'high':
        return '高';
      case 'medium':
        return '中';
      default:
        return '低';
    }
  }

  String _highestSignalSeverity(List<JsonMap> driftSignals) {
    var rank = 0;
    for (final signal in driftSignals) {
      final current = _severityRank(
        ValueReaders.stringValue(signal['severity']),
      );
      if (current > rank) {
        rank = current;
      }
    }
    if (rank >= 3) {
      return 'high';
    }
    if (rank == 2) {
      return 'medium';
    }
    if (rank == 1) {
      return 'low';
    }
    return '';
  }

  int _severityRank(String severity) {
    switch (severity.trim()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  String _maxSeverity(String left, String right) {
    return _severityRank(right) > _severityRank(left) ? right : left;
  }
}
