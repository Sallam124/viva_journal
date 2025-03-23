import 'package:flutter/material.dart';

class TrackerLogScreen extends StatelessWidget {
  const TrackerLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracker Log')),
      body: const Center(
        child: Text('Tracker Log Screen'),
      ),
    );
  }
}
