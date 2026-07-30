import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

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
  late String _proxyProtocol;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _timeoutController;
  late final TextEditingController _transportRetryAttemptsController;
  late bool _transportRetryEnabled;
  // 中文注释: 自定义代理保存前的本地校验错误（host 空 / port 越界），不再静默归一。
  String _formError = '';

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController();
    _portController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _timeoutController = TextEditingController();
    _transportRetryAttemptsController = TextEditingController();
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
    _usernameController.dispose();
    _passwordController.dispose();
    _timeoutController.dispose();
    _transportRetryAttemptsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '网络偏好',
          description:
              '自定义代理会优先覆盖系统网络环境；协议头可留空，端口固定限制在 ${NetworkProxyPortPolicy.minPort}-${NetworkProxyPortPolicy.maxPort}。',
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
              SettingsLabeledDropdownField<String>(
                label: '代理协议',
                value: _proxyProtocol,
                options: const [
                  SettingsDropdownOption(value: '', label: '不指定'),
                  SettingsDropdownOption(value: 'http', label: 'HTTP'),
                  SettingsDropdownOption(value: 'socks5', label: 'SOCKS5'),
                ],
                onChanged: _proxyMode == 'custom'
                    ? (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _proxyProtocol = value;
                        });
                      }
                    : (_) {},
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '代理 IP',
                controller: _hostController,
                enabled: _proxyMode == 'custom',
                hintText: '127.0.0.1',
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '代理端口',
                controller: _portController,
                enabled: _proxyMode == 'custom',
                keyboardType: TextInputType.number,
                hintText:
                    '${NetworkProxyPortPolicy.minPort}-${NetworkProxyPortPolicy.maxPort}',
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '代理用户名（可选）',
                controller: _usernameController,
                enabled: _proxyMode == 'custom',
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '代理密码（可选）',
                controller: _passwordController,
                enabled: _proxyMode == 'custom',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: 'AI 超时（秒）',
                controller: _timeoutController,
                keyboardType: TextInputType.number,
                hintText: '建议 60-900',
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _transportRetryEnabled,
                title: const Text('瞬时网络错误自动重试'),
                subtitle: const Text('默认对连接被提前关闭等抖动做有限内置重试。'),
                onChanged: (value) {
                  setState(() {
                    _transportRetryEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '自动重试次数',
                controller: _transportRetryAttemptsController,
                enabled: _transportRetryEnabled,
                keyboardType: TextInputType.number,
                hintText: '0-5',
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-5]')),
                  LengthLimitingTextInputFormatter(1),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存网络设置',
          expanded: true,
          icon: Icons.save_outlined,
          onPressed: _save,
        ),
        if (_formError.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _formError,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  void _sync() {
    _proxyMode = (widget.settings['proxy_mode'] ?? 'system').toString();
    _proxyProtocol = (widget.settings['proxy_protocol'] ?? '').toString();
    _hostController.text = (widget.settings['proxy_host'] ?? '').toString();
    _portController.text = (widget.settings['proxy_port'] ?? '').toString();
    _usernameController.text = (widget.settings['proxy_username'] ?? '')
        .toString();
    _passwordController.text = (widget.settings['proxy_password'] ?? '')
        .toString();
    _timeoutController.text = (widget.settings['timeout_seconds'] ?? '900')
        .toString();
    _transportRetryEnabled =
        widget.settings['transport_retry_enabled'] != false;
    _transportRetryAttemptsController.text =
        (widget.settings['transport_retry_attempts'] ?? '2').toString();
  }

  String _normalizedPortText(String rawValue) {
    // 中文注释: 端口规范统一复用 core 里的固定范围策略，避免 GUI 与 CLI 口径漂移。
    return NetworkProxyPortPolicy.normalizeText(rawValue);
  }

  void _save() {
    // 中文注释: 保存前显式校验自定义代理(host/port)、超时、重试次数——不再让 core/网关层
    // 默默归一或静默回落默认值，否则用户以为自己填的值生效了，实际被吞掉。
    final errors = <String>[];
    if (_proxyMode == 'custom') {
      final host = _hostController.text.trim();
      final portRaw = _portController.text.trim();
      if (host.isEmpty) {
        errors.add('自定义代理需要填写主机（host）。');
      }
      // 中文注释: 空端口必须报错——core 的 _normalizedNetworkDocument 在 custom+空端口时会
      // 静默把 proxy_mode 改回 system 并清空所有代理字段，用户会看到"保存成功"后下拉跳回系统网络。
      if (portRaw.isEmpty) {
        errors.add('自定义代理需要填写端口。');
      } else {
        final port = int.tryParse(portRaw);
        if (port == null ||
            port < NetworkProxyPortPolicy.minPort ||
            port > NetworkProxyPortPolicy.maxPort) {
          errors.add(
            '端口需是 ${NetworkProxyPortPolicy.minPort}-${NetworkProxyPortPolicy.maxPort} 之间的整数（当前 "$portRaw"）。',
          );
        }
      }
    }
    final timeoutRaw = _timeoutController.text.trim();
    // 中文注释: 超时字段无 inputFormatter 时桌面键盘可输入字母/负数；网关层对不可解析或 ≤0 的值
    // 静默回落 90s，与表单默认 900 差 10 倍且用户看不到——保存前拦截。
    if (timeoutRaw.isEmpty) {
      errors.add('AI 超时需填写一个正整数秒数。');
    } else {
      final timeout = int.tryParse(timeoutRaw);
      if (timeout == null || timeout <= 0) {
        errors.add('AI 超时需是大于 0 的整数（当前 "$timeoutRaw"）。');
      } else if (timeout > 3600) {
        errors.add('AI 超时建议不超过 3600 秒（当前 "$timeoutRaw"）。');
      }
    }
    if (_transportRetryEnabled) {
      final retryRaw = _transportRetryAttemptsController.text.trim();
      // 中文注释: 重试次数 core 会 clamp(0,5)，输入 6-9 会被默默改成 5——保存前拦截。
      final retry = int.tryParse(retryRaw);
      if (retry == null || retry < 0 || retry > 5) {
        errors.add('自动重试次数需是 0-5 之间的整数（当前 "$retryRaw"）。');
      }
    }
    if (errors.isNotEmpty) {
      setState(() => _formError = errors.join('；'));
      return;
    }
    setState(() => _formError = '');
    final normalizedPort = _normalizedPortText(_portController.text);
    widget.onSaved(<String, Object?>{
      'proxy_mode': _proxyMode,
      'proxy_protocol': _proxyProtocol,
      'proxy_host': _hostController.text.trim(),
      'proxy_port': normalizedPort,
      'proxy_username': _usernameController.text.trim(),
      'proxy_password': _passwordController.text,
      'timeout_seconds': _timeoutController.text.trim(),
      'transport_retry_enabled': _transportRetryEnabled,
      'transport_retry_attempts': _transportRetryAttemptsController.text.trim(),
    });
  }
}
