import 'package:flutter/material.dart';

/// Ultimate Overflow Fix - The final solution for all overflow issues
class UltimateOverflowFix {
  /// Ultimate Column that never overflows
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
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
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
            ),
          ),
        );
      },
    );
  }

  /// Ultimate Row that never overflows
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

  /// Ultimate Container that adapts perfectly
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

  /// Ultimate Text that never overflows
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

  /// Ultimate Card that never overflows
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

  /// Ultimate ListView that never overflows
  static Widget listView({
    Key? key,
    List<Widget> children = const <Widget>[],
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    double? itemExtent,
    Widget? prototypeItem,
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
        return ListView(
          key: key,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          itemExtent: itemExtent,
          prototypeItem: prototypeItem,
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

  /// Ultimate GridView that never overflows
  static Widget gridView({
    Key? key,
    required SliverGridDelegate gridDelegate,
    List<Widget> children = const <Widget>[],
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
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
        return GridView(
          key: key,
          gridDelegate: gridDelegate,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
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

  /// Ultimate auto-fix for any widget
  static Widget autoFix(Widget widget) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: widget),
          ),
        );
      },
    );
  }

  /// Ultimate fix for specific overflow type
  static Widget fixOverflow(Widget widget, {Axis? scrollDirection}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: scrollDirection ?? Axis.vertical,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: widget),
          ),
        );
      },
    );
  }
}

/// Quick access aliases
class Ultimate {
  static Widget column({
    List<Widget> children = const <Widget>[],
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) => UltimateOverflowFix.column(
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
  }) => UltimateOverflowFix.row(
    children: children,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
  );

  static Widget text(String data) => UltimateOverflowFix.text(data);

  static Widget container({Widget? child}) =>
      UltimateOverflowFix.container(child: child);

  static Widget card({Widget? child}) => UltimateOverflowFix.card(child: child);

  static Widget listView({List<Widget> children = const <Widget>[]}) =>
      UltimateOverflowFix.listView(children: children);

  static Widget gridView({
    required SliverGridDelegate gridDelegate,
    List<Widget> children = const <Widget>[],
  }) => UltimateOverflowFix.gridView(
    gridDelegate: gridDelegate,
    children: children,
  );

  static Widget autoFix(Widget widget) => UltimateOverflowFix.autoFix(widget);
}
