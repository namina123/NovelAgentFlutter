import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

class ConversationComposerTextField extends StatelessWidget {
  const ConversationComposerTextField({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.hintText,
  });

  final TextEditingController controller;
  final ScrollController scrollController;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    return SizedBox(
      height: 92,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: false,
        child: TextField(
          controller: controller,
          scrollController: scrollController,
          scrollPhysics: const ClampingScrollPhysics(),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: null,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(
            color: surface.foregroundColor,
            fontSize: 13,
            height: 1.56,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: colors.accentColor,
          decoration: InputDecoration(
            hintText: hintText,
            filled: false,
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintStyle: TextStyle(
              color: colors.mutedTextColor.withValues(alpha: 0.9),
              fontSize: 12.2,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
