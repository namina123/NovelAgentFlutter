import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/task_center_view_data.dart';

class TaskCenterChapterLengthDefaultsService {
  const TaskCenterChapterLengthDefaultsService();

  static const TaskCenterChapterLengthConfigViewData _fallback =
      TaskCenterChapterLengthConfigViewData(
        enableChapterWordConstraints: true,
        chapterWordTarget: 2000,
        chapterWordMin: 1600,
        chapterWordMax: 2600,
        sampleChapterWordTarget: 1800,
        sampleChapterWordMin: 1400,
        sampleChapterWordMax: 2400,
      );

  TaskCenterChapterLengthConfigViewData resolve(
    ProjectRuntimeProfile? runtimeProfile,
  ) {
    final options =
        runtimeProfile?.initialRunOptions ?? const <String, Object?>{};
    final fallback = _fallback;
    return TaskCenterChapterLengthConfigViewData(
      enableChapterWordConstraints:
          options.containsKey('enable_chapter_word_constraints')
          ? ValueReaders.boolValue(options['enable_chapter_word_constraints'])
          : fallback.enableChapterWordConstraints,
      chapterWordTarget: _intOrFallback(
        options['chapter_word_target'],
        fallback.chapterWordTarget,
      ),
      chapterWordMin: _intOrFallback(
        options['chapter_word_min'],
        fallback.chapterWordMin,
      ),
      chapterWordMax: _intOrFallback(
        options['chapter_word_max'],
        fallback.chapterWordMax,
      ),
      sampleChapterWordTarget: _intOrFallback(
        options['sample_chapter_word_target'],
        fallback.sampleChapterWordTarget,
      ),
      sampleChapterWordMin: _intOrFallback(
        options['sample_chapter_word_min'],
        fallback.sampleChapterWordMin,
      ),
      sampleChapterWordMax: _intOrFallback(
        options['sample_chapter_word_max'],
        fallback.sampleChapterWordMax,
      ),
    );
  }

  int _intOrFallback(Object? value, int fallback) {
    final resolved = ValueReaders.intValue(value);
    return resolved > 0 ? resolved : fallback;
  }
}
