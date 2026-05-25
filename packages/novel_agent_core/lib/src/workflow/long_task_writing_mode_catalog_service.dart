import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../strategy/strategy_catalog_service.dart';

class LongTaskWritingModeCatalogService {
  const LongTaskWritingModeCatalogService({
    StrategyCatalogService strategyCatalogService =
        const StrategyCatalogService(),
  }) : _strategyCatalogService = strategyCatalogService;

  final StrategyCatalogService _strategyCatalogService;

  List<JsonMap> modes() {
    return _strategyCatalogService
        .modeDefinitions()
        .where(
          (mode) =>
              mode.projectStrategyId ==
              StrategyCatalogService.longTaskNovelStrategyId,
        )
        .map(
          (mode) => <String, Object?>{
            'id': mode.id,
            'title': mode.title,
            'description': mode.description,
            'human_involvement': mode.defaultAutonomyPolicy.title,
            'best_for': _bestFor(mode.id),
          },
        )
        .toList(growable: false);
  }

  JsonMap modeById(String modeId) {
    final cleanModeId = modeId.trim();
    for (final mode in modes()) {
      if (ValueReaders.stringValue(mode['id']) == cleanModeId) {
        return mode;
      }
    }
    return const <String, Object?>{};
  }

  String _bestFor(String modeId) {
    switch (modeId) {
      case 'seed_autopilot_novel':
        return '只有创作种子，还没有完整大纲时。';
      case 'full_outline_consensus':
        return '你想先把全书走向谈清楚，再放心交给长任务。';
      case 'volume_checkpoint_handoff':
        return '你希望控制大方向，但不想逐章盯写。';
      case 'chapter_brief_supervised':
        return '你想保留节奏控制权，同时让执行层自动化。';
      case 'salvage_restructure_existing':
        return '手里已经有旧材料，但结构混乱或中断过。';
      default:
        return '';
    }
  }
}
