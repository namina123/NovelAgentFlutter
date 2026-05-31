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
    final surface = context.novelThemeSurfaces.panel;
    final extension = request.fileExtension.isEmpty
        ? '未识别'
        : request.fileExtension.toUpperCase();
    return DocumentWorkspaceCanvasFrame(
      title: request.title,
      relativePath: request.relativePath,
      status: '结构摘要',
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前资源正在以结构摘要方式查看，适合先确认资源类型、路径和同步状态，再决定是否切回正文或继续查看关联内容。',
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
