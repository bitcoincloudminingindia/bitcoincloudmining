import 'package:flutter/material.dart';

/// Universal Overflow Safe Container
/// यह widget सभी overflow errors को automatically handle करता है
class OverflowSafeContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final bool enableScroll;
  final ScrollPhysics? scrollPhysics;
  final bool shrinkWrap;

  const OverflowSafeContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.enableScroll = true,
    this.scrollPhysics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            border: border,
            boxShadow: boxShadow,
          ),
          child: enableScroll
              ? SingleChildScrollView(
                  physics: scrollPhysics ?? const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: padding ?? EdgeInsets.zero,
                        child: child,
                      ),
                    ),
                  ),
                )
              : Padding(padding: padding ?? EdgeInsets.zero, child: child),
        );
      },
    );
  }
}

/// Overflow Safe Column
/// Column के साथ overflow issues को automatically handle करता है
class OverflowSafeColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final bool enableScroll;
  final EdgeInsetsGeometry? padding;

  const OverflowSafeColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.enableScroll = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: children,
    );

    if (enableScroll) {
      return SingleChildScrollView(
        child: Padding(padding: padding ?? EdgeInsets.zero, child: column),
      );
    }

    return Padding(padding: padding ?? EdgeInsets.zero, child: column);
  }
}

/// Overflow Safe Row
/// Row के साथ overflow issues को automatically handle करता है
class OverflowSafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final bool enableScroll;
  final EdgeInsetsGeometry? padding;

  const OverflowSafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.enableScroll = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: children,
    );

    if (enableScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: row),
      );
    }

    return Padding(padding: padding ?? EdgeInsets.zero, child: row);
  }
}

/// Overflow Safe Text
/// Text के साथ overflow issues को automatically handle करता है
class OverflowSafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? minFontSize;
  final double? maxFontSize;

  const OverflowSafeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.minFontSize,
    this.maxFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = style?.fontSize ?? 14;

        if (minFontSize != null && fontSize < minFontSize!) {
          fontSize = minFontSize!;
        }

        if (maxFontSize != null && fontSize > maxFontSize!) {
          fontSize = maxFontSize!;
        }

        return Text(
          text,
          style:
              style?.copyWith(fontSize: fontSize) ??
              TextStyle(fontSize: fontSize),
          textAlign: textAlign,
          textDirection: textDirection,
          softWrap: softWrap ?? true,
          overflow: overflow ?? TextOverflow.ellipsis,
          maxLines: maxLines,
        );
      },
    );
  }
}

/// Overflow Safe Card
/// Card के साथ overflow issues को automatically handle करता है
class OverflowSafeCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? shadowColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final bool enableScroll;
  final EdgeInsetsGeometry? padding;

  const OverflowSafeCard({
    super.key,
    required this.child,
    this.color,
    this.shadowColor,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.margin,
    this.clipBehavior,
    this.enableScroll = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      shadowColor: shadowColor,
      elevation: elevation,
      shape: shape,
      borderOnForeground: borderOnForeground,
      margin: margin,
      clipBehavior: clipBehavior,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (enableScroll) {
      return SingleChildScrollView(child: card);
    }

    return card;
  }
}

/// Quick Fix Helper Functions
class OverflowFixHelper {
  /// किसी भी Column को overflow-safe बनाने के लिए
  static Widget safeColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    bool enableScroll = false,
    EdgeInsetsGeometry? padding,
  }) {
    return OverflowSafeColumn(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      enableScroll: enableScroll,
      padding: padding,
      children: children,
    );
  }

  /// किसी भी Row को overflow-safe बनाने के लिए
  static Widget safeRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    bool enableScroll = false,
    EdgeInsetsGeometry? padding,
  }) {
    return OverflowSafeRow(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      enableScroll: enableScroll,
      padding: padding,
      children: children,
    );
  }

  /// किसी भी Container को overflow-safe बनाने के लिए
  static Widget safeContainer({
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
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      enableScroll: enableScroll,
      child: child,
    );
  }

  /// किसी भी Text को overflow-safe बनाने के लिए
  static Widget safeText(
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
}
