import '../common/json_types.dart';

class LongTaskWorldDriftSignalService {
  List<JsonMap> buildSignals({
    required String taskType,
    required String stage,
    required List<String> memorySectionTitles,
    required List<String> outputPaths,
  }) {
    // 中文注释: 世界规则漂移信号只负责规则、代价和因果约束，不承担角色或文风判断。
    final hasWorldAnchor = memorySectionTitles.contains('世界硬约束');
    final touchesWorldFile = outputPaths.any((path) {
      final clean = path.trim().toLowerCase();
      return clean.startsWith('world/') || clean.startsWith('specs/');
    });
    if (!hasWorldAnchor &&
        !touchesWorldFile &&
        taskType != 'planning' &&
        taskType != 'chapter') {
      return const <JsonMap>[];
    }
    final severity = touchesWorldFile || taskType == 'planning'
        ? 'high'
        : (taskType == 'chapter' || stage == 'sample' ? 'medium' : 'low');
    return <JsonMap>[
      <String, Object?>{
        'domain': 'world',
        'severity': severity,
        'title': '世界规则守恒',
        'note': touchesWorldFile
            ? '当前节点触及设定文件，需重点检查新增规则、代价和因果是否自洽。'
            : '检查新增设定、能力代价和事件因果是否违反已确认世界规则。',
      },
    ];
  }
}
