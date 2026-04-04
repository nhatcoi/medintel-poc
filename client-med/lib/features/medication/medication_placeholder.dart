import 'package:flutter/material.dart';

class MedicationPlaceholder extends StatelessWidget {
  const MedicationPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication')),
      body: const Center(child: Text('medication — danh sách thuốc')),
    );
  }
}
