import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../widgets/document_workspace_canvas_frame.dart';
import 'document_resource_render_request.dart';
import 'document_resource_renderer.dart';

class DocumentStructuredResourceRenderer implements DocumentResourceRenderer {
  const DocumentStructuredResourceRenderer();

  @override
  String get id => 'structured';

  @override
  Widget build(BuildContext context, DocumentResourceRenderRequest request) {
    // 中文注释: 结构化渲染器负责把 SQLite 结构化资源和数据库型资源说明白，而不是只给一块泛化的结构摘要。
    final metadata = _metadataFrom(request);
    final surface = context.novelThemeSurfaces.panel;
    final extension = request.fileExtension.isEmpty
        ? '未识别'
        : request.fileExtension.toUpperCase();
    return DocumentWorkspaceCanvasFrame(
      title: request.title,
      relativePath: request.relativePath,
      status: metadata.statusLabel,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata.summaryLabel,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    fontWeight: FontWeight.w600,
                    color: surface.foregroundColor,
                  ),
                ),
                const SizedBox(height: 18),
                _StructuredFactRow(label: '资源类型', value: extension),
                _StructuredFactRow(
                  label: '资源路径',
                  value: request.normalizedPath.isEmpty
                      ? '未命名资源'
                      : request.normalizedPath,
                ),
                if (metadata.sourceIdentityLabel.isNotEmpty)
                  _StructuredFactRow(
                    label: '来源类型',
                    value: metadata.sourceIdentityLabel,
                  ),
                if (metadata.truthLabel.isNotEmpty)
                  _StructuredFactRow(label: '来源', value: metadata.truthLabel),
                _StructuredFactRow(
                  label: '只读',
                  value: metadata.isProjectionOnly ? '是' : '否',
                ),
                _StructuredFactRow(
                  label: '源码长度',
                  value: '${request.content.runes.length} 字符',
                ),
                _StructuredFactRow(
                  label: '编辑状态',
                  value: request.isDirty ? '存在未保存修改' : '已与当前工作区同步',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

_StructuredResourceMetadata _metadataFrom(
  DocumentResourceRenderRequest request,
) {
  // 中文注释: 元数据提取只解析投影文档的稳定 frontmatter 和 SQLite 扩展名，不在这里引入完整 YAML 依赖。
  final normalizedPath = request.normalizedPath.toLowerCase();
  final frontmatter = _frontmatterOf(request.content);
  final projectionId = _frontmatterScalar(frontmatter, 'projection_id');
  final projectionOnly = _frontmatterBool(frontmatter, 'projection_only');
  final sourceOfTruthPaths = _frontmatterStringList(
    frontmatter,
    'source_of_truth_paths',
  );
  final isSqliteFile =
      request.fileExtension == 'db' || request.fileExtension == 'sqlite';
  final isProjectionDocument =
      projectionId.isNotEmpty || sourceOfTruthPaths.isNotEmpty;
  final isSqliteProjectionSurface = normalizedPath.startsWith(
    'premise/sqlite_projection/',
  );
  final sourceIdentityLabel = isProjectionDocument
      ? '结构化资料摘要'
      : isSqliteFile
      ? '项目资料库文件'
      : isSqliteProjectionSurface
      ? '结构化资料目录'
      : '';
  final truthLabel = sourceOfTruthPaths.isEmpty
      ? (isSqliteFile ? '项目资料库主文件' : '')
      : sourceOfTruthPaths.join(' / ');
  final summaryLabel = isProjectionDocument
      ? '这是当前项目整理出的结构化资料摘要，可以先确认来源、是否可直接编辑，以及它对应的原始资料位置。'
      : isSqliteFile
      ? '当前资源是项目资料库文件，适合先确认来源和存放位置，再决定是否继续查看。'
      : '当前资源正在以结构摘要方式查看，适合先确认资源类型、路径和同步状态，再决定是否切回正文或继续查看关联内容。';
  return _StructuredResourceMetadata(
    statusLabel: isProjectionDocument ? '结构化资料' : '结构摘要',
    summaryLabel: summaryLabel,
    sourceIdentityLabel: sourceIdentityLabel,
    truthLabel: truthLabel,
    projectionId: projectionId,
    isProjectionOnly:
        projectionOnly || isSqliteFile || isSqliteProjectionSurface,
  );
}

String _frontmatterOf(String content) {
  // 中文注释: frontmatter 只负责投影文档的轻量元数据，不扩展成完整 Markdown/YAML 解析器。
  final normalized = content.replaceAll('\r\n', '\n');
  if (!normalized.startsWith('---\n')) {
    return '';
  }
  final closingIndex = normalized.indexOf('\n---\n', 4);
  if (closingIndex < 0) {
    return '';
  }
  return normalized.substring(4, closingIndex);
}

String _frontmatterScalar(String frontmatter, String key) {
  // 中文注释: 标量只读取最常见的 `key: value` 形式，保持结构化渲染器的依赖极轻。
  for (final rawLine in frontmatter.split('\n')) {
    final line = rawLine.trim();
    if (!line.startsWith('$key:')) {
      continue;
    }
    return line.substring(key.length + 1).trim();
  }
  return '';
}

bool _frontmatterBool(String frontmatter, String key) {
  // 中文注释: 布尔字段只接受 true/false 这类稳定字符串，避免投影文档的状态口径漂移。
  final value = _frontmatterScalar(frontmatter, key).toLowerCase();
  return value == 'true' || value == 'yes' || value == '1';
}

List<String> _frontmatterStringList(String frontmatter, String key) {
  // 中文注释: 列表字段只处理 YAML 常见缩进行，不在这里支持嵌套对象。
  final items = <String>[];
  final lines = frontmatter.split('\n');
  var inList = false;
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (!inList) {
      if (line == '$key:') {
        inList = true;
      }
      continue;
    }
    if (line.isEmpty) {
      continue;
    }
    if (!line.startsWith('- ')) {
      break;
    }
    final item = line.substring(2).trim();
    if (item.isNotEmpty) {
      items.add(item);
    }
  }
  return items;
}

class _StructuredResourceMetadata {
  const _StructuredResourceMetadata({
    required this.statusLabel,
    required this.summaryLabel,
    required this.sourceIdentityLabel,
    required this.truthLabel,
    required this.projectionId,
    required this.isProjectionOnly,
  });

  final String statusLabel;
  final String summaryLabel;
  final String sourceIdentityLabel;
  final String truthLabel;
  final String projectionId;
  final bool isProjectionOnly;
}

class _StructuredFactRow extends StatelessWidget {
  const _StructuredFactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: surface.mutedForegroundColor,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: surface.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
