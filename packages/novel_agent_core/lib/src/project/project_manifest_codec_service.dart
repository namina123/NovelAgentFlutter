import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_manifest.dart';
import 'project_type_catalog_service.dart';

class ProjectManifestCodecService {
  ProjectManifestCodecService({
    ProjectTypeCatalogService? projectTypeCatalogService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService();

  static const String manifestRelativePath = '.novel_agent/project_manifest.json';

  final ProjectTypeCatalogService _projectTypeCatalogService;

  ProjectManifest create({
    required String title,
    required String projectType,
  }) {
    // 中文注释: 新建 manifest 时在这里统一补齐标题和项目类型，避免不同创建入口写出不同结构。
    final normalizedType = _projectTypeCatalogService.normalize(projectType);
    final cleanTitle = title.trim().isEmpty
        ? _projectTypeCatalogService.defaultTitle(normalizedType)
        : title.trim();
    return ProjectManifest(title: cleanTitle, projectType: normalizedType);
  }

  ProjectManifest parse(
    String source, {
    String fallbackTitle = '',
    String fallbackProjectType = 'novel',
  }) {
    // 中文注释: manifest 解析需要对旧文件和坏数据保持宽容，确保项目至少还能以普通小说打开。
    final cleanSource = source.trim();
    if (cleanSource.isEmpty) {
      return create(
        title: fallbackTitle,
        projectType: fallbackProjectType,
      );
    }
    final parsed = jsonDecode(cleanSource);
    if (parsed is! Map<Object?, Object?>) {
      return create(
        title: fallbackTitle,
        projectType: fallbackProjectType,
      );
    }
    return fromJson(
      Map<String, Object?>.from(parsed),
      fallbackTitle: fallbackTitle,
      fallbackProjectType: fallbackProjectType,
    );
  }

  ProjectManifest fromJson(
    JsonMap json, {
    String fallbackTitle = '',
    String fallbackProjectType = 'novel',
  }) {
    // 中文注释: JSON 到 manifest 的转换保持纯规则，方便仓储、测试和未来迁移脚本共用。
    final normalizedType = _projectTypeCatalogService.normalize(
      ValueReaders.stringValue(json['project_type'], fallbackProjectType),
    );
    final title = ValueReaders.stringValue(
      json['title'],
      fallbackTitle.trim().isEmpty
          ? _projectTypeCatalogService.defaultTitle(normalizedType)
          : fallbackTitle.trim(),
    );
    return ProjectManifest(
      title: title.trim().isEmpty
          ? _projectTypeCatalogService.defaultTitle(normalizedType)
          : title.trim(),
      projectType: normalizedType,
      schemaVersion: ValueReaders.intValue(json['schema_version'], 1),
    );
  }

  JsonMap toJson(ProjectManifest manifest) {
    // 中文注释: manifest 输出结构固定在这里，避免不同模块写出字段名不一致的项目描述文件。
    return <String, Object?>{
      'schema_version': manifest.schemaVersion,
      'title': manifest.title,
      'project_type': _projectTypeCatalogService.normalize(manifest.projectType),
    };
  }

  String encode(ProjectManifest manifest) {
    // 中文注释: 持久化格式统一使用可读缩进 JSON，方便用户和调试工具直接查看。
    return const JsonEncoder.withIndent('  ').convert(toJson(manifest));
  }
}
