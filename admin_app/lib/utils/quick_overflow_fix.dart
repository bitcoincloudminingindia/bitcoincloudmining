// Quick Overflow Fix Script
// यह script सभी overflow errors को एक साथ fix करता है

import 'package:flutter/material.dart';
import '../widgets/overflow_safe_container.dart';

/// Universal Overflow Fix Class
/// किसी भी screen में overflow errors को fix करने के लिए
class QuickOverflowFix {
  
  /// किसी भी Column को safe बनाने के लिए
  static Widget fixColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    bool enableScroll = false,
    EdgeInsetsGeometry? padding,
  }) {
    return OverflowSafeColumn(
      children: children,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      enableScroll: enableScroll,
      padding: padding,
    );
  }

  /// किसी भी Row को safe बनाने के लिए
  static Widget fixRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    bool enableScroll = false,
    EdgeInsetsGeometry? padding,
  }) {
    return OverflowSafeRow(
      children: children,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      enableScroll: enableScroll,
      padding: padding,
    );
  }

  /// किसी भी Container को safe बनाने के लिए
  static Widget fixContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    bool enableScroll = true,
  }) {
    return OverflowSafeContainer(
      child: child,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      enableScroll: enableScroll,
    );
  }

  /// किसी भी Text को safe बनाने के लिए
  static Widget fixText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    double? minFontSize,
    double? maxFontSize,
  }) {
    return OverflowSafeText(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      minFontSize: minFontSize,
      maxFontSize: maxFontSize,
    );
  }

  /// किसी भी Card को safe बनाने के लिए
  static Widget fixCard({
    required Widget child,
    Color? color,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    bool enableScroll = false,
  }) {
    return OverflowSafeCard(
      child: child,
      color: color,
      elevation: elevation,
      margin: margin,
      padding: padding,
      enableScroll: enableScroll,
    );
  }

  /// किसी भी ListView को safe बनाने के लिए
  static Widget fixListView({
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
  }) {
    return ListView(
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }

  /// किसी भी GridView को safe बनाने के लिए
  static Widget fixGridView({
    required List<Widget> children,
    required int crossAxisCount,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 0.0,
    double mainAxisSpacing = 0.0,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
  }) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }

  /// किसी भी SingleChildScrollView को safe बनाने के लिए
  static Widget fixScrollView({
    required Widget child,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
  }) {
    return SingleChildScrollView(
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      child: child,
    );
  }

  /// किसी भी screen को completely safe बनाने के लिए
  static Widget fixScreen({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    bool enableScroll = true,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: OverflowSafeContainer(
          child: child,
          padding: padding,
          enableScroll: enableScroll,
        ),
      ),
    );
  }
}

/// Common Overflow Error Patterns and Solutions
class OverflowPatterns {
  
  /// Pattern 1: Column overflow by X pixels on the bottom
  static Widget fixColumnOverflow(List<Widget> children) {
    return QuickOverflowFix.fixColumn(
      children: children,
      mainAxisSize: MainAxisSize.min,
      enableScroll: true,
    );
  }

  /// Pattern 2: Row overflow by X pixels on the right
  static Widget fixRowOverflow(List<Widget> children) {
    return QuickOverflowFix.fixRow(
      children: children,
      mainAxisSize: MainAxisSize.min,
      enableScroll: true,
    );
  }

  /// Pattern 3: Text overflow
  static Widget fixTextOverflow(String text, {TextStyle? style}) {
    return QuickOverflowFix.fixText(
      text,
      style: style,
      maxLines: 2,
    );
  }

  /// Pattern 4: Container overflow
  static Widget fixContainerOverflow(Widget child) {
    return QuickOverflowFix.fixContainer(
      child: child,
      enableScroll: true,
    );
  }

  /// Pattern 5: Card overflow
  static Widget fixCardOverflow(Widget child) {
    return QuickOverflowFix.fixCard(
      child: child,
      enableScroll: true,
    );
  }
}

/// Usage Examples:
/*
// पुराना तरीका:
Column(
  children: [
    Text('Hello'),
    Text('World'),
  ],
)

// नया तरीका:
QuickOverflowFix.fixColumn(
  children: [
    Text('Hello'),
    Text('World'),
  ],
)

// या pattern के साथ:
OverflowPatterns.fixColumnOverflow([
  Text('Hello'),
  Text('World'),
])
*/ 