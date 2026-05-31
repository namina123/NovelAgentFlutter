import '../common/json_types.dart';

class LongTaskNarrativeDriftSignalService {
  List<JsonMap> buildSignals({
    required String taskType,
    required String stage,
    required List<String> memorySectionTitles,
    required List<String> outputPaths,
  }) {
    // 中文注释: 这一层只负责伏笔/时间线/关系三类共享叙事资产的漂移警戒，不混入文风和角色判断。
    final hasNarrativeAnchor =
        memorySectionTitles.contains('待回收伏笔') ||
        memorySectionTitles.contains('最近时间线') ||
        memorySectionTitles.contains('关键关系变化');
    final touchesNarrativeAsset = outputPaths.any((path) {
      final clean = path.trim().toLowerCase();
      return clean.startsWith('assets/foreshadows/') ||
          clean.startsWith('assets/timeline/') ||
          clean.startsWith('assets/relationships/');
    });
    if (!hasNarrativeAnchor &&
        !touchesNarrativeAsset &&
        taskType != 'chapter' &&
        taskType != 'planning' &&
        taskType != 'revision') {
      return const <JsonMap>[];
    }
    final severity = _severityFor(
      taskType: taskType,
      stage: stage,
      touchesNarrativeAsset: touchesNarrativeAsset,
    );
    return <JsonMap>[
      <String, Object?>{
        'domain': 'narrative',
        'severity': severity,
        'title': '伏笔与关系守恒',
        'note': _noteFor(
          taskType: taskType,
          stage: stage,
          touchesNarrativeAsset: touchesNarrativeAsset,
        ),
      },
    ];
  }

  String _severityFor({
    required String taskType,
    required String stage,
    required bool touchesNarrativeAsset,
  }) {
    if (touchesNarrativeAsset) {
      return 'high';
    }
    if (taskType == 'chapter' && stage == 'sample') {
      return 'high';
    }
    if (taskType == 'chapter' ||
        taskType == 'planning' ||
        taskType == 'revision') {
      return 'medium';
    }
    return 'low';
  }

  String _noteFor({
    required String taskType,
    required String stage,
    required bool touchesNarrativeAsset,
  }) {
    if (touchesNarrativeAsset) {
      return '当前节点已直接改动伏笔、时间线或关系资产，需要重点核对承诺推进、事件顺序和关系变化是否一致。';
    }
    if (taskType == 'chapter' && stage == 'sample') {
      return '样章阶段要提前检查伏笔埋设、事件顺序和人物关系张力是否站得住。';
    }
    return '检查待回收伏笔、关键关系变化与最近事件顺序是否仍和正文推进保持一致。';
  }
}
