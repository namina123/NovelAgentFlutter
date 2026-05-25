import '../common/json_types.dart';

class LongTaskStyleDriftSignalService {
  List<JsonMap> buildSignals({
    required String taskType,
    required String stage,
    required List<String> memorySectionTitles,
    required List<String> outputPaths,
  }) {
    // 中文注释: 风格漂移信号只关心文风相关锚点与输出类型，不和其他领域规则混在一起。
    final hasStyleAnchor = memorySectionTitles.contains('风格锚点');
    final touchesStyleFile = outputPaths.any(
      (path) => path.trim().toLowerCase().startsWith('styles/'),
    );
    if (!hasStyleAnchor && !touchesStyleFile && taskType != 'chapter') {
      return const <JsonMap>[];
    }
    final severity =
        touchesStyleFile || (taskType == 'chapter' && stage == 'sample')
        ? 'high'
        : (taskType == 'chapter' || taskType == 'revision' ? 'medium' : 'low');
    return <JsonMap>[
      <String, Object?>{
        'domain': 'style',
        'severity': severity,
        'title': '文风守恒',
        'note': taskType == 'chapter' && stage == 'sample'
            ? '样章阶段要重点检查文风是否稳定、入口是否干净利落。'
            : '检查文风是否仍符合已确认风格锚点，避免语言质地突然漂移。',
      },
    ];
  }
}
