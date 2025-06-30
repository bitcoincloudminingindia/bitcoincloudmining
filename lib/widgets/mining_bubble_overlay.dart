import 'package:flutter/material.dart';

class MiningBubbleOverlay extends StatelessWidget {
  const MiningBubbleOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Bubble tap par app open karne ka logic (native side se handle ho sakta hai)
      },
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.amber,
        child: Image.asset('assets/images/app_logo.png', width: 48, height: 48),
      ),
    );
  }
}
