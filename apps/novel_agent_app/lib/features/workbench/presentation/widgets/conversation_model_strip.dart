import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../models/selector_option_view_data.dart';
import 'selector_field.dart';

class ConversationModelStrip extends StatelessWidget {
  const ConversationModelStrip({
    super.key,
    required this.modelLabel,
    required this.modelOptions,
    required this.onModelSelected,
    this.showSurface = true,
  });

  final String modelLabel;
  final List<SelectorOptionViewData> modelOptions;
  final ValueChanged<String> onModelSelected;
  final bool showSurface;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 模型条只承接模型选择，不再混入项目级智能体组入口。
    final content = SelectorField(
      label: '模型',
      value: modelLabel,
      options: modelOptions,
      onSelected: onModelSelected,
    );
    if (!showSurface) {
      return content;
    }
    return PanelSurface(
      role: PanelSurfaceRole.inputDock,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: content,
    );
  }
}
