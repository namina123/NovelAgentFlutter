import 'package:flutter/material.dart';

import '../../application/services/context_settings_contract_service.dart';
import '../../../../../shared/widgets/action_button.dart';
import 'settings_form_section.dart';
import 'settings_labeled_text_field.dart';

class ContextSettingsPanel extends StatefulWidget {
  const ContextSettingsPanel({
    super.key,
    required this.settings,
    required this.defaultProjectPath,
    required this.allowProjectPathEdit,
    required this.onSaved,
  });

  final Map<String, Object?> settings;
  final String defaultProjectPath;
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
  bool _isCompatBridgeExpanded = false;

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
    // 中文注释: 上下文设置页先呈现 token 压力合同，再把旧字符字段收进折叠兼容桥，避免普通用户先看到一堆旧参数。
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
                label: '预留输出 token',
                controller: _reservedOutputTokensController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '自动压缩策略',
                controller: _autoCompactPolicyController,
                hintText: 'disabled / warning / warning_and_critical',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '优先 exact count',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text('当 provider 可返回精确 token 时优先采用。'),
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
              SettingsLabeledTextField(
                label: '压缩输出策略',
                controller: _compactionOutputPolicyController,
                hintText:
                    'structured_bullets / balanced_bullets / detailed_bullets',
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
                          '高级兼容桥',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '保留旧字符与文件包字段，供旧项目和迁移桥继续读取。',
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
            title: '旧版上下文字段',
            description:
                '这些字段仍会被保存，但普通 token 压力逻辑已经不再以它们为主。',
            child: Column(
              children: [
                SettingsLabeledTextField(
                  label: '压缩阈值百分比（兼容桥）',
                  controller: _compressionThresholdController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SettingsLabeledTextField(
                  label: '上下文包预算百分比',
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
                  label: '预留输出字符',
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
          onPressed: () {
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
                ContextSettingsContractService.preferExactCountKey:
                    _preferExactCount,
                ContextSettingsContractService.compactionOutputPolicyKey:
                    _compactionOutputPolicyController.text.trim(),
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
          },
        ),
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
    _autoCompactPolicyController.text =
        normalized[ContextSettingsContractService.autoCompactPolicyKey]
            .toString();
    _preferExactCount =
        normalized[ContextSettingsContractService.preferExactCountKey] as bool;
    _compactionOutputPolicyController.text =
        normalized[ContextSettingsContractService.compactionOutputPolicyKey]
            .toString();
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
}
