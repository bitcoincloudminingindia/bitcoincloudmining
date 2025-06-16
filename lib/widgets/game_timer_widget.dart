import 'package:flutter/material.dart';

import '../utils/color_constants.dart';

class GameTimerWidget extends StatelessWidget {
  final int remainingTime;
  final int totalTime;

  const GameTimerWidget({
    super.key,
    required this.remainingTime,
    required this.totalTime,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remainingTime / totalTime;
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 51, red: 0, green: 0, blue: 0),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: ColorConstants.primaryTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: ColorConstants.secondaryColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.5
                      ? ColorConstants.successColor
                      : progress > 0.25
                          ? Colors.orange
                          : ColorConstants.errorColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
