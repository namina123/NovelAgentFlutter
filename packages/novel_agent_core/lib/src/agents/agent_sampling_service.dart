import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentSamplingService {
  JsonMap normalizeSampling(JsonMap agent) {
    // 中文注释: 采样参数会被 GUI、CLI 和运行时共享，这里统一做安全范围裁剪。
    final temperature = ValueReaders.doubleValue(agent['temperature'], 0.85);
    final topP = ValueReaders.doubleValue(agent['top_p'], 0.95);
    final topK = ValueReaders.intValue(agent['top_k'], 0);
    return <String, Object?>{
      'temperature': temperature.clamp(0.0, 2.0),
      'top_p': topP.clamp(0.0, 1.0),
      'top_k': topK < 0 ? 0 : topK,
    };
  }
}
