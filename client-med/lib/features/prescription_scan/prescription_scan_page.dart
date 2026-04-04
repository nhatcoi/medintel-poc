import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../services/api_service.dart';
import '../../services/ocr_service.dart';
import 'widgets/scan_empty_state.dart';
import 'widgets/scan_result_view.dart';
import 'widgets/scan_top_bar.dart';

class PrescriptionScanPage extends StatefulWidget {
  const PrescriptionScanPage({super.key});

  @override
  State<PrescriptionScanPage> createState() => _PrescriptionScanPageState();
}

class _PrescriptionScanPageState extends State<PrescriptionScanPage> {
  final ImagePicker _picker = ImagePicker();
  late final OcrService _ocrService;

  Uint8List? _imageBytes;
  ScanResult? _scanResult;
  bool _isScanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService(ApiService());
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _scanResult = null;
        _error = null;
      });

      await _performScan(bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không thể chọn ảnh: $e');
    }
  }

  Future<void> _performScan(Uint8List bytes) async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final result = await _ocrService.scanPrescription(bytes);
      if (!mounted) return;
      setState(() {
        _scanResult = result;
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _scanErrorMessage(e);
        _isScanning = false;
      });
    }
  }

  /// Ưu tiên `detail` từ FastAPI (502/503) thay vì chỉ [DioException.message].
  String _scanErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String) return detail;
      }
      return e.message?.isNotEmpty == true ? e.message! : e.toString();
    }
    return e.toString();
  }

  void _reset() {
    setState(() {
      _imageBytes = null;
      _scanResult = null;
      _error = null;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VitalisColors.background,
      child: Column(
        children: [
          ScanTopBar(
            hasImage: _imageBytes != null,
            onReset: _reset,
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_imageBytes == null) {
      return ScanEmptyState(
        onCamera: () => _pickImage(ImageSource.camera),
        onGallery: () => _pickImage(ImageSource.gallery),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            _imageBytes!,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        if (_isScanning) ...[
          const SizedBox(height: 32),
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: VitalisColors.primary),
                SizedBox(height: 16),
                Text(
                  'AI đang phân tích đơn thuốc...',
                  style: TextStyle(
                    color: VitalisColors.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => _performScan(_imageBytes!),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ),
        ],
        if (_scanResult != null) ScanResultView(result: _scanResult!),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Chụp lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VitalisColors.primary,
                  side: const BorderSide(color: VitalisColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Chọn ảnh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VitalisColors.primary,
                  side: const BorderSide(color: VitalisColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
