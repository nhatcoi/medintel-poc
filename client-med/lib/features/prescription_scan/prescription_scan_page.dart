import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../features/treatment/data/treatment_provider.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../services/ocr_service.dart';
import 'widgets/scan_empty_state.dart';
import 'widgets/scan_result_view.dart';
import 'widgets/scan_top_bar.dart';

class PrescriptionScanPage extends ConsumerStatefulWidget {
  const PrescriptionScanPage({super.key});

  @override
  ConsumerState<PrescriptionScanPage> createState() =>
      _PrescriptionScanPageState();
}

class _PrescriptionScanPageState extends ConsumerState<PrescriptionScanPage> {
  final ImagePicker _picker = ImagePicker();
  late final OcrService _ocrService;

  Uint8List? _imageBytes;
  ScanResult? _scanResult;
  bool _isScanning = false;
  bool _isAdding = false;
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
      final l10n = AppLocalizations.of(context);
      setState(() => _error = l10n.scanPickImageError(e.toString()));
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
      _isAdding = false;
    });
  }

  Future<void> _addScannedToTreatment() async {
    final result = _scanResult;
    if (result == null || result.medications.isEmpty || _isAdding) return;

    final profileId = ref.read(authProvider).user?.id;
    if (profileId == null || profileId.isEmpty) {
      setState(() {
        _error = 'Bạn cần đăng nhập để thêm thuốc vào lịch uống.';
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _error = null;
    });

    try {
      // Server scan đã auto-persist. Chỉ fallback tạo tay nếu chưa lưu được.
      if (result.savedMedications.isEmpty) {
        final notifier = ref.read(treatmentProvider.notifier);
        for (final med in result.medications) {
          await notifier.addMedication(
            profileId: profileId,
            medicationName: med.name,
            dosage: med.dosage,
            frequency: med.frequency,
            instructions: med.instructions,
            scheduleTimes: med.times,
          );
        }
      } else {
        await ref.read(treatmentProvider.notifier).loadMedications(profileId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm ${result.savedMedications.isNotEmpty ? result.savedMedications.length : result.medications.length} thuốc vào lịch uống.',
          ),
        ),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Thêm thuốc thất bại: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
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
    final l10n = AppLocalizations.of(context);
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
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(color: VitalisColors.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.scanAnalyzing,
                  style: const TextStyle(
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
              label: Text(l10n.scanRetry),
            ),
          ),
        ],
        if (_scanResult != null) ...[
          ScanResultView(result: _scanResult!),
          const SizedBox(height: 12),
          if (_scanResult!.medications.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isAdding ? null : _addScannedToTreatment,
                icon: _isAdding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_task_rounded, size: 18),
                label: Text(_isAdding ? 'Đang thêm...' : 'Thêm vào lịch uống'),
                style: FilledButton.styleFrom(
                  backgroundColor: VitalisColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(l10n.scanRetake),
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
                label: Text(l10n.scanPickImage),
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
