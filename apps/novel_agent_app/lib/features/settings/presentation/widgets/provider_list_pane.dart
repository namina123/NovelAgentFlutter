import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/settings_view_data.dart';

class ProviderListPane extends StatelessWidget {
  const ProviderListPane({
    super.key,
    required this.providers,
    required this.onProviderSelected,
    required this.onProviderCreateRequested,
  });

  final List<ProviderEndpointViewData> providers;
  final ValueChanged<String> onProviderSelected;
  final VoidCallback onProviderCreateRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 接口列表独立成 pane，后续加入搜索、排序和筛选时不影响详情和页头。
    final panel = context.novelThemeSurfaces.panel;
    final optionTile = context.novelThemeSurfaces.optionTile;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panel.backgroundColor.withValues(alpha: 0.8),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: panel.borderColor,
          width: AppChrome.borderWidth,
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: providers.length + 1,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == providers.length) {
            return OutlinedButton.icon(
              onPressed: onProviderCreateRequested,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加接口'),
            );
          }
          final provider = providers[index];
          final isDraft = provider.id == '__new__';
          final title = provider.title.trim().isEmpty
              ? (isDraft ? '新接口（未保存）' : '未命名接口')
              : provider.title;
          final subtitle = isDraft && provider.baseUrl.trim().isEmpty
              ? '填写厂商名称、密钥与地址后保存'
              : '${(provider.protocol == 'openai_compatible') ? 'OpenAI 兼容' : provider.protocol} · ${provider.baseUrl.trim().isEmpty ? '未填写地址' : provider.baseUrl}';
          return Material(
            color: provider.isSelected
                ? optionTile.highlightBackgroundColor
                : optionTile.backgroundColor,
            borderRadius: AppChrome.surfaceBorderRadius,
            child: InkWell(
              borderRadius: AppChrome.surfaceBorderRadius,
              onTap: () => onProviderSelected(provider.id),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppChrome.surfaceBorderRadius,
                  border: Border.all(
                    color: provider.isSelected
                        ? optionTile.highlightBorderColor
                        : optionTile.borderColor,
                    width: AppChrome.borderWidth,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: optionTile.foregroundColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: optionTile.mutedForegroundColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.apiKeyState,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        // 中文注释: 未配置密钥用警示色突出，已配置保持弱化，便于扫一眼定位待补的接口。
                        color: provider.apiKeyState.contains('未配置')
                            ? Theme.of(context).colorScheme.error
                            : optionTile.mutedForegroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
