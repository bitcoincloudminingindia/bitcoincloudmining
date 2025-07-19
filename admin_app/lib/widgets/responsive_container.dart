import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  final bool enableScroll;
  final bool enableOverflowProtection;
  final double minHeight;
  final double maxHeight;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.decoration,
    this.enableScroll = true,
    this.enableOverflowProtection = true,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Determine if we need scroll
        final needsScroll = enableScroll && availableHeight < minHeight;

        // Create the main container
        Widget container = Container(
          width: width ?? availableWidth,
          height:
              height ??
              (needsScroll
                  ? null
                  : availableHeight.clamp(minHeight, maxHeight)),
          padding: padding ?? const EdgeInsets.all(16),
          margin: margin,
          decoration: decoration,
          child: child,
        );

        // Add overflow protection
        if (enableOverflowProtection) {
          container = OverflowBox(
            maxWidth: availableWidth,
            maxHeight: availableHeight,
            child: container,
          );
        }

        // Wrap in scrollable if needed
        if (needsScroll) {
          container = SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight,
                maxHeight: maxHeight,
              ),
              child: container,
            ),
          );
        }

        return container;
      },
    );
  }
}

// Specialized containers for different use cases
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool enableShadow;
  final bool enableScroll;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.enableShadow = true,
    this.enableScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        boxShadow: enableShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      enableScroll: enableScroll,
      child: child,
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final bool enableScroll;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.padding,
    this.enableScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-adjust cross axis count based on screen width
        int adaptiveCrossAxisCount = crossAxisCount;
        if (constraints.maxWidth < 600) {
          adaptiveCrossAxisCount = 1; // Mobile: 1 column
        } else if (constraints.maxWidth < 900) {
          adaptiveCrossAxisCount = 2; // Tablet: 2 columns
        } else if (constraints.maxWidth < 1200) {
          adaptiveCrossAxisCount = 3; // Desktop: 3 columns
        } else {
          adaptiveCrossAxisCount = 4; // Large desktop: 4 columns
        }

        return ResponsiveContainer(
          padding: padding,
          enableScroll: enableScroll,
          child: GridView.builder(
            shrinkWrap: true,
            physics: enableScroll
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: adaptiveCrossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }
}

class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final bool enableScroll;
  final ScrollPhysics? physics;

  const ResponsiveList({
    super.key,
    required this.children,
    this.padding,
    this.spacing = 16,
    this.enableScroll = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      padding: padding,
      enableScroll: enableScroll,
      child: ListView.separated(
        shrinkWrap: true,
        physics: enableScroll
            ? (physics ?? const BouncingScrollPhysics())
            : const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (context, index) => SizedBox(height: spacing),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

// Utility widget for text that auto-adjusts
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? minFontSize;
  final double? maxFontSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.minFontSize,
    this.maxFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-adjust font size based on available width
        double fontSize = style?.fontSize ?? 14;
        if (constraints.maxWidth < 400) {
          fontSize = (fontSize * 0.8).clamp(
            minFontSize ?? 10,
            maxFontSize ?? 20,
          );
        } else if (constraints.maxWidth < 600) {
          fontSize = (fontSize * 0.9).clamp(
            minFontSize ?? 10,
            maxFontSize ?? 20,
          );
        } else if (constraints.maxWidth > 1200) {
          fontSize = (fontSize * 1.2).clamp(
            minFontSize ?? 10,
            maxFontSize ?? 20,
          );
        }

        return Text(
          text,
          style:
              style?.copyWith(fontSize: fontSize) ??
              GoogleFonts.poppins(fontSize: fontSize),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

// Auto-sizing button widget
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool isLoading;
  final Widget? icon;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-adjust button size based on screen
        double buttonWidth = width ?? constraints.maxWidth;
        double buttonHeight = height ?? 48;
        double fontSize = 16;

        if (constraints.maxWidth < 400) {
          buttonWidth = constraints.maxWidth * 0.9;
          buttonHeight = 44;
          fontSize = 14;
        } else if (constraints.maxWidth < 600) {
          buttonWidth = constraints.maxWidth * 0.8;
          buttonHeight = 46;
          fontSize = 15;
        }

        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? const Color(0xFF3B82F6),
              foregroundColor: textColor ?? Colors.white,
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius ?? 12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[icon!, const SizedBox(width: 8)],
                      Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
