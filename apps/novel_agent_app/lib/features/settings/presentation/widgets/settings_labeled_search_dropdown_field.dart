import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/settings_search_option.dart';

class SettingsLabeledSearchDropdownField<T> extends StatefulWidget {
  const SettingsLabeledSearchDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.controller,
    this.selectedValue,
    this.hintText = '',
    this.enabled = true,
    this.openOnFocus = true,
    this.onSelected,
  });

  final String label;
  final List<SettingsSearchOption<T>> options;
  final TextEditingController controller;
  final T? selectedValue;
  final String hintText;
  final bool enabled;
  /// 获得焦点或点击输入框时，是否立刻展开完整列表（空查询也展示全部）。
  final bool openOnFocus;
  final ValueChanged<T?>? onSelected;

  @override
  State<SettingsLabeledSearchDropdownField<T>> createState() =>
      _SettingsLabeledSearchDropdownFieldState<T>();
}

class _SettingsLabeledSearchDropdownFieldState<T>
    extends State<SettingsLabeledSearchDropdownField<T>> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  bool _menuRequested = false;
  List<SettingsSearchOption<T>> _visibleOptions = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
    _syncControllerWithSelection();
  }

  @override
  void didUpdateWidget(
    covariant SettingsLabeledSearchDropdownField<T> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
    if (oldWidget.selectedValue != widget.selectedValue ||
        oldWidget.options != widget.options) {
      _syncControllerWithSelection();
      if (_menuRequested) {
        _scheduleOverlayRefresh(forceAllWhenEmpty: true);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: surface.mutedForegroundColor,
          ),
        ),
        const SizedBox(height: 6),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            // 中文注释: 点输入框就展开，不要逼用户先打字或只点小箭头。
            onTap: widget.enabled ? _openMenuFromField : null,
            decoration: InputDecoration(
              hintText: widget.hintText,
              suffixIcon: IconButton(
                tooltip: _menuRequested ? '收起列表' : '展开全部选项',
                onPressed: widget.enabled ? _toggleMenuFromButton : null,
                icon: Icon(
                  _menuRequested
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                ),
              ),
            ),
          ),
        ),
        if (widget.options.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '当前没有可选条目。',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  void _syncControllerWithSelection() {
    final selected = _optionForValue(widget.selectedValue);
    if (selected == null) {
      return;
    }
    if (widget.controller.text.trim() == selected.label) {
      return;
    }
    widget.controller.value = widget.controller.value.copyWith(
      text: selected.label,
      selection: TextSelection.collapsed(offset: selected.label.length),
      composing: TextRange.empty,
    );
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      // 中文注释: 失焦时延后收起，给列表项 onTap 留出命中时间。
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted || _focusNode.hasFocus) {
          return;
        }
        _hideMenu();
      });
      return;
    }
    if (widget.openOnFocus && widget.enabled) {
      _openMenuFromField();
    }
  }

  void _handleTextChanged() {
    if (!_menuRequested && widget.controller.text.trim().isNotEmpty) {
      _openMenuFromField();
      return;
    }
    if (_menuRequested) {
      _scheduleOverlayRefresh(forceAllWhenEmpty: true);
    }
  }

  void _openMenuFromField() {
    if (!widget.enabled) {
      return;
    }
    _menuRequested = true;
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    _scheduleOverlayRefresh(forceAllWhenEmpty: true);
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleMenuFromButton() {
    if (_menuRequested) {
      _hideMenu();
      return;
    }
    _openMenuFromField();
  }

  void _hideMenu() {
    if (!_menuRequested && _overlayEntry == null) {
      return;
    }
    _menuRequested = false;
    _removeOverlay();
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshOverlay({bool forceAllWhenEmpty = false}) {
    if (!_menuRequested || !mounted) {
      _removeOverlay();
      return;
    }
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      _visibleOptions = forceAllWhenEmpty || widget.openOnFocus
          ? List<SettingsSearchOption<T>>.from(widget.options)
          : <SettingsSearchOption<T>>[];
    } else {
      _visibleOptions = widget.options
          .where((option) {
            final haystacks = <String>[
              option.label.toLowerCase(),
              option.value.toString().toLowerCase(),
              option.note.toLowerCase(),
            ];
            return haystacks.any((value) => value.contains(query));
          })
          .toList(growable: false);
    }

    if (_visibleOptions.isEmpty) {
      _removeOverlay();
      return;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _scheduleOverlayRefresh(forceAllWhenEmpty: forceAllWhenEmpty);
      return;
    }

    _overlayEntry?.remove();
    _overlayEntry = _buildOverlay(renderObject.size);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    overlay.insert(_overlayEntry!);
  }

  void _scheduleOverlayRefresh({bool forceAllWhenEmpty = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _refreshOverlay(forceAllWhenEmpty: forceAllWhenEmpty);
    });
  }

  OverlayEntry _buildOverlay(Size fieldSize) {
    final theme = Theme.of(context);
    final surface = context.novelThemeSurfaces.panel;
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 中文注释: 不在全屏透明层上抢点击，避免和列表项抢手势；仅用失焦/按钮收起。
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: Material(
                elevation: 10,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: fieldSize.width,
                    maxWidth: fieldSize.width,
                    maxHeight: 280,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: surface.borderColor.withValues(alpha: 0.8),
                      ),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: _visibleOptions.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: surface.borderColor.withValues(alpha: 0.35),
                      ),
                      itemBuilder: (context, index) {
                        final option = _visibleOptions[index];
                        return InkWell(
                          onTap: () => _selectOption(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: surface.foregroundColor,
                                  ),
                                ),
                                if (option.note.trim().isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    option.note,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      color: surface.mutedForegroundColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectOption(SettingsSearchOption<T> option) {
    widget.controller.value = widget.controller.value.copyWith(
      text: option.label,
      selection: TextSelection.collapsed(offset: option.label.length),
      composing: TextRange.empty,
    );
    widget.onSelected?.call(option.value);
    _hideMenu();
  }

  SettingsSearchOption<T>? _optionForValue(T? value) {
    if (value == null) {
      return null;
    }
    for (final option in widget.options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
