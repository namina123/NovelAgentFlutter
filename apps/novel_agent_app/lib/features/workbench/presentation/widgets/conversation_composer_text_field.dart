import 'package:flutter/material.dart';

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
    return SizedBox(
      height: 92,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
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
          decoration: InputDecoration(
            hintText: hintText,
            filled: false,
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
