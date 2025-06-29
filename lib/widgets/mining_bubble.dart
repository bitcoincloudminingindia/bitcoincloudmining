import 'package:flutter/material.dart';

class MiningBubble extends StatelessWidget {
  const MiningBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Bubble par tap par app open (plugin handle karega)
      },
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.amber,
        child: Image.asset('assets/images/app_logo.png', width: 48, height: 48),
      ),
    );
  }
}
