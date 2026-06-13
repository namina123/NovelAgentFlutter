import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/task_center_view_data.dart';

class TaskCenterWorkflowCreateOptionMapperService {
  const TaskCenterWorkflowCreateOptionMapperService();

  JsonMap buildOptions({
    required TaskWorkflowCreateRequestViewData request,
    required JsonMap initialRunOptions,
    required String runtimeMode,
    required String runtimeBaselineId,
  }) {
    final chapterLength = request.chapterLength;
    return <String, Object?>{
      ...initialRunOptions,
      'runtime_baseline_id': runtimeBaselineId.trim(),
      'runtime_mode': runtimeMode.trim(),
      'outline_path': request.outlinePath.trim(),
      'seed_prompt': request.seedPrompt.trim(),
      'chapter_count': request.chapterCount,
      'checkpoint_interval': request.checkpointInterval,
      'enable_chapter_word_constraints':
          chapterLength.enableChapterWordConstraints,
      'chapter_word_target': chapterLength.chapterWordTarget,
      'chapter_word_min': chapterLength.chapterWordMin,
      'chapter_word_max': chapterLength.chapterWordMax,
      'sample_chapter_word_target': chapterLength.sampleChapterWordTarget,
      'sample_chapter_word_min': chapterLength.sampleChapterWordMin,
      'sample_chapter_word_max': chapterLength.sampleChapterWordMax,
    };
  }
}
