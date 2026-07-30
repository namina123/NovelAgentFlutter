import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../application/services/context_settings_contract_service.dart';
import '../../../../../shared/widgets/action_button.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_form_section.dart';
import 'settings_labeled_text_field.dart';
import 'settings_switch_row.dart';

class ContextSettingsPanel extends StatefulWidget {
  const ContextSettingsPanel({
    super.key,
    required this.settings,
    required this.defaultProjectPath,
    required this.draftFallbackProtectionEnabled,
    required this.allowProjectPathEdit,
    required this.onSaved,
  });

  final Map<String, Object?> settings;
  final String defaultProjectPath;
  final bool draftFallbackProtectionEnabled;
  final bool allowProjectPathEdit;
  final ValueChanged<Map<String, Object?>> onSaved;

  @override
  State<ContextSettingsPanel> createState() => _ContextSettingsPanelState();
}

class _ContextSettingsPanelState extends State<ContextSettingsPanel> {
  final ContextSettingsContractService _contractService =
      const ContextSettingsContractService();
  late final TextEditingController _projectPathController;
  late final TextEditingController _modelWindowController;
  late final TextEditingController _windowHintController;
  late final TextEditingController _warningThresholdController;
  late final TextEditingController _criticalThresholdController;
  late final TextEditingController _reservedOutputTokensController;
  late final TextEditingController _autoCompactPolicyController;
  late final TextEditingController _compactionOutputPolicyController;
  late final TextEditingController _compressionThresholdController;
  late final TextEditingController _budgetController;
  late final TextEditingController _maxCharsController;
  late final TextEditingController _maxFilesController;
  late final TextEditingController _reservedOutputCharsController;
  bool _preferExactCount = false;
  bool _draftFallbackProtectionEnabled = true;
  bool _isCompatBridgeExpanded = false;
  // 中文注释: 百分比字段解析失败时收集错误，不再让 _ratioFromPercentText 静默回退 0.8。
  String _formError = '';

