import 'package:flutter/material.dart';

class PrescriptionScanPlaceholder extends StatelessWidget {
  const PrescriptionScanPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét đơn thuốc')),
      body: const Center(child: Text('prescription_scan — camera + OCR')),
    );
  }
}
