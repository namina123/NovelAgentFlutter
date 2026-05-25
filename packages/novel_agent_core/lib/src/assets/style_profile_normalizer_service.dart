import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'style_profile.dart';

class StyleProfileNormalizerService {
  const StyleProfileNormalizerService();

  StyleProfile normalize(JsonMap raw) {
    // 中文注释: 风格资产归一化统一补齐字段，便于导入导出和多策略共享同一对象模型。
    return StyleProfile(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(
        raw['display_name'],
        ValueReaders.stringValue(raw['name']),
      ).trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      genre: ValueReaders.stringValue(raw['genre']).trim(),
      tone: ValueReaders.stringValue(raw['tone']).trim(),
      audience: ValueReaders.stringValue(raw['audience']).trim(),
      guardrails: ValueReaders.stringList(raw['guardrails']),
      tags: ValueReaders.stringList(raw['tags']),
      examplePaths: ValueReaders.stringList(raw['example_paths']),
      inheritedFromIds: ValueReaders.stringList(raw['inherited_from_ids']),
      defaultForProject: ValueReaders.boolValue(raw['default_for_project']),
      sourcePath: ValueReaders.stringValue(raw['source_path']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(StyleProfile style) {
    return <String, Object?>{
      'id': style.id,
      'display_name': style.displayName,
      'summary': style.summary,
      'genre': style.genre,
      'tone': style.tone,
      'audience': style.audience,
      'guardrails': style.guardrails,
      'tags': style.tags,
      'example_paths': style.examplePaths,
      'inherited_from_ids': style.inheritedFromIds,
      'default_for_project': style.defaultForProject,
      'source_path': style.sourcePath,
      'metadata': ValueReaders.deepCopyMap(style.metadata),
    };
  }
}
