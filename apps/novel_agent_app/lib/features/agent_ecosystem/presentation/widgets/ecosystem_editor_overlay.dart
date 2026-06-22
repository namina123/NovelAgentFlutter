import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../application/services/ecosystem_entry_editor_service.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../contracts/ecosystem_editor_action_handler.dart';
import '../models/ecosystem_editor_view_data.dart';

class EcosystemEditorOverlay extends StatefulWidget {
  const EcosystemEditorOverlay({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final EcosystemEditorViewData viewData;
  final EcosystemEditorActionHandler actionHandler;

  @override
  State<EcosystemEditorOverlay> createState() => _EcosystemEditorOverlayState();
}

class _EcosystemEditorOverlayState extends State<EcosystemEditorOverlay> {
  final EcosystemEntryEditorService _reviewService =
      EcosystemEntryEditorService();
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _roleController;
  late final TextEditingController _objectiveController;
  late final TextEditingController _bodyController;
  late final TextEditingController _skillsController;
  late final TextEditingController _skillGroupsController;
  late final TextEditingController _agentsController;
  late final TextEditingController _activationHintsController;
  late final TextEditingController _inputsController;
  late final TextEditingController _outputsController;
  late final TextEditingController _canDoController;
  late final TextEditingController _mustNotDoController;
  late final TextEditingController _knowledgeSourcesController;
  late final TextEditingController _requiredCapabilitiesController;
  late final TextEditingController _optionalCapabilitiesController;
  late final TextEditingController _preferredOutputController;
  late final TextEditingController _primaryAgentIdController;
  late final TextEditingController _requiredAgentIdsController;
  late final TextEditingController _optionalAgentIdsController;
  late String _orchestration;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _roleController = TextEditingController();
    _objectiveController = TextEditingController();
    _bodyController = TextEditingController();
    _skillsController = TextEditingController();
    _skillGroupsController = TextEditingController();
    _agentsController = TextEditingController();
    _activationHintsController = TextEditingController();
    _inputsController = TextEditingController();
    _outputsController = TextEditingController();
    _canDoController = TextEditingController();
    _mustNotDoController = TextEditingController();
    _knowledgeSourcesController = TextEditingController();
    _requiredCapabilitiesController = TextEditingController();
    _optionalCapabilitiesController = TextEditingController();
    _preferredOutputController = TextEditingController();
    _primaryAgentIdController = TextEditingController();
    _requiredAgentIdsController = TextEditingController();
    _optionalAgentIdsController = TextEditingController();
    _apply(widget.viewData);
  }

  @override
  void didUpdateWidget(covariant EcosystemEditorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData.entryId != widget.viewData.entryId ||
        oldWidget.viewData.kind != widget.viewData.kind ||
        oldWidget.viewData.projectRelativePath !=
            widget.viewData.projectRelativePath) {
      _apply(widget.viewData);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _roleController.dispose();
    _objectiveController.dispose();
    _bodyController.dispose();
    _skillsController.dispose();
    _skillGroupsController.dispose();
    _agentsController.dispose();
    _activationHintsController.dispose();
    _inputsController.dispose();
    _outputsController.dispose();
    _canDoController.dispose();
    _mustNotDoController.dispose();
    _knowledgeSourcesController.dispose();
    _requiredCapabilitiesController.dispose();
    _optionalCapabilitiesController.dispose();
    _preferredOutputController.dispose();
    _primaryAgentIdController.dispose();
    _requiredAgentIdsController.dispose();
    _optionalAgentIdsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveReview = _reviewService.reviewRequest(_request());
    final mergedIssues = <String>[
      ...widget.viewData.validationIssues,
      ...liveReview.validationIssues.where(
        (issue) => !widget.viewData.validationIssues.contains(issue),
      ),
    ];
    final permissionSummary =
        liveReview.permissionBoundarySummary.trim().isNotEmpty
        ? liveReview.permissionBoundarySummary
        : widget.viewData.permissionBoundarySummary;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 820),
            child: PanelSurface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SectionHeading(
                          title: widget.viewData.title,
                          subtitle:
                              widget.viewData.projectRelativePath.trim().isEmpty
                              ? '保存后会写入项目草案，仍需确认安装'
                              : widget.viewData.projectRelativePath,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            widget.actionHandler.onEcosystemEditorDismissed,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  if (widget.viewData.statusMessage.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.viewData.statusMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.mutedText,
                      ),
                    ),
                  ],
                  if (widget.viewData.sourceSummary.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _infoBlock(
                      icon: Icons.inventory_2_outlined,
                      title: '来源说明',
                      body: widget.viewData.sourceSummary,
                    ),
                  ],
                  if (permissionSummary.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _infoBlock(
                      icon: Icons.shield_outlined,
                      title: '权限边界',
                      body: permissionSummary,
                    ),
                  ],
                  if (mergedIssues.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _issueBlock(mergedIssues),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final form = SingleChildScrollView(
                          child: Column(
                            children: [
                              _textField(_idController, 'ID'),
                              const SizedBox(height: 8),
                              _textField(_nameController, '名称'),
                              const SizedBox(height: 8),
                              _textField(_descriptionController, '说明'),
                              const SizedBox(height: 8),
                              if (_isAgent) ...[
                                _textField(_roleController, '角色'),
                                const SizedBox(height: 8),
                                _textField(_objectiveController, '目标'),
                                const SizedBox(height: 8),
                                _multiField(_canDoController, '能做什么'),
                                const SizedBox(height: 8),
                                _multiField(_mustNotDoController, '绝不做什么'),
                                const SizedBox(height: 8),
                                _multiField(
                                  _knowledgeSourcesController,
                                  '知识与记忆路径',
                                ),
                                const SizedBox(height: 8),
                                _multiField(_skillsController, '技能'),
                                const SizedBox(height: 8),
                                _multiField(_skillGroupsController, '技能组'),
                                const SizedBox(height: 8),
                                _multiField(
                                  _requiredCapabilitiesController,
                                  '必需能力',
                                ),
                                const SizedBox(height: 8),
                                _multiField(
                                  _optionalCapabilitiesController,
                                  '可选能力',
                                ),
                                const SizedBox(height: 8),
                                _textField(
                                  _preferredOutputController,
                                  '偏好输出',
                                ),
                              ],
                              if (_isSkill) ...[
                                _multiField(
                                  _activationHintsController,
                                  '触发时机',
                                ),
                                const SizedBox(height: 8),
                                _multiField(_inputsController, '输入'),
                                const SizedBox(height: 8),
                                _multiField(_outputsController, '输出'),
                                const SizedBox(height: 8),
                                _multiField(
                                  _requiredCapabilitiesController,
                                  '必需能力',
                                ),
                                const SizedBox(height: 8),
                                _multiField(
                                  _optionalCapabilitiesController,
                                  '可选能力',
                                ),
                                const SizedBox(height: 8),
                                _textField(
                                  _preferredOutputController,
                                  '偏好输出',
                                ),
                              ],
                              if (_isSkillGroup) ...[
                                _multiField(_skillsController, '技能列表'),
                              ],
                              if (_isAgentGroup) ...[
                                _multiField(_agentsController, '智能体列表'),
                                const SizedBox(height: 8),
                                _textField(
                                  _primaryAgentIdController,
                                  '主智能体 ID',
                                ),
                                const SizedBox(height: 8),
                                _multiField(
                                  _requiredAgentIdsController,
                                  '必需成员',
                                ),
                                const SizedBox(height: 8),
                                _multiField(
                                  _optionalAgentIdsController,
                                  '可选成员',
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  key: ValueKey<String>(
                                    'orchestration-$_orchestration',
                                  ),
                                  initialValue: _orchestration,
                                  decoration: const InputDecoration(
                                    labelText: '编排方式',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'supervised',
                                      child: Text('监督式'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'parallel',
                                      child: Text('并行'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'round_robin',
                                      child: Text('轮转'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _orchestration = value ?? 'supervised';
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  value: _enabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _enabled = value;
                                    });
                                  },
                                  title: const Text('默认启用'),
                                ),
                              ],
                            ],
                          ),
                        );
                        final markdown = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeading(
                              title: '正文 / 操作手册',
                              subtitle:
                                  'Markdown 内容会原样写入 AGENT.md 或 SKILL.md',
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: TextField(
                                controller: _bodyController,
                                minLines: null,
                                maxLines: null,
                                expands: true,
                                decoration: const InputDecoration(
                                  alignLabelWithHint: true,
                                  labelText: 'Markdown 正文',
                                ),
                              ),
                            ),
                          ],
                        );
                        if (constraints.maxWidth < 760) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 240, child: form),
                              const SizedBox(height: 16),
                              Expanded(child: markdown),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: form),
                            const SizedBox(width: 16),
                            Expanded(flex: 6, child: markdown),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionButton(
                        label: widget.viewData.saveActionLabel,
                        icon: Icons.save_outlined,
                        onPressed: () {
                          widget.actionHandler.onEcosystemEditorSubmitted(
                            _request(),
                          );
                        },
                      ),
                      if (widget.viewData.isProjectEntry)
                        ActionButton(
                          label: widget.viewData.deleteActionLabel,
                          icon: Icons.delete_outline,
                          tone: ActionButtonTone.danger,
                          onPressed: () {
                            widget.actionHandler
                                .onEcosystemEditorDeleteRequested(_request());
                          },
                        ),
                      ActionButton(
                        label: '关闭',
                        icon: Icons.close_rounded,
                        tone: ActionButtonTone.neutral,
                        onPressed:
                            widget.actionHandler.onEcosystemEditorDismissed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isAgent => widget.viewData.kind == 'agents';
  bool get _isSkill => widget.viewData.kind == 'skills';
  bool get _isSkillGroup => widget.viewData.kind == 'skill-groups';
  bool get _isAgentGroup => widget.viewData.kind == 'agent-groups';

  Widget _textField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _multiField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        labelText: '$label（每行一项）',
      ),
    );
  }

  Widget _infoBlock({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.panel.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppPalette.mutedText),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppPalette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _issueBlock(List<String> issues) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.panel.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.warmStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '配置提示',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppPalette.text,
              ),
            ),
            const SizedBox(height: 8),
            for (final issue in issues) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppPalette.warmStrong,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppPalette.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
              if (issue != issues.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  void _apply(EcosystemEditorViewData viewData) {
    _idController.text = viewData.entryId;
    _nameController.text = viewData.name;
    _descriptionController.text = viewData.description;
    _roleController.text = viewData.role;
    _objectiveController.text = viewData.objective;
    _bodyController.text = viewData.bodyMarkdown;
    _skillsController.text = viewData.skillsText;
    _skillGroupsController.text = viewData.skillGroupsText;
    _agentsController.text = viewData.agentsText;
    _activationHintsController.text = viewData.activationHintsText;
    _inputsController.text = viewData.inputsText;
    _outputsController.text = viewData.outputsText;
    _canDoController.text = viewData.canDoText;
    _mustNotDoController.text = viewData.mustNotDoText;
    _knowledgeSourcesController.text = viewData.knowledgeSourcesText;
    _requiredCapabilitiesController.text = viewData.requiredCapabilitiesText;
    _optionalCapabilitiesController.text = viewData.optionalCapabilitiesText;
    _preferredOutputController.text = viewData.preferredOutput;
    _primaryAgentIdController.text = viewData.primaryAgentIdText;
    _requiredAgentIdsController.text = viewData.requiredAgentIdsText;
    _optionalAgentIdsController.text = viewData.optionalAgentIdsText;
    _orchestration = viewData.orchestration.isEmpty
        ? 'supervised'
        : viewData.orchestration;
    _enabled = viewData.enabled;
  }

  EcosystemEditorRequestViewData _request() {
    return EcosystemEditorRequestViewData(
      kind: widget.viewData.kind,
      originalEntryId: widget.viewData.entryId,
      originalRelativePath: widget.viewData.projectRelativePath,
      entryId: _idController.text,
      name: _nameController.text,
      description: _descriptionController.text,
      role: _roleController.text,
      objective: _objectiveController.text,
      bodyMarkdown: _bodyController.text,
      skillsText: _skillsController.text,
      skillGroupsText: _skillGroupsController.text,
      agentsText: _agentsController.text,
      activationHintsText: _activationHintsController.text,
      inputsText: _inputsController.text,
      outputsText: _outputsController.text,
      canDoText: _canDoController.text,
      mustNotDoText: _mustNotDoController.text,
      knowledgeSourcesText: _knowledgeSourcesController.text,
      requiredCapabilitiesText: _requiredCapabilitiesController.text,
      optionalCapabilitiesText: _optionalCapabilitiesController.text,
      preferredOutput: _preferredOutputController.text,
      orchestration: _orchestration,
      enabled: _enabled,
      primaryAgentIdText: _primaryAgentIdController.text,
      requiredAgentIdsText: _requiredAgentIdsController.text,
      optionalAgentIdsText: _optionalAgentIdsController.text,
    );
  }
}
