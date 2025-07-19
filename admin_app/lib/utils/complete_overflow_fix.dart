// Complete Overflow Fix Script
// यह script पूरे app में सभी overflow errors को automatically fix करता है

import 'package:flutter/material.dart';

import 'one_click_overflow_fix.dart';

/// Complete Overflow Fix for Entire App
/// किसी भी screen में overflow errors को automatically detect और fix करता है
class CompleteOverflowFix {
  /// किसी भी Widget को automatically safe बनाने के लिए
  static Widget fix(Widget widget) {
    return OneClickOverflowFix.fix(widget);
  }

  /// किसी भी List को automatically safe बनाने के लिए
  static List<Widget> fixList(List<Widget> widgets) {
    return OneClickOverflowFix.fixList(widgets);
  }

  /// किसी भी screen को completely safe बनाने के लिए
  static Widget fixScreen(Widget screen) {
    return OneClickOverflowFix.fixScreen(screen);
  }

  /// किसी भी Column को automatically fix करने के लिए
  static Widget column({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    bool enableScroll = true,
    EdgeInsetsGeometry? padding,
  }) {
    return OneClickOverflowFix.fixColumn(
      children: children,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      enableScroll: enableScroll,
      padding: padding,
    );
  }

  /// किसी भी Row को automatically fix करने के लिए
  static Widget row({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    bool enableScroll = true,
    EdgeInsetsGeometry? padding,
  }) {
    return OneClickOverflowFix.fixRow(
      children: children,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      enableScroll: enableScroll,
      padding: padding,
    );
  }

  /// किसी भी Text को automatically fix करने के लिए
  static Widget text(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    double? minFontSize,
    double? maxFontSize,
  }) {
    return OneClickOverflowFix.fixText(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      minFontSize: minFontSize,
      maxFontSize: maxFontSize,
    );
  }

  /// किसी भी Container को automatically fix करने के लिए
  static Widget container({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    bool enableScroll = true,
  }) {
    return OneClickOverflowFix.fixContainer(
      child: child,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      enableScroll: enableScroll,
    );
  }

  /// किसी भी Card को automatically fix करने के लिए
  static Widget card({
    required Widget child,
    Color? color,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    bool enableScroll = true,
  }) {
    return OneClickOverflowFix.fixCard(
      child: child,
      color: color,
      elevation: elevation,
      margin: margin,
      padding: padding,
      enableScroll: enableScroll,
    );
  }
}

/// Quick Fix Methods for Common Issues
/// Common overflow errors के लिए quick fix methods
class Fix {
  /// Column overflow by X pixels on the bottom
  static Widget column(List<Widget> children) {
    return CompleteOverflowFix.column(
      children: children,
      mainAxisSize: MainAxisSize.min,
      enableScroll: true,
    );
  }

  /// Row overflow by X pixels on the right
  static Widget row(List<Widget> children) {
    return CompleteOverflowFix.row(
      children: children,
      mainAxisSize: MainAxisSize.min,
      enableScroll: true,
    );
  }

  /// Text overflow
  static Widget text(String text, {TextStyle? style}) {
    return CompleteOverflowFix.text(text, style: style, maxLines: 2);
  }

  /// Container overflow
  static Widget container(Widget child) {
    return CompleteOverflowFix.container(child: child, enableScroll: true);
  }

  /// Card overflow
  static Widget card(Widget child) {
    return CompleteOverflowFix.card(child: child, enableScroll: true);
  }
}

/// Usage Examples:
/*
// किसी भी Column को fix करने के लिए:
CompleteOverflowFix.column(children: [...])

// किसी भी Row को fix करने के लिए:
CompleteOverflowFix.row(children: [...])

// किसी भी Text को fix करने के लिए:
CompleteOverflowFix.text('Hello World')

// किसी भी Container को fix करने के लिए:
CompleteOverflowFix.container(child: widget)

// किसी भी Card को fix करने के लिए:
CompleteOverflowFix.card(child: widget)

// Quick fix methods:
Fix.column([...])
Fix.row([...])
Fix.text('Text')
Fix.container(widget)
Fix.card(widget)
*/
