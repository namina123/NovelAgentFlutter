import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../models/settings_view_data.dart';

class SettingsOverviewPanel extends StatelessWidget {
  const SettingsOverviewPanel({super.key, required this.sections});

  final List<SettingsSectionViewData> sections;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 概览型设置子页统一复用这一层，避免每个 tab 都重新拼接同类说明块和信息项。
    final surface = context.novelThemeSurfaces.panel;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final section = sections[index];
        return PanelSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: surface.foregroundColor,
                ),
              ),
              if (section.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  section.description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: surface.mutedForegroundColor,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ...section.items.map(_buildItem),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(SettingsItemViewData item) {
    // 中文注释: 单项说明块与整体概览拆开，后续替换成可编辑表单时可以逐项演化。
    return Builder(
      builder: (context) {
        final surface = context.novelThemeSurfaces.optionTile;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: surface.backgroundColor.withValues(alpha: 0.82),
            borderRadius: AppChrome.surfaceBorderRadius,
            border: Border.all(
              color: surface.borderColor,
              width: AppChrome.borderWidth,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 118,
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: surface.mutedForegroundColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  item.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: surface.foregroundColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
