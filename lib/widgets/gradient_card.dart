import 'package:flutter/material.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ??
              [
                Color.fromRGBO(
                    Theme.of(context).primaryColor.r.round(),
                    Theme.of(context).primaryColor.g.round(),
                    Theme.of(context).primaryColor.b.round(),
                    0.7),
                Theme.of(context).primaryColor,
              ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
