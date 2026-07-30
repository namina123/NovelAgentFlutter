import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../shared/services/desktop_text_file_picker_service.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/agent_ecosystem_action_handler.dart';
import '../models/ecosystem_import_command_view_data.dart';

class EcosystemImportOverlay extends StatefulWidget {
  const EcosystemImportOverlay({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final EcosystemImportCommandViewData viewData;
  final AgentEcosystemActionHandler actionHandler;

  @override
  State<EcosystemImportOverlay> createState() => _EcosystemImportOverlayState();
}

class _EcosystemImportOverlayState extends State<EcosystemImportOverlay> {
  late final TextEditingController _bundlePathController;
  late bool _overwrite;
  late bool _allowBuiltinShadow;

  @override
  void initState() {
    super.initState();
    _bundlePathController = TextEditingController(
      text: widget.viewData.bundlePath,
    );
    _overwrite = widget.viewData.overwrite;
    _allowBuiltinShadow = widget.viewData.allowBuiltinShadow;
  }

  @override
  void dispose() {
    _bundlePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 生态导入弹层只收集路径和策略开关，不直接依赖具体导入实现。
    final colors = context.novelThemeColors;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 780,
              maxHeight: 680,
              minWidth: 320,
            ),
            child: PanelSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '导入生态包',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colors.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '输入一个 `.customization.json` 生态包的绝对路径。',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            widget.actionHandler.onEcosystemImportDismissed,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: '关闭',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _bundlePathController,
                    label: '生态包路径',
                    hint: '例如：D:\\exports\\novel_bundle.customization.json',
                    // 中文注释: 桌面端给一个「浏览」按钮免去手粘绝对路径；选择器只有桌面实现
                    // (PowerShell/osascript/zenity)，移动端不显示以免放一个死按钮。
                    onBrowse: _canBrowseOnDesktop ? _browseBundle : null,
                  ),
                  const SizedBox(height: 6),
                  CheckboxListTile(
                    value: _overwrite,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    controlAffinity: ListTileControlAffinity.leading,
                    titleAlignment: ListTileTitleAlignment.top,
                    title: const Text('覆盖项目内同 ID 条目'),
                    onChanged: (value) {
                      setState(() {
                        _overwrite = value ?? true;
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: _allowBuiltinShadow,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    controlAffinity: ListTileControlAffinity.leading,
                    titleAlignment: ListTileTitleAlignment.top,
                    title: const Text('允许项目条目遮蔽内置条目'),
                    onChanged: (value) {
                      setState(() {
                        _allowBuiltinShadow = value ?? true;
                      });
                    },
                  ),
                  if (widget.viewData.status.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.viewData.status,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: colors.mutedTextColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.panelBackground.withValues(alpha: 0.72),
                        border: Border.all(color: colors.lineColor),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          widget.viewData.previewSummary.trim().isEmpty
                              ? '这里会显示导入预检摘要。'
                              : widget.viewData.previewSummary,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: colors.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            widget.actionHandler.onEcosystemImportDismissed,
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        // 中文注释: 导入进行中禁用提交并改文案，避免慢盘/网络下连点触发
                        // 并行导入写同一批项目文件。状态由控制器经 isImporting 回传。
                        onPressed: widget.viewData.isImporting ? null : _submit,
                        child: Text(
                          widget.viewData.isImporting ? '正在导入...' : '预检并导入',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    VoidCallback? onBrowse,
  }) {
    // 中文注释: 表单字段统一封装，后续替换视觉样式时不影响导入请求结构。
    final colors = context.novelThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.mutedTextColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: onBrowse == null
                ? null
                : IconButton(
                    tooltip: '浏览…',
                    icon: const Icon(Icons.folder_open_outlined, size: 20),
                    onPressed: onBrowse,
                  ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    widget.actionHandler.onEcosystemImportSubmitted(
      EcosystemImportRequestViewData(
        bundlePath: _bundlePathController.text,
        overwrite: _overwrite,
        allowBuiltinShadow: _allowBuiltinShadow,
      ),
    );
  }

  bool get _canBrowseOnDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  Future<void> _browseBundle() async {
    final picked = await const DesktopTextFilePickerService().pickSingleFile(
      dialogTitle: '选择生态包',
    );
    if (!mounted) {
      return;
    }
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _bundlePathController.text = picked;
      });
    }
  }
}
