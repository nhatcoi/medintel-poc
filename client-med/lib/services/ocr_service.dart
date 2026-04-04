import 'dart:typed_data';

/// Nhận dạng đơn thuốc — nối API `/api/v1/ocr` hoặc on-device sau.
final class OcrService {
  OcrService();

  Future<String> extractFromImage(Uint8List bytes, {String filename = 'rx.jpg'}) async {
    throw UnimplementedError('Gắn ApiService.post multipart tới backend OCR.');
  }
}
