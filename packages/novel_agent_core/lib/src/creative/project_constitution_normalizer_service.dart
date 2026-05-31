import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_constitution.dart';

class ProjectConstitutionNormalizerService {
  const ProjectConstitutionNormalizerService();

  ProjectConstitution normalize(JsonMap raw) {
    // 中文注释: 创作宪法归一化统一补齐关键字段，避免不同入口各自产生半结构化约束对象。
    return ProjectConstitution(
      id: ValueReaders.stringValue(
        raw['id'],
        ValueReaders.stringValue(raw['constitution_id'], 'project_constitution'),
      ).trim(),
      title: ValueReaders.stringValue(
        raw['title'],
        ValueReaders.stringValue(raw['display_name'], '项目创作宪法'),
      ).trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      principles: ValueReaders.stringList(raw['principles']),
      prohibitions: ValueReaders.stringList(raw['prohibitions']),
      naturalExpressionRules: ValueReaders.stringList(
        raw['natural_expression_rules'],
      ),
      sourcePath: ValueReaders.stringValue(raw['source_path']).trim(),
      metadata: ValueReaders.deepCopyMap(ValueReaders.mapValue(raw['metadata'])),
    );
  }

  JsonMap toDocument(ProjectConstitution constitution) {
    return <String, Object?>{
      'id': constitution.id,
      'title': constitution.title,
      'summary': constitution.summary,
      'principles': constitution.principles,
      'prohibitions': constitution.prohibitions,
      'natural_expression_rules': constitution.naturalExpressionRules,
      'source_path': constitution.sourcePath,
      'metadata': ValueReaders.deepCopyMap(constitution.metadata),
    };
  }
}
