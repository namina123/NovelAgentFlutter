import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'foreshadow_record.dart';
import 'foreshadow_record_markdown_parser_service.dart';
import 'foreshadow_record_normalizer_service.dart';
import 'relationship_record.dart';
import 'relationship_record_markdown_parser_service.dart';
import 'relationship_record_normalizer_service.dart';
import 'shared_narrative_asset_context_section_service.dart';
import 'timeline_record.dart';
import 'timeline_record_markdown_parser_service.dart';
import 'timeline_record_normalizer_service.dart';

class SharedNarrativeAssetContextProjectionService {
  SharedNarrativeAssetContextProjectionService({
    SharedNarrativeAssetContextSectionService? contextSectionService,
    ForeshadowRecordMarkdownParserService? foreshadowParserService,
    ForeshadowRecordNormalizerService? foreshadowNormalizerService,
    TimelineRecordMarkdownParserService? timelineParserService,
    TimelineRecordNormalizerService? timelineNormalizerService,
    RelationshipRecordMarkdownParserService? relationshipParserService,
    RelationshipRecordNormalizerService? relationshipNormalizerService,
  }) : _contextSectionService =
           contextSectionService ??
           const SharedNarrativeAssetContextSectionService(),
       _foreshadowParserService =
           foreshadowParserService ?? ForeshadowRecordMarkdownParserService(),
       _foreshadowNormalizerService =
           foreshadowNormalizerService ??
           const ForeshadowRecordNormalizerService(),
       _timelineParserService =
           timelineParserService ?? TimelineRecordMarkdownParserService(),
       _timelineNormalizerService =
           timelineNormalizerService ?? const TimelineRecordNormalizerService(),
       _relationshipParserService =
           relationshipParserService ??
           RelationshipRecordMarkdownParserService(),
       _relationshipNormalizerService =
           relationshipNormalizerService ??
           const RelationshipRecordNormalizerService();

  final SharedNarrativeAssetContextSectionService _contextSectionService;
  final ForeshadowRecordMarkdownParserService _foreshadowParserService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;
  final TimelineRecordMarkdownParserService _timelineParserService;
  final TimelineRecordNormalizerService _timelineNormalizerService;
  final RelationshipRecordMarkdownParserService _relationshipParserService;
  final RelationshipRecordNormalizerService _relationshipNormalizerService;

  List<JsonMap> buildSections({
    required JsonMap projectFileContents,
    List<String> focusPaths = const <String>[],
    int maxItemsPerSection = 4,
  }) {
    // 中文注释: 这个投影层只负责把已加载的共享资产文件压成上下文块，不直接参与文件选择或预算裁剪。
    final foreshadows = <ForeshadowRecord>[];
    final timelines = <TimelineRecord>[];
    final relationships = <RelationshipRecord>[];
    projectFileContents.forEach((key, value) {
      final path = key.trim();
      final content = ValueReaders.stringValue(value).trim();
      if (path.isEmpty || content.isEmpty) {
        return;
      }
      final lower = path.toLowerCase();
      if (lower.startsWith('assets/foreshadows/') ||
          lower.startsWith('world/foreshadows/')) {
        foreshadows.add(
          _foreshadowNormalizerService.normalize(
            _foreshadowParserService.parseDocument(
              content,
              fallbackId: _fallbackId(path, '.foreshadow.md'),
              relativePath: path,
            ),
          ),
        );
        return;
      }
      if (lower.startsWith('assets/timeline/')) {
        timelines.add(
          _timelineNormalizerService.normalize(
            _timelineParserService.parseDocument(
              content,
              fallbackId: _fallbackId(path, '.timeline.md'),
              relativePath: path,
            ),
          ),
        );
        return;
      }
      if (lower.startsWith('assets/relationships/')) {
        relationships.add(
          _relationshipNormalizerService.normalize(
            _relationshipParserService.parseDocument(
              content,
              fallbackId: _fallbackId(path, '.relationship.md'),
              relativePath: path,
            ),
          ),
        );
      }
    });
    return _contextSectionService.buildSections(
      foreshadows: foreshadows,
      timelines: timelines,
      relationships: relationships,
      focusPaths: focusPaths,
      maxItemsPerSection: maxItemsPerSection,
    );
  }

  String _fallbackId(String relativePath, String suffix) {
    var name = relativePath.split('/').last;
    final lower = name.toLowerCase();
    if (lower.endsWith(suffix)) {
      name = name.substring(0, name.length - suffix.length);
    } else if (lower.endsWith('.md')) {
      name = name.substring(0, name.length - 3);
    }
    return name.trim();
  }
}