  @override
  void initState() {
    super.initState();
    _projectPathController = TextEditingController();
    _modelWindowController = TextEditingController();
    _windowHintController = TextEditingController();
    _warningThresholdController = TextEditingController();
    _criticalThresholdController = TextEditingController();
    _reservedOutputTokensController = TextEditingController();
    _autoCompactPolicyController = TextEditingController();
    _compactionOutputPolicyController = TextEditingController();
    _compressionThresholdController = TextEditingController();
    _budgetController = TextEditingController();
    _maxCharsController = TextEditingController();
    _maxFilesController = TextEditingController();
    _reservedOutputCharsController = TextEditingController();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ContextSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings ||
        oldWidget.defaultProjectPath != widget.defaultProjectPath) {
      _sync();
    }
  }

  @override
  void dispose() {
    _projectPathController.dispose();
    _modelWindowController.dispose();
    _windowHintController.dispose();
    _warningThresholdController.dispose();
    _criticalThresholdController.dispose();
    _reservedOutputTokensController.dispose();
    _autoCompactPolicyController.dispose();
    _compactionOutputPolicyController.dispose();
    _compressionThresholdController.dispose();
    _budgetController.dispose();
    _maxCharsController.dispose();
    _maxFilesController.dispose();
    _reservedOutputCharsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 上下文设置页先呈现 token 压力合同，再把历史参数收进折叠区，避免普通用户先看到一堆旧字段。
    final autoCompactPolicy = _autoCompactPolicyValue();
    final compactionOutputPolicy = _compactionOutputPolicyValue();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '上下文压力',
          description: '这些设置决定模型上下文窗口、预警/临界阈值，以及自动压缩的用户侧策略。',
          child: Column(
            children: [
              SettingsLabeledTextField(
                label: '默认项目路径',
                controller: _projectPathController,
                enabled: widget.allowProjectPathEdit,
              ),
              if (!widget.allowProjectPathEdit) ...[
                const SizedBox(height: 6),
                Text(
                  '移动端项目目录固定在应用文档目录内，不能更改。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '模型上下文窗口（token）',
                controller: _modelWindowController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '上下文窗口提示（token，可选）',
                controller: _windowHintController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '预警阈值（%）',
                controller: _warningThresholdController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '临界阈值（%）',
                controller: _criticalThresholdController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '为模型回复保留的额度（token）',
                controller: _reservedOutputTokensController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledDropdownField<String>(
                label: '自动压缩策略',
                value: autoCompactPolicy,
                options: const [
                  SettingsDropdownOption(
                    value: 'disabled',
                    label: '关闭自动压缩',
                  ),
                  SettingsDropdownOption(
                    value: 'warning',
                    label: '仅在接近上限时压缩',
                  ),
                  SettingsDropdownOption(
                    value: 'warning_and_critical',
                    label: '在接近上限或到达临界时压缩',
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _autoCompactPolicyController.text = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsSwitchRow(
                label: '普通会话草稿保护',
                note: '当模型没有走正式交付工具时，只把结果暂存为当前文档草稿，不直接写入正式项目文件。',
                value: _draftFallbackProtectionEnabled,
                onChanged: (value) {
                  setState(() {
                    _draftFallbackProtectionEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '优先使用精确计数',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text('当提供方可返回精确 token 时优先采用。'),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _preferExactCount,
                    onChanged: (value) {
                      setState(() {
                        _preferExactCount = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SettingsLabeledDropdownField<String>(
                label: '压缩输出样式',
                value: compactionOutputPolicy,
                options: const [
                  SettingsDropdownOption(
                    value: 'structured_bullets',
                    label: '结构化条目',
                  ),
                  SettingsDropdownOption(
                    value: 'balanced_bullets',
                    label: '均衡概览',
                  ),
                  SettingsDropdownOption(
                    value: 'detailed_bullets',
                    label: '详细展开',
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _compactionOutputPolicyController.text = value;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isCompatBridgeExpanded = !_isCompatBridgeExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '历史上下文参数',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '保留旧字符字段，供旧项目迁移和高级调整继续读取。',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isCompatBridgeExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isCompatBridgeExpanded) ...[
          const SizedBox(height: 12),
          SettingsFormSection(
            title: '历史上下文字段',
            description: '这些字段仍会被保存，但普通 token 压力逻辑已经不再以它们为主。',
            child: Column(
              children: [
                SettingsLabeledTextField(
                  label: '压缩阈值（%）',
                  controller: _compressionThresholdController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SettingsLabeledTextField(
                  label: '上下文预算（%）',
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SettingsLabeledTextField(
                  label: '单文件字符上限',
                  controller: _maxCharsController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SettingsLabeledTextField(
                  label: '每类文件纳入上限',
                  controller: _maxFilesController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SettingsLabeledTextField(
                  label: '为模型回复保留的额度（字符）',
                  controller: _reservedOutputCharsController,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ActionButton(
          label: '保存上下文设置',
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
    // 中文注释: 同步时先把旧字段和新字段统一归一，再把归一后的值填回表单，避免 panel 需要自己猜兼容优先级。
    final normalized = _contractService.normalizeForStorage(widget.settings);
    _projectPathController.text = widget.defaultProjectPath;
    _modelWindowController.text =
        normalized[ContextSettingsContractService.modelContextWindowTokensKey]
            .toString();
    _windowHintController.text =
        normalized[ContextSettingsContractService.contextWindowHintTokensKey]
            .toString();
    _warningThresholdController.text = _percentText(
      normalized[ContextSettingsContractService.warningThresholdRatioKey],
    );
    _criticalThresholdController.text = _percentText(
      normalized[ContextSettingsContractService.criticalThresholdRatioKey],
    );
    _reservedOutputTokensController.text =
        normalized[ContextSettingsContractService.reservedOutputTokensKey]
            .toString();
    _preferExactCount =
        normalized[ContextSettingsContractService.preferExactCountKey] as bool;
    _draftFallbackProtectionEnabled = widget.draftFallbackProtectionEnabled;
    _autoCompactPolicyController.text = _stringValue(
      normalized[ContextSettingsContractService.autoCompactPolicyKey],
      'warning_and_critical',
    );
    _compactionOutputPolicyController.text =
        _stringValue(
          normalized[ContextSettingsContractService.compactionOutputPolicyKey],
          'structured_bullets',
        );
    _compressionThresholdController.text =
        normalized[ContextSettingsContractService
                .compressionThresholdPercentKey]
            .toString();
    _budgetController.text =
        normalized[ContextSettingsContractService.contextPackBudgetPercentKey]
            .toString();
    _maxCharsController.text =
        normalized[ContextSettingsContractService.maxContextFileCharsKey]
            .toString();
    _maxFilesController.text =
        normalized[ContextSettingsContractService.maxContextFilesPerKindKey]
            .toString();
    _reservedOutputCharsController.text =
        normalized[ContextSettingsContractService.reservedOutputCharsKey]
            .toString();
  }

  double _ratioFromPercentText(String text) {
    // 中文注释: 百分比输入只在保存时转成 ratio，核心和控制器层以后只看比例合同。
    final value = double.tryParse(text.trim());
    if (value == null) {
      return 0.8;
    }
    if (value < 0) {
      return 0;
    }
    if (value > 100) {
      return 1;
    }
    return value / 100;
  }

  String _percentText(Object? ratioValue) {
    // 中文注释: ratio 回填给 UI 时显示成百分比，让用户继续沿用熟悉的阈值表达。
    final ratio = ratioValue is num
        ? ratioValue.toDouble()
        : double.tryParse(ratioValue?.toString().trim() ?? '') ?? 0.8;
    return (ratio * 100).round().toString();
  }

  void _save() {
    // 中文注释: 百分比字段非空但解析失败时如实报错并阻止保存，不再被 _ratioFromPercentText
    // 静默改成 0.8(80%)——那会让用户以为自己填的值生效了。
    final errors = <String>[];
    void checkPercent(TextEditingController controller, String label) {
      final text = controller.text.trim();
      if (text.isEmpty) {
        return;
      }
      final value = double.tryParse(text);
      if (value == null || value < 0 || value > 100) {
        errors.add('$label 需是 0-100 之间的数（当前 "$text"）');
      }
    }

    checkPercent(_warningThresholdController, '预警阈值');
    checkPercent(_criticalThresholdController, '临界阈值');
    checkPercent(_compressionThresholdController, '压缩阈值');
    checkPercent(_budgetController, '上下文预算');
    if (errors.isNotEmpty) {
      setState(() => _formError = errors.join('；'));
      return;
    }
    setState(() => _formError = '');
    widget.onSaved(
      _contractService.normalizeForStorage(<String, Object?>{
        'default_project_path': _projectPathController.text.trim(),
        ContextSettingsContractService.modelContextWindowTokensKey:
            _modelWindowController.text.trim(),
        ContextSettingsContractService.contextWindowHintTokensKey:
            _windowHintController.text.trim(),
        ContextSettingsContractService.warningThresholdRatioKey:
            _ratioFromPercentText(_warningThresholdController.text),
        ContextSettingsContractService.criticalThresholdRatioKey:
            _ratioFromPercentText(_criticalThresholdController.text),
        ContextSettingsContractService.reservedOutputTokensKey:
            _reservedOutputTokensController.text.trim(),
        ContextSettingsContractService.autoCompactPolicyKey:
            _autoCompactPolicyController.text.trim(),
        ContextSettingsContractService.preferExactCountKey: _preferExactCount,
        ContextSettingsContractService.compactionOutputPolicyKey:
            _compactionOutputPolicyController.text.trim(),
        AppSettings.draftFallbackProtectionConfigKey:
            _draftFallbackProtectionEnabled,
        ContextSettingsContractService.compressionThresholdPercentKey:
            _compressionThresholdController.text.trim(),
        ContextSettingsContractService.contextPackBudgetPercentKey:
            _budgetController.text.trim(),
        ContextSettingsContractService.maxContextFileCharsKey:
            _maxCharsController.text.trim(),
        ContextSettingsContractService.maxContextFilesPerKindKey:
            _maxFilesController.text.trim(),
        ContextSettingsContractService.reservedOutputCharsKey:
            _reservedOutputCharsController.text.trim(),
      }),
    );
  }

  String _stringValue(Object? value, String fallback) {
    // 中文注释: 下拉控件只接受稳定枚举值，遇到空值或脏值时回退到默认选项。
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _autoCompactPolicyValue() {
    // 中文注释: 自动压缩策略面向用户显示为自然中文选项，但保存时仍保持原始策略键不变。
    final value = _stringValue(
      _autoCompactPolicyController.text,
      'warning_and_critical',
    );
    switch (value) {
      case 'disabled':
      case 'warning':
      case 'warning_and_critical':
        return value;
      default:
        return 'warning_and_critical';
    }
  }

  String _compactionOutputPolicyValue() {
    // 中文注释: 压缩输出样式采用固定枚举映射，避免用户直接看到内部策略键。
    final value = _stringValue(
      _compactionOutputPolicyController.text,
      'structured_bullets',
    );
    switch (value) {
      case 'structured_bullets':
      case 'balanced_bullets':
      case 'detailed_bullets':
        return value;
      default:
        return 'structured_bullets';
    }
  }
}
