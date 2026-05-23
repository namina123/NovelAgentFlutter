import 'package:flutter/material.dart';

class AppChrome {
  static const double surfaceRadius = 0;
  static const double controlRadius = 0;
  static const double borderWidth = 1;
  static const BorderRadius surfaceBorderRadius = BorderRadius.zero;
  static const BorderRadius controlBorderRadius = BorderRadius.zero;
  static const List<BoxShadow> noShadow = <BoxShadow>[];

  const AppChrome._();

  static RoundedRectangleBorder controlShape({required Color sideColor}) {
    // 中文注释: 统一控件外形，避免不同页面各自维护圆角风格而让工作区显得松散。
    return RoundedRectangleBorder(
      borderRadius: controlBorderRadius,
      side: BorderSide(color: sideColor, width: borderWidth),
    );
  }

  static OutlineInputBorder inputBorder({required Color sideColor}) {
    // 中文注释: 输入框边框同样走一套直角规范，便于后续整体调整界面语言。
    return OutlineInputBorder(
      borderRadius: controlBorderRadius,
      borderSide: BorderSide(color: sideColor, width: borderWidth),
    );
  }
}
