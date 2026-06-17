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
    this.onSelected,
  });

  final String label;
  final List<SettingsSearchOption<T>> options;
  final TextEditingController controller;
  final T? selectedValue;
  final String hintText;
  final bool enabled;
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
      _scheduleOverlayRefresh();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
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
            onTapOutside: (_) => _hideMenu(),
            decoration: InputDecoration(
              hintText: widget.hintText,
              suffixIcon: IconButton(
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

  void _handleTextChanged() {
    if (!_menuRequested && widget.controller.text.trim().isNotEmpty) {
      _menuRequested = true;
      if (mounted) {
        setState(() {});
      }
      _focusNode.requestFocus();
      _scheduleOverlayRefresh(forceAllWhenEmpty: true);
      return;
    }
    if (_menuRequested) {
      _scheduleOverlayRefresh();
    }
  }

  void _toggleMenuFromButton() {
    _menuRequested = !_menuRequested;
    if (_menuRequested) {
      _focusNode.requestFocus();
      _scheduleOverlayRefresh(forceAllWhenEmpty: true);
    } else {
      _hideMenu();
    }
    setState(() {});
  }

  void _hideMenu() {
    _menuRequested = false;
    _removeOverlay();
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshOverlay({bool forceAllWhenEmpty = false}) {
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      _visibleOptions = forceAllWhenEmpty
          ? widget.options
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
    _overlayEntry?.remove();
    _overlayEntry = _buildOverlay();
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _scheduleOverlayRefresh({bool forceAllWhenEmpty = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _refreshOverlay(forceAllWhenEmpty: forceAllWhenEmpty);
    });
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final theme = Theme.of(context);
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideMenu,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: Material(
                elevation: 8,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: size.width,
                    maxWidth: size.width,
                    maxHeight: 220,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: _visibleOptions.length,
                    itemBuilder: (context, index) {
                      final option = _visibleOptions[index];
                      return ListTile(
                        dense: true,
                        title: Text(option.label),
                        subtitle: option.note.trim().isEmpty
                            ? null
                            : Text(option.note),
                        onTap: () => _selectOption(option),
                      );
                    },
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
