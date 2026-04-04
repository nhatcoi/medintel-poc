import 'package:flutter/material.dart';

class ReminderPlaceholder extends StatelessWidget {
  const ReminderPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc thuốc')),
      body: const Center(child: Text('reminder — lịch & local notifications')),
    );
  }
}
