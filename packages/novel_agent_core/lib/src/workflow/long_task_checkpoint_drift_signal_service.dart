import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_entity_drift_signal_service.dart';
import 'long_task_style_drift_signal_service.dart';
import 'long_task_world_drift_signal_service.dart';

class LongTaskCheckpointDriftSignalService {
  LongTaskCheckpointDriftSignalService({
    LongTaskStyleDriftSignalService? styleService,
    LongTaskWorldDriftSignalService? worldService,
    LongTaskEntityDriftSignalService? entityService,
  }) : _styleService = styleService ?? LongTaskStyleDriftSignalService(),
       _worldService = worldService ?? LongTaskWorldDriftSignalService(),
       _entityService = entityService ?? LongTaskEntityDriftSignalService();

  final LongTaskStyleDriftSignalService _styleService;
  final LongTaskWorldDriftSignalService _worldService;
  final LongTaskEntityDriftSignalService _entityService;

  List<JsonMap> buildSignals({
    required String taskType,
    required String stage,
    required List<JsonMap> memorySections,
    required List<String> outputPaths,
  }) {
    // 中文注释: 聚合服务只负责把三类专门信号合并，不在这里下最终结论。
    final memorySectionTitles = memorySections
        .map((section) => ValueReaders.stringValue(section['title']).trim())
        .where((title) => title.isNotEmpty)
        .toList(growable: false);
    return <JsonMap>[
      ..._styleService.buildSignals(
        taskType: taskType,
        stage: stage,
        memorySectionTitles: memorySectionTitles,
        outputPaths: outputPaths,
      ),
      ..._worldService.buildSignals(
        taskType: taskType,
        stage: stage,
        memorySectionTitles: memorySectionTitles,
        outputPaths: outputPaths,
      ),
      ..._entityService.buildSignals(
        taskType: taskType,
        stage: stage,
        memorySectionTitles: memorySectionTitles,
        outputPaths: outputPaths,
      ),
    ];
  }
}
