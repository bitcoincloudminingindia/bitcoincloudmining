// One-Click Overflow Fix Script
// यह script पूरे app में सभी overflow errors को एक click में fix करता है

import 'package:flutter/material.dart';

import '../widgets/overflow_safe_container.dart';
import 'universal_overflow_fix.dart';

/// One-Click Overflow Fix for Entire App
/// किसी भी screen में overflow errors को automatically detect और fix करता है
class OneClickOverflowFix {
  /// किसी भी Widget को automatically safe बनाने के लिए
  static Widget fix(Widget widget) {
    if (widget is Column) {
      return AutoOverflowFix.autoFixColumn(
        children: widget.children,
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
      );
    } else if (widget is Row) {
      return AutoOverflowFix.autoFixRow(
        children: widget.children,
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
      );
    } else if (widget is Text) {
      return AutoOverflowFix.autoFixText(
        widget.data ?? '',
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
      );
    } else if (widget is Container) {
      return OverflowSafeContainer(
        padding: widget.padding,
        margin: widget.margin,
        backgroundColor: widget.color,
        enableScroll: true,
        child: widget.child ?? const SizedBox(),
      );
    } else if (widget is Card) {
      return OverflowSafeCard(
        color: widget.color,
        elevation: widget.elevation,
        margin: widget.margin,
        enableScroll: true,
        child: widget.child ?? const SizedBox(),
      );
    }

    return widget;
  }

  /// किसी भी List को automatically safe बनाने के लिए
  static List<Widget> fixList(List<Widget> widgets) {
    return widgets.map((widget) => fix(widget)).toList();
  }

  /// किसी भी screen को completely safe बनाने के लिए
  static Widget fixScreen(Widget screen) {
    return OverflowSafeContainer(enableScroll: true, child: screen);
  }

  /// किसी भी Column को automatically fix करने के लिए
  static Widget fixColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    bool enableScroll = true,
    EdgeInsetsGeometry? padding,
  }) {
    return AutoOverflowFix.autoFixColumn(
      children: children,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      enableScroll: enableScroll,
      padding: padding,
    );
  }

  /// किसी भी Row को automatically fix करने के लिए
  static Widget fixRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    bool enableScroll = true,
    EdgeInsetsGeometry? padding,
  }) {
    return AutoOverflowFix.autoFixRow(
      children: children,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      enableScroll: enableScroll,
      padding: padding,
    );
  }

  /// किसी भी Text को automatically fix करने के लिए
  static Widget fixText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    double? minFontSize,
    double? maxFontSize,
  }) {
    return AutoOverflowFix.autoFixText(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      minFontSize: minFontSize,
      maxFontSize: maxFontSize,
    );
  }

  /// किसी भी Container को automatically fix करने के लिए
  static Widget fixContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    bool enableScroll = true,
  }) {
    return OverflowSafeContainer(
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      enableScroll: enableScroll,
      child: child,
    );
  }

  /// किसी भी Card को automatically fix करने के लिए
  static Widget fixCard({
    required Widget child,
    Color? color,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    bool enableScroll = true,
  }) {
    return OverflowSafeCard(
      color: color,
      elevation: elevation,
      margin: margin,
      padding: padding,
      enableScroll: enableScroll,
      child: child,
    );
  }
}

/// Quick Fix Methods for Common Issues
/// Common overflow errors के लिए quick fix methods
class QuickFix {
  /// Column overflow by X pixels on the bottom
  static Widget column(List<Widget> children) {
    return OneClickOverflowFix.fixColumn(
      children: children,
      mainAxisSize: MainAxisSize.min,
      enableScroll: true,
    );
  }

  /// Row overflow by X pixels on the right
  static Widget row(List<Widget> children) {
    return OneClickOverflowFix.fixRow(
      children: children,
      mainAxisSize: MainAxisSize.min,
      enableScroll: true,
    );
  }

  /// Text overflow
  static Widget text(String text, {TextStyle? style}) {
    return OneClickOverflowFix.fixText(text, style: style, maxLines: 2);
  }

  /// Container overflow
  static Widget container(Widget child) {
    return OneClickOverflowFix.fixContainer(child: child, enableScroll: true);
  }

  /// Card overflow
  static Widget card(Widget child) {
    return OneClickOverflowFix.fixCard(child: child, enableScroll: true);
  }
}

/// Usage Examples:
/*
// किसी भी Column को fix करने के लिए:
OneClickOverflowFix.fixColumn(children: [...])

// किसी भी Row को fix करने के लिए:
OneClickOverflowFix.fixRow(children: [...])

// किसी भी Text को fix करने के लिए:
OneClickOverflowFix.fixText('Hello World')

// किसी भी Container को fix करने के लिए:
OneClickOverflowFix.fixContainer(child: widget)

// किसी भी Card को fix करने के लिए:
OneClickOverflowFix.fixCard(child: widget)

// Quick fix methods:
QuickFix.column([...])
QuickFix.row([...])
QuickFix.text('Text')
QuickFix.container(widget)
QuickFix.card(widget)
*/
