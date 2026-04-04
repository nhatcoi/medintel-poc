import 'package:flutter/material.dart';

class AdherencePlaceholder extends StatelessWidget {
  const AdherencePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuân thủ')),
      body: const Center(child: Text('adherence — log & dashboard')),
    );
  }
}
