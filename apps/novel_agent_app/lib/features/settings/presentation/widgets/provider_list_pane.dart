import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../models/settings_view_data.dart';

class ProviderListPane extends StatelessWidget {
  const ProviderListPane({
    super.key,
    required this.providers,
    required this.onProviderSelected,
  });

  final List<ProviderEndpointViewData> providers;
  final ValueChanged<String> onProviderSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 接口列表独立成 pane，后续加入搜索、排序和筛选时不影响详情和页头。
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: AppPalette.line,
          width: AppChrome.borderWidth,
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: providers.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final provider = providers[index];
          return Material(
            color: provider.isSelected
                ? AppPalette.accentSoft
                : AppPalette.panel,
            borderRadius: AppChrome.surfaceBorderRadius,
            child: InkWell(
              borderRadius: AppChrome.surfaceBorderRadius,
              onTap: () => onProviderSelected(provider.id),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppChrome.surfaceBorderRadius,
                  border: Border.all(
                    color: AppPalette.line,
                    width: AppChrome.borderWidth,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${provider.protocol} · ${provider.baseUrl}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.mutedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.apiKeyState,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.mutedText,
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
