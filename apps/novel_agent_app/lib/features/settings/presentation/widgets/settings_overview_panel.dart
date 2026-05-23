import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../models/settings_view_data.dart';

class SettingsOverviewPanel extends StatelessWidget {
  const SettingsOverviewPanel({
    super.key,
    required this.sections,
  });

  final List<SettingsSectionViewData> sections;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 概览型设置子页统一复用这一层，避免每个 tab 都重新拼接同类说明块和信息项。
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.text,
                ),
              ),
              if (section.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  section.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppPalette.mutedText,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: AppPalette.line, width: AppChrome.borderWidth),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppPalette.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              item.value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppPalette.text,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
