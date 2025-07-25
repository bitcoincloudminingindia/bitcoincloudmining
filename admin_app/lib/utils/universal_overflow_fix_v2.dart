import 'package:flutter/material.dart';

/// Universal Overflow Fix V2 - Complete solution for all overflow issues
class UniversalOverflowFixV2 {
  /// Universal Column with all parameters
  static Widget column({
    Key? key,
    List<Widget> children = const <Widget>[],
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            key: key,
            mainAxisAlignment: mainAxisAlignment,
            mainAxisSize: mainAxisSize,
            crossAxisAlignment: crossAxisAlignment,
            textDirection: textDirection,
            verticalDirection: verticalDirection,
            textBaseline: textBaseline,
            children: children,
          ),
        );
      },
    );
  }

  /// Universal Row with all parameters
  static Widget row({
    Key? key,
    List<Widget> children = const <Widget>[],
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: key,
            mainAxisAlignment: mainAxisAlignment,
            mainAxisSize: mainAxisSize,
            crossAxisAlignment: crossAxisAlignment,
            textDirection: textDirection,
            verticalDirection: verticalDirection,
            textBaseline: textBaseline,
            children: children,
          ),
        );
      },
    );
  }

  /// Universal Container with all parameters
  static Widget container({
    Key? key,
    Widget? child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    Decoration? decoration,
    BoxConstraints? constraints,
    AlignmentGeometry? alignment,
    Clip clipBehavior = Clip.none,
  }) {
    return LayoutBuilder(
      builder: (context, screenConstraints) {
        return Container(
          key: key,
          width: width ?? screenConstraints.maxWidth,
          height: height,
          padding: padding,
          margin: margin,
          color: color,
          decoration: decoration,
          constraints:
              constraints ??
              BoxConstraints(
                maxWidth: screenConstraints.maxWidth,
                maxHeight: screenConstraints.maxHeight,
              ),
          alignment: alignment,
          clipBehavior: clipBehavior,
          child: child,
        );
      },
    );
  }

  /// Universal Text with all parameters
  static Widget text(
    String data, {
    Key? key,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Flexible(
          child: Text(
            data,
            key: key,
            style: style,
            strutStyle: strutStyle,
            textAlign: textAlign,
            textDirection: textDirection,
            locale: locale,
            softWrap: softWrap ?? true,
            overflow: overflow ?? TextOverflow.ellipsis,
            textScaleFactor: textScaleFactor,
            maxLines: maxLines,
            semanticsLabel: semanticsLabel,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
            selectionColor: selectionColor,
          ),
        );
      },
    );
  }

  /// Universal Card with all parameters
  static Widget card({
    Key? key,
    Color? color,
    Color? shadowColor,
    double? elevation,
    ShapeBorder? shape,
    bool borderOnForeground = true,
    EdgeInsetsGeometry? margin,
    Clip? clipBehavior,
    Widget? child,
    bool semanticContainer = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          key: key,
          color: color,
          shadowColor: shadowColor,
          elevation: elevation,
          shape: shape,
          borderOnForeground: borderOnForeground,
          margin: margin,
          clipBehavior: clipBehavior,
          semanticContainer: semanticContainer,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Auto-fix any widget
  static Widget autoFix(Widget widget) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: widget,
          ),
        );
      },
    );
  }

  /// Fix specific overflow type
  static Widget fixOverflow(Widget widget, {Axis? scrollDirection}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: scrollDirection ?? Axis.vertical,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: widget,
          ),
        );
      },
    );
  }
}

/// Quick access aliases
class FixV2 {
  static Widget column({
    List<Widget> children = const <Widget>[],
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) => UniversalOverflowFixV2.column(
    children: children,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
  );

  static Widget row({
    List<Widget> children = const <Widget>[],
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) => UniversalOverflowFixV2.row(
    children: children,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
  );

  static Widget text(String data) => UniversalOverflowFixV2.text(data);

  static Widget container({Widget? child}) =>
      UniversalOverflowFixV2.container(child: child);

  static Widget card({Widget? child}) =>
      UniversalOverflowFixV2.card(child: child);

  static Widget autoFix(Widget widget) =>
      UniversalOverflowFixV2.autoFix(widget);
}
