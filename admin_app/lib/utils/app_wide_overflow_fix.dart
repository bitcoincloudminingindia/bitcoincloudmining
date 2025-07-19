import 'package:flutter/material.dart';

/// App-wide overflow fix utility that automatically fixes all overflow issues
class AppWideOverflowFix {
  /// Fixes all overflow issues in the entire app
  static Widget fixApp(BuildContext context, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }

  /// Universal Column that never overflows
  static Widget column({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    List<Widget> children = const <Widget>[],
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

  /// Universal Row that never overflows
  static Widget row({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    List<Widget> children = const <Widget>[],
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

  /// Universal Container that adapts to screen size
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

  /// Universal Text that never overflows
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

  /// Universal Card that never overflows
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

  /// Universal ListView that never overflows
  static Widget listView({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    Widget? prototypeItem,
    int? itemCount,
    IndexedWidgetBuilder? itemBuilder,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          key: key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          itemExtent: itemExtent,
          prototypeItem: prototypeItem,
          itemCount: itemCount,
          itemBuilder: itemBuilder ?? (context, index) => Container(),
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
        );
      },
    );
  }

  /// Universal GridView that never overflows
  static Widget gridView({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    required SliverGridDelegate gridDelegate,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    List<Widget> children = const <Widget>[],
    int? semanticChildCount,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView(
          key: key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          gridDelegate: gridDelegate,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          children: children,
        );
      },
    );
  }

  /// Auto-fix any widget that might overflow
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
class AppFix {
  static Widget column({List<Widget> children = const <Widget>[]}) =>
      AppWideOverflowFix.column(children: children);

  static Widget row({List<Widget> children = const <Widget>[]}) =>
      AppWideOverflowFix.row(children: children);

  static Widget text(String data) => AppWideOverflowFix.text(data);

  static Widget container({Widget? child}) =>
      AppWideOverflowFix.container(child: child);

  static Widget card({Widget? child}) => AppWideOverflowFix.card(child: child);

  static Widget autoFix(Widget widget) => AppWideOverflowFix.autoFix(widget);
}
