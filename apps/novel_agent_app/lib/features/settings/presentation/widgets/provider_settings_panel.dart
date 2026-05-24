import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../models/settings_view_data.dart';
import 'provider_detail_pane.dart';
import 'provider_list_pane.dart';

class ProviderSettingsPanel extends StatelessWidget {
  const ProviderSettingsPanel({
    super.key,
    required this.providers,
    required this.onProviderSelected,
    required this.onProviderSaved,
    required this.onProviderDeleted,
  });

  final List<ProviderEndpointViewData> providers;
  final ValueChanged<String> onProviderSelected;
  final ValueChanged<Map<String, Object?>> onProviderSaved;
  final ValueChanged<String> onProviderDeleted;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 接口配置面板拆成列表与详情两块，确保设置页不是一个不断长胖的大表单页面。
    final selected = providers.isEmpty
        ? null
        : providers.firstWhere(
            (item) => item.isSelected,
            orElse: () => providers.first,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              SizedBox(
                height: 220,
                child: PanelSurface(
                  child: ProviderListPane(
                    providers: providers,
                    onProviderSelected: onProviderSelected,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PanelSurface(
                  child: ProviderDetailPane(
                    provider: selected,
                    onProviderSaved: onProviderSaved,
                    onProviderDeleted: onProviderDeleted,
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 340,
              child: PanelSurface(
                child: ProviderListPane(
                  providers: providers,
                  onProviderSelected: onProviderSelected,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PanelSurface(
                child: ProviderDetailPane(
                  provider: selected,
                  onProviderSaved: onProviderSaved,
                  onProviderDeleted: onProviderDeleted,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
