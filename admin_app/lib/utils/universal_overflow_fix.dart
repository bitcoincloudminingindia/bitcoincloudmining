// Universal Overflow Fix Script
// यह script पूरे app में सभी overflow errors को automatically fix करता है

import 'package:flutter/material.dart';

import 'quick_overflow_fix.dart';

/// Universal Overflow Fix for Entire App
/// किसी भी screen में overflow errors को automatically detect और fix करता है
class UniversalOverflowFix {
  /// किसी भी Widget को overflow-safe बनाने के लिए
  static Widget makeSafe(Widget widget) {
    if (widget is Column) {
      return QuickOverflowFix.fixColumn(
        children: widget.children,
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
      );
    } else if (widget is Row) {
      return QuickOverflowFix.fixRow(
        children: widget.children,
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
      );
    } else if (widget is Container) {
      return QuickOverflowFix.fixContainer(
        child: widget.child ?? const SizedBox(),
        padding: widget.padding,
        margin: widget.margin,
        backgroundColor: widget.color,
      );
    } else if (widget is Text) {
      return QuickOverflowFix.fixText(
        widget.data ?? '',
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
      );
    } else if (widget is Card) {
      return QuickOverflowFix.fixCard(
        child: widget.child ?? const SizedBox(),
        color: widget.color,
        elevation: widget.elevation,
        margin: widget.margin,
      );
    }

    return widget;
  }

  /// किसी भी List को overflow-safe बनाने के लिए
  static List<Widget> makeListSafe(List<Widget> widgets) {
    return widgets.map((widget) => makeSafe(widget)).toList();
  }

  /// किसी भी screen को completely safe बनाने के लिए
  static Widget makeScreenSafe(Widget screen) {
    return QuickOverflowFix.fixScreen(child: screen, enableScroll: true);
  }
}

/// Automatic Overflow Detection and Fix
/// Overflow errors को automatically detect करके fix करता है
class AutoOverflowFix {
  /// किसी भी Column को automatically fix करने के लिए
  static Widget autoFixColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    bool enableScroll = true,
    EdgeInsetsGeometry? padding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if content might overflow
        bool mightOverflow =
            children.length > 3 ||
            constraints.maxHeight < 400 ||
            constraints.maxWidth < 300;

        if (mightOverflow) {
          return QuickOverflowFix.fixColumn(
            children: children,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            enableScroll: enableScroll,
            padding: padding,
          );
        }

        return Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        );
      },
    );
  }

  /// किसी भी Row को automatically fix करने के लिए
  static Widget autoFixRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    bool enableScroll = true,
    EdgeInsetsGeometry? padding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if content might overflow
        bool mightOverflow = children.length > 4 || constraints.maxWidth < 400;

        if (mightOverflow) {
          return QuickOverflowFix.fixRow(
            children: children,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            enableScroll: enableScroll,
            padding: padding,
          );
        }

        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        );
      },
    );
  }

  /// किसी भी Text को automatically fix करने के लिए
  static Widget autoFixText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    double? minFontSize,
    double? maxFontSize,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if text might overflow
        bool mightOverflow = text.length > 50 || constraints.maxWidth < 200;

        if (mightOverflow) {
          return QuickOverflowFix.fixText(
            text,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines ?? 2,
            minFontSize: minFontSize,
            maxFontSize: maxFontSize,
          );
        }

        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// Common Overflow Error Solutions
/// सभी common overflow errors के लिए ready-made solutions
class OverflowSolutions {
  /// Solution 1: Column overflow by X pixels on the bottom
  static Widget solveColumnBottomOverflow(List<Widget> children) {
    return QuickOverflowFix.fixColumn(
      children: children,
      mainAxisSize: MainAxisSize.min,
      enableScroll: true,
    );
  }

  /// Solution 2: Row overflow by X pixels on the right
  static Widget solveRowRightOverflow(List<Widget> children) {
    return QuickOverflowFix.fixRow(
      children: children,
      mainAxisSize: MainAxisSize.min,
      enableScroll: true,
    );
  }

  /// Solution 3: Text overflow
  static Widget solveTextOverflow(String text, {TextStyle? style}) {
    return QuickOverflowFix.fixText(text, style: style, maxLines: 2);
  }

  /// Solution 4: Container overflow
  static Widget solveContainerOverflow(Widget child) {
    return QuickOverflowFix.fixContainer(child: child, enableScroll: true);
  }

  /// Solution 5: Card overflow
  static Widget solveCardOverflow(Widget child) {
    return QuickOverflowFix.fixCard(child: child, enableScroll: true);
  }

  /// Solution 6: ListView overflow
  static Widget solveListViewOverflow(List<Widget> children) {
    return QuickOverflowFix.fixListView(children: children, shrinkWrap: true);
  }

  /// Solution 7: GridView overflow
  static Widget solveGridViewOverflow(
    List<Widget> children,
    int crossAxisCount,
  ) {
    return QuickOverflowFix.fixGridView(
      children: children,
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
    );
  }
}

/// Usage Examples:
/*
// किसी भी Column को automatically fix करने के लिए:
AutoOverflowFix.autoFixColumn(children: [...])

// किसी भी Row को automatically fix करने के लिए:
AutoOverflowFix.autoFixRow(children: [...])

// किसी भी Text को automatically fix करने के लिए:
AutoOverflowFix.autoFixText('Hello World')

// Specific overflow solutions:
OverflowSolutions.solveColumnBottomOverflow([...])
OverflowSolutions.solveRowRightOverflow([...])
OverflowSolutions.solveTextOverflow('Text')
*/
