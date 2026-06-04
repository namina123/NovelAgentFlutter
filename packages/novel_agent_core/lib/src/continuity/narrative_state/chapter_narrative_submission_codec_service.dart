import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'chapter_narrative_submission.dart';

class ChapterNarrativeSubmissionCodecService {
  const ChapterNarrativeSubmissionCodecService();

  ChapterNarrativeSubmission fromJson(JsonMap json) {
    // 中文注释: submission decode 集中在这里，供后续工具输入和 repository 共享同一入口。
    return ChapterNarrativeSubmission.fromJson(json);
  }

  JsonMap toJson(ChapterNarrativeSubmission submission) {
    // 中文注释: submission encode 保持薄包装，避免调用点重复手拼章节状态提交结构。
    return submission.toJson();
  }

  List<ChapterNarrativeSubmission> fromJsonList(Object? rawSubmissions) {
    // 中文注释: 章节提交列表在初期可能为空，这里必须稳定返回空数组。
    return ValueReaders.mapList(
      rawSubmissions,
    ).map(ChapterNarrativeSubmission.fromJson).toList(growable: false);
  }
}
