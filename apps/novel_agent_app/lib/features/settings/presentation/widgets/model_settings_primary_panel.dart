import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../models/model_editor_view_data.dart';
import '../models/settings_search_option.dart';
import 'connection_status_card.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_search_dropdown_field.dart';
import 'settings_labeled_text_field.dart';
import 'settings_switch_row.dart';

class ModelSettingsPrimaryPanel extends StatelessWidget {
  const ModelSettingsPrimaryPanel({
    super.key,
    required this.providerOptions,
    required this.providerController,
    required this.selectedProviderId,
    required this.modelController,
    required this.modelOptions,
    required this.editor,
    required this.thinkingEnabled,
    required this.thinkingEffort,
    required this.temperatureController,
    required this.topPController,
    required this.onProviderSelected,
    required this.onModelSelected,
    required this.onThinkingChanged,
    required this.onThinkingEffortChanged,
    required this.onTestConnection,
    required this.connectionResult,
    required this.connectionTesting,
    this.onOpenInterfacesTab,
  });

  /// 「当前没有接口」警告里「前往「接口」页」按钮的回调；为空（测试）时不渲染该按钮。
  final VoidCallback? onOpenInterfacesTab;

  final List<SettingsSearchOption<String>> providerOptions;
  final TextEditingController providerController;
  final String selectedProviderId;
  final TextEditingController modelController;
  final List<SettingsSearchOption<String>> modelOptions;
  final ModelEditorViewData editor;
  final bool thinkingEnabled;
  final String thinkingEffort;
  final TextEditingController temperatureController;
  final TextEditingController topPController;
  final ValueChanged<String?> onProviderSelected;
  final ValueChanged<String?> onModelSelected;
  final ValueChanged<bool> onThinkingChanged;
  final ValueChanged<String?> onThinkingEffortChanged;
  final VoidCallback onTestConnection;
  final ProviderConnectionValidationResultViewData connectionResult;
  final bool connectionTesting;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 主设置区只放写作时最常碰的模型选择与四个高价值参数，不把运行兼容细节掺进来。
    final visibleAdvancedFields = editor.visibleAdvancedFields;
    final showsReasoning = visibleAdvancedFields.isEmpty
        ? editor.supportsReasoning
        : visibleAdvancedFields.contains('thinking_enabled');
    final showsEffort = visibleAdvancedFields.isEmpty
        ? editor.supportsReasoning && editor.thinkingEffortSupported
        : visibleAdvancedFields.contains('thinking_effort');
    // 中文注释: 必须同时选中接口与模型 ID 才允许探测——连接测试验证的是这对组合。
    final modelIdTrimmed = modelController.text.trim();
    final canTestConnection =
        !connectionTesting && selectedProviderId.isNotEmpty && modelIdTrimmed.isNotEmpty;
    return SettingsFormSection(
      title: '写作模型',
      description: '先选接口，再选模型；模型必须绑定到一个接口。选好后可测试连接。',
      child: Column(
        children: [
          SettingsLabeledSearchDropdownField<String>(
            label: '默认接口',
            controller: providerController,
            selectedValue: selectedProviderId.isEmpty
                ? null
                : selectedProviderId,
            options: providerOptions,
            hintText: providerOptions.isEmpty
                ? '请先到「接口」页添加并保存接口'
                : '点输入框展开接口列表，或输入名称筛选',
            openOnFocus: true,
            enabled: providerOptions.isNotEmpty,
            onSelected: onProviderSelected,
          ),
          if (providerOptions.isEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '当前还没有可用接口。请先到「接口」页添加厂商地址与 API Key 并保存。',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onOpenInterfacesTab != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onOpenInterfacesTab,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // 中文注释: 把「请先到接口页」从死路变成一键可达——直接切到接口标签页。
                    child: const Text('前往「接口」页'),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          SettingsLabeledSearchDropdownField<String>(
            label: '默认模型',
            controller: modelController,
            selectedValue: modelIdTrimmed.isEmpty ? null : modelIdTrimmed,
            options: modelOptions,
            hintText: selectedProviderId.isEmpty
                ? '先选择接口，再挑选或输入模型 ID'
                : '点输入框展开模型列表，或直接输入任意模型 ID',
            openOnFocus: true,
            enabled: selectedProviderId.isNotEmpty || modelOptions.isNotEmpty,
            onSelected: onModelSelected,
          ),
          const SizedBox(height: 14),
          ActionButton(
            label: connectionTesting ? '正在测试连接...' : '测试连接',
            icon: Icons.wifi_tethering_rounded,
            tone: ActionButtonTone.neutral,
            compact: true,
            disabled: !canTestConnection,
            onPressed: onTestConnection,
          ),
          if (selectedProviderId.isEmpty || modelIdTrimmed.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '选择接口与模型后即可测试连接。',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ConnectionStatusCard(
            key: const ValueKey('model-connection-status'),
            result: connectionResult,
          ),
          if (showsReasoning) ...[
            const SizedBox(height: 16),
            if (editor.reasoningCanToggle)
              SettingsSwitchRow(
                label: '启用深度思考',
                value: thinkingEnabled,
                onChanged: onThinkingChanged,
                note: editor.thinkingParameterLabel,
              )
            else
              const SettingsSwitchRow(
                label: '深度思考',
                value: true,
                onChanged: null,
                note: '当前模型始终启用',
              ),
          ],
          if (showsEffort) ...[
            const SizedBox(height: 12),
            SettingsLabeledDropdownField<String>(
              label: editor.thinkingEffortParameterLabel,
              value: thinkingEffort,
              options: editor.thinkingEffortOptions
                  .map(
                    (item) => SettingsDropdownOption<String>(
                      value: item,
                      label: item,
                    ),
                  )
                  .toList(growable: false),
              onChanged: onThinkingEffortChanged,
            ),
          ],
          if (editor.supportsTemperature) ...[
            const SizedBox(height: 16),
            SettingsLabeledTextField(
              label: '温度',
              controller: temperatureController,
              hintText: '例如 0.8',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
          if (editor.supportsTopP) ...[
            const SizedBox(height: 12),
            SettingsLabeledTextField(
              label: 'Top P',
              controller: topPController,
              hintText: '例如 0.95',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
