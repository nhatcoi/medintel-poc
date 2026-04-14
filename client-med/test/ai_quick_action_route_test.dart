import 'package:flutter_test/flutter_test.dart';
import 'package:med_intel_client/features/ai_chat/ai_chat_page.dart';

void main() {
  group('routeFromQuickPrompt', () {
    test('maps open command prompts', () {
      expect(routeFromQuickPrompt('open: history'), '/history');
      expect(routeFromQuickPrompt('/open memory now'), '/memory');
      expect(routeFromQuickPrompt('open: medical records'), '/medical-records');
    });

    test('maps Vietnamese intent prompts', () {
      expect(routeFromQuickPrompt('xem lịch sử uống thuốc'), '/history');
      expect(routeFromQuickPrompt('mở trang quét đơn thuốc'), '/scan');
      expect(routeFromQuickPrompt('về trang chủ'), '/home');
      expect(routeFromQuickPrompt('mở chăm sóc'), '/care');
    });

    test('returns null for non-navigation prompts', () {
      expect(routeFromQuickPrompt('Tôi bị quên uống thuốc thì sao?'), null);
      expect(routeFromQuickPrompt(''), null);
    });
  });
}
