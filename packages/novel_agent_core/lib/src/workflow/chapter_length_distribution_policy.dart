import '../common/json_types.dart';

class ChapterLengthDistributionPolicy {
  const ChapterLengthDistributionPolicy({
    this.rollingWindow = 4,
    this.mildDeviationRatio = 0.18,
    this.severeDeviationRatio = 0.35,
    this.mildAdjacentDeltaRatio = 0.22,
    this.severeAdjacentDeltaRatio = 0.45,
  });

  final int rollingWindow;
  final double mildDeviationRatio;
  final double severeDeviationRatio;
  final double mildAdjacentDeltaRatio;
  final double severeAdjacentDeltaRatio;

  JsonMap toJson() {
    // 中文注释: 分布策略定义“偏离到什么程度算提醒、重平衡或严重偏离”，不和具体项目文件绑定。
    return <String, Object?>{
      'rolling_window': rollingWindow,
      'mild_deviation_ratio': mildDeviationRatio,
      'severe_deviation_ratio': severeDeviationRatio,
      'mild_adjacent_delta_ratio': mildAdjacentDeltaRatio,
      'severe_adjacent_delta_ratio': severeAdjacentDeltaRatio,
    };
  }
}
