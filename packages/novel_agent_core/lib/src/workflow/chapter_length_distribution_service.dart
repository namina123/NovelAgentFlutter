import 'dart:math';

import 'chapter_length_distribution_policy.dart';
import 'chapter_length_evaluation.dart';
import 'chapter_length_profile.dart';
import 'chapter_length_record.dart';

class ChapterLengthDistributionService {
  const ChapterLengthDistributionService();

  ChapterLengthEvaluation evaluate({
    required ChapterLengthProfile profile,
    required ChapterLengthDistributionPolicy policy,
    required ChapterLengthRecord currentRecord,
    List<ChapterLengthRecord> history = const <ChapterLengthRecord>[],
  }) {
    // 中文注释: 分布评估的核心只看长度样本和策略，不接触任务仓储、UI 或 provider 原始响应。
    final usableHistory = history
        .where((record) => record.length > 0)
        .toList(growable: false)
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    final recentHistory = usableHistory.length <= policy.rollingWindow
        ? usableHistory
        : usableHistory.sublist(usableHistory.length - policy.rollingWindow);
    final previous = usableHistory.isEmpty ? null : usableHistory.last;
    final rollingAverage = recentHistory.isEmpty
        ? 0
        : (recentHistory
                    .map((record) => record.length)
                    .reduce((left, right) => left + right) /
                recentHistory.length)
            .round();
    final targetDeviation = (currentRecord.length - profile.targetLength).abs();
    final double targetDeviationRatio = profile.targetLength <= 0
        ? 0.0
        : targetDeviation / profile.targetLength;
    final adjacentDelta = previous == null
        ? 0
        : (currentRecord.length - previous.length).abs();
    final adjacentBase = max(profile.targetLength, previous?.length ?? 0);
    final double adjacentDeltaRatio = adjacentBase <= 0
        ? 0.0
        : adjacentDelta / adjacentBase;
    final double rollingDeviationRatio = rollingAverage <= 0
        ? 0.0
        : (currentRecord.length - rollingAverage).abs() / rollingAverage;
    final outOfPreferredRange =
        (profile.preferredMin > 0 && currentRecord.length < profile.preferredMin) ||
        (profile.preferredMax > 0 && currentRecord.length > profile.preferredMax);
    final severe =
        targetDeviationRatio >= policy.severeDeviationRatio ||
        adjacentDeltaRatio >= policy.severeAdjacentDeltaRatio;
    final needsRebalance =
        outOfPreferredRange ||
        targetDeviationRatio >= policy.mildDeviationRatio ||
        adjacentDeltaRatio >= policy.mildAdjacentDeltaRatio ||
        rollingDeviationRatio >= policy.mildDeviationRatio;
    final slightReminder =
        !needsRebalance &&
        (targetDeviationRatio >= policy.mildDeviationRatio * 0.6 ||
            adjacentDeltaRatio >= policy.mildAdjacentDeltaRatio * 0.6 ||
            rollingDeviationRatio >= policy.mildDeviationRatio * 0.6);
    final level = severe
        ? 'severely_off'
        : needsRebalance
        ? 'needs_rebalance'
        : slightReminder
        ? 'slightly_off'
        : 'balanced';
    final recommendedAction = severe
        ? 'review_or_repair'
        : needsRebalance
        ? 'adjust_next_chapter'
        : slightReminder
        ? 'remind'
        : 'pass';
    final notes = _notes(
      profile: profile,
      currentRecord: currentRecord,
      previous: previous,
      rollingAverage: rollingAverage,
      targetDeviationRatio: targetDeviationRatio,
      adjacentDeltaRatio: adjacentDeltaRatio,
      outOfPreferredRange: outOfPreferredRange,
      level: level,
    );
    return ChapterLengthEvaluation(
      profile: profile,
      policy: policy,
      currentRecord: currentRecord,
      rollingAverageLength: rollingAverage,
      previousLength: previous?.length ?? 0,
      adjacentDelta: adjacentDelta,
      targetDeviation: targetDeviation,
      targetDeviationRatio: targetDeviationRatio,
      adjacentDeltaRatio: adjacentDeltaRatio,
      historySamplesUsed: recentHistory.length,
      level: level,
      recommendedAction: recommendedAction,
      notes: notes,
    );
  }

  List<String> _notes({
    required ChapterLengthProfile profile,
    required ChapterLengthRecord currentRecord,
    required ChapterLengthRecord? previous,
    required int rollingAverage,
    required double targetDeviationRatio,
    required double adjacentDeltaRatio,
    required bool outOfPreferredRange,
    required String level,
  }) {
    final result = <String>[
      '当前章约 ${currentRecord.length} 字，目标基准约 ${profile.targetLength} 字。',
    ];
    if (profile.preferredMin > 0 || profile.preferredMax > 0) {
      result.add(
        '当前任务的柔性参考区间为 ${profile.preferredMin > 0 ? profile.preferredMin : '未设下限'} ~ ${profile.preferredMax > 0 ? profile.preferredMax : '未设上限'} 字。',
      );
    }
    if (rollingAverage > 0) {
      result.add('最近若干章滚动均值约 ${rollingAverage} 字。');
    }
    if (previous != null) {
      result.add('与上一章相比，字数差约 ${currentRecord.length - previous.length} 字。');
    }
    if (outOfPreferredRange) {
      result.add('当前章已经超出本任务的柔性参考区间。');
    }
    if (targetDeviationRatio >= 0.01) {
      result.add('相对目标基准的偏离约 ${(targetDeviationRatio * 100).round()}%。');
    }
    if (adjacentDeltaRatio >= 0.01 && previous != null) {
      result.add('与上一章的波动约 ${(adjacentDeltaRatio * 100).round()}%。');
    }
    if (level == 'severely_off') {
      result.add('偏离已经明显，建议把它当成审稿/返修提示，而不是只在下章轻微回调。');
    } else if (level == 'needs_rebalance') {
      result.add('偏离尚可消化，建议在下一章优先回调分布，避免继续越拉越开。');
    } else if (level == 'slightly_off') {
      result.add('目前只是轻微波动，记录提醒即可，不需要强行打断当前产物。');
    } else {
      result.add('当前章长度分布基本稳定，可直接继续。');
    }
    return result;
  }
}
