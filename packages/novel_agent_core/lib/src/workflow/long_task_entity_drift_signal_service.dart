import '../common/json_types.dart';

class LongTaskEntityDriftSignalService {
  List<JsonMap> buildSignals({
    required String taskType,
    required String stage,
    required List<String> memorySectionTitles,
    required List<String> outputPaths,
  }) {
    // 中文注释: 角色锚点漂移信号只关心身份、动机、称谓和关系的一致性。
    final hasEntityAnchor = memorySectionTitles.contains('角色/身份锚点');
    final touchesEntityFile = outputPaths.any(
      (path) => path.trim().toLowerCase().startsWith('characters/'),
    );
    if (!hasEntityAnchor && !touchesEntityFile && taskType != 'chapter') {
      return const <JsonMap>[];
    }
    final severity =
        touchesEntityFile || (taskType == 'chapter' && stage == 'sample')
        ? 'medium'
        : (taskType == 'chapter' || taskType == 'revision' ? 'medium' : 'low');
    return <JsonMap>[
      <String, Object?>{
        'domain': 'entity',
        'severity': severity,
        'title': '角色锚点守恒',
        'note': '检查角色动机、身份、称谓和关系是否与既有锚点一致。',
      },
    ];
  }
}
