import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../models/user_option_view_data.dart';

class UserOptionTile extends StatelessWidget {
  const UserOptionTile({
    super.key,
    required this.option,
    required this.onSelected,
  });

  final UserOptionViewData option;
  final ValueChanged<UserOptionViewData> onSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 单个待选项独立成控件后，未来补充长按说明或禁用状态不会扩散到整个选项面板。
    return OutlinedButton(
      onPressed: () => onSelected(option),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(12),
        backgroundColor: AppPalette.accentSoft,
        side: const BorderSide(
          color: AppPalette.line,
          width: AppChrome.borderWidth,
        ),
        shape: AppChrome.controlShape(sideColor: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              color: AppPalette.lineStrong,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (option.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              option.description,
              style: const TextStyle(
                color: AppPalette.text,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
