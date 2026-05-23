import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_text_field.dart';

class NetworkSettingsPanel extends StatefulWidget {
  const NetworkSettingsPanel({
    super.key,
    required this.settings,
    required this.onSaved,
  });

  final Map<String, Object?> settings;
  final ValueChanged<Map<String, Object?>> onSaved;

  @override
  State<NetworkSettingsPanel> createState() => _NetworkSettingsPanelState();
}

class _NetworkSettingsPanelState extends State<NetworkSettingsPanel> {
  late String _proxyMode;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _timeoutController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController();
    _portController = TextEditingController();
    _timeoutController = TextEditingController();
    _sync();
  }

  @override
  void didUpdateWidget(covariant NetworkSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _sync();
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '网络偏好',
          description: '临时代理端口 12334 只允许当前进程生效；保存时不会把它写回设置文件。',
          child: Column(
            children: [
              SettingsLabeledDropdownField<String>(
                label: '代理模式',
                value: _proxyMode,
                options: const [
                  SettingsDropdownOption(value: 'system', label: '系统网络环境'),
                  SettingsDropdownOption(value: 'custom', label: '自定义代理'),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _proxyMode = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '代理主机',
                controller: _hostController,
                enabled: _proxyMode == 'custom',
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '代理端口',
                controller: _portController,
                enabled: _proxyMode == 'custom',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: 'AI 超时（秒）',
                controller: _timeoutController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存网络设置',
          expanded: true,
          icon: Icons.save_outlined,
          onPressed: () {
            widget.onSaved(<String, Object?>{
              'proxy_mode': _proxyMode,
              'proxy_host': _hostController.text.trim(),
              'proxy_port': _portController.text.trim(),
              'timeout_seconds': _timeoutController.text.trim(),
            });
          },
        ),
      ],
    );
  }

  void _sync() {
    _proxyMode = (widget.settings['proxy_mode'] ?? 'system').toString();
    _hostController.text = (widget.settings['proxy_host'] ?? '').toString();
    _portController.text = (widget.settings['proxy_port'] ?? '').toString();
    _timeoutController.text =
        (widget.settings['timeout_seconds'] ?? '900').toString();
  }
}
