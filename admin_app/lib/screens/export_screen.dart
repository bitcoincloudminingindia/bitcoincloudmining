import 'package:flutter/material.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Export Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: () {}, child: Text('Export Users')),
            SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: Text('Export Wallets')),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: Text('Export Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}
