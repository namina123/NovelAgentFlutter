import '../common/json_types.dart';
import '../common/value_readers.dart';

abstract final class ReferenceExtractionConcurrencyModes {
  static const String single = 'single';
  static const String reservedParallel = 'reserved_parallel';
}

class ReferenceExtractionExecutionDiscipline {
  const ReferenceExtractionExecutionDiscipline({
    this.concurrencyMode = ReferenceExtractionConcurrencyModes.single,
    this.maxConcurrentBatches = 1,
    this.allowParallelHeavyTextConsumption = false,
    this.metadata = const <String, Object?>{},
  });

  final String concurrencyMode;
  final int maxConcurrentBatches;
  final bool allowParallelHeavyTextConsumption;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'concurrency_mode': concurrencyMode,
      'max_concurrent_batches': maxConcurrentBatches,
      'allow_parallel_heavy_text_consumption':
          allowParallelHeavyTextConsumption,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ReferenceExtractionExecutionDiscipline fromJson(JsonMap json) {
    return ReferenceExtractionExecutionDiscipline(
      concurrencyMode: ValueReaders.stringValue(
        json['concurrency_mode'],
        ReferenceExtractionConcurrencyModes.single,
      ).trim(),
      maxConcurrentBatches: ValueReaders.intValue(
        json['max_concurrent_batches'],
        1,
      ),
      allowParallelHeavyTextConsumption: ValueReaders.boolValue(
        json['allow_parallel_heavy_text_consumption'],
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}
