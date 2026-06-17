import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../models/model_editor_view_data.dart';
import '../models/settings_view_data.dart';
import 'provider_detail_pane.dart';
import 'provider_list_pane.dart';

class ProviderSettingsPanel extends StatelessWidget {
  const ProviderSettingsPanel({
    super.key,
    required this.providers,
    required this.providerDirectoryOptions,
    required this.allModelOptions,
    this.providerConnectionValidationResult =
        ProviderConnectionValidationResultViewData.initial,
    required this.onProviderSelected,
    required this.onProviderCreateRequested,
    required this.onProviderDetailBackRequested,
    required this.onProviderSaved,
    required this.onProviderDeleted,
    required this.onConnectionTestRequested,
  });

  final List<ProviderEndpointViewData> providers;
  final List<ProviderDirectoryOptionViewData> providerDirectoryOptions;
  final List<SettingsSearchOptionViewData> allModelOptions;
  final ProviderConnectionValidationResultViewData providerConnectionValidationResult;
  final ValueChanged<String> onProviderSelected;
  final VoidCallback onProviderCreateRequested;
  final VoidCallback onProviderDetailBackRequested;
  final ValueChanged<Map<String, Object?>> onProviderSaved;
  final ValueChanged<String> onProviderDeleted;
  final ValueChanged<Map<String, Object?>> onConnectionTestRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 接口配置面板拆成列表与详情两块，确保设置页不是一个不断长胖的大表单页面。
    ProviderEndpointViewData? selected;
    for (final item in providers) {
      if (item.isSelected) {
        selected = item;
        break;
      }
    }
    final detailId = selected?.id ?? '__new__';
    final detailKey = GlobalObjectKey('provider-detail-$detailId');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          if (selected == null) {
            return PanelSurface(
              child: ProviderListPane(
                providers: providers,
                onProviderSelected: onProviderSelected,
                onProviderCreateRequested: onProviderCreateRequested,
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: PanelSurface(
                  child: ProviderDetailPane(
                    key: detailKey,
                    provider: selected,
                    providerDirectoryOptions: providerDirectoryOptions,
                    modelOptions: allModelOptions,
                    onConnectionTestRequested: onConnectionTestRequested,
                    onBackRequested: onProviderDetailBackRequested,
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
                  onProviderCreateRequested: onProviderCreateRequested,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PanelSurface(
                child: ProviderDetailPane(
                  key: detailKey,
                  provider: selected,
                  providerDirectoryOptions: providerDirectoryOptions,
                  modelOptions: allModelOptions,
                  onConnectionTestRequested: onConnectionTestRequested,
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
