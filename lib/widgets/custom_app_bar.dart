import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool centerTitle;
  final double? titleSpacing;
  final double? leadingWidth;
  final TextStyle? titleTextStyle;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final double? leadingPadding;
  final bool showBorder;
  final Color? borderColor;
  final VoidCallback? onTitleTap;
  final bool isScrollable;
  final ScrollController? scrollController;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.systemOverlayStyle,
    this.centerTitle = true,
    this.titleSpacing,
    this.leadingWidth,
    this.titleTextStyle,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
    this.leadingPadding,
    this.showBorder = false,
    this.borderColor,
    this.onTitleTap,
    this.isScrollable = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ??
        theme.appBarTheme.backgroundColor ??
        theme.primaryColor;
    final effectiveForegroundColor = foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        theme.colorScheme.onPrimary;

    final Widget appBar = AppBar(
      title: GestureDetector(
        onTap: onTitleTap,
        child: Text(
          title,
          style: titleTextStyle ??
              theme.textTheme.titleLarge?.copyWith(
                color: effectiveForegroundColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      leading: leading ??
          (automaticallyImplyLeading
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: effectiveForegroundColor),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null),
      actions: actions,
      backgroundColor: effectiveBackgroundColor,
      elevation: elevation ?? (showBorder ? 0 : 4),
      systemOverlayStyle: systemOverlayStyle ??
          SystemUiOverlayStyle(
            statusBarColor: effectiveBackgroundColor,
            statusBarIconBrightness: ThemeData.estimateBrightnessForColor(
                        effectiveBackgroundColor) ==
                    Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      leadingWidth: leadingWidth,
      toolbarHeight: toolbarHeight,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: bottom!.preferredSize,
              child: Container(
                decoration: showBorder
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: borderColor ?? theme.dividerColor,
                            width: 1,
                          ),
                        ),
                      )
                    : null,
                child: bottom!,
              ),
            )
          : showBorder
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: borderColor ?? theme.dividerColor,
                  ),
                )
              : null,
    );

    if (isScrollable && scrollController != null) {
      return AnimatedBuilder(
        animation: scrollController!,
        builder: (context, child) {
          final scrolled =
              scrollController!.hasClients && scrollController!.offset > 0;
          return Material(
            elevation: scrolled ? (elevation ?? 4) : 0,
            color: effectiveBackgroundColor,
            child: child,
          );
        },
        child: appBar,
      );
    }

    return appBar;
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
