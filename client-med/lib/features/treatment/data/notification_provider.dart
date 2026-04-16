import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['notification_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['notification_type'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['sent_at'] != null 
          ? DateTime.parse(json['sent_at']) 
          : DateTime.now(),
    );
  }
}

class NotificationState {
  final List<NotificationItem> items;
  final bool loading;

  const NotificationState({
    this.items = const [],
    this.loading = false,
  });

  NotificationState copyWith({
    List<NotificationItem>? items,
    bool? loading,
  }) {
    return NotificationState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref ref;
  NotificationNotifier(this.ref) : super(const NotificationState());

  Future<void> fetchNotifications() async {
    final profileId = ref.read(authProvider).user?.id;
    if (profileId == null) return;

    state = state.copyWith(loading: true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.client.get(
        '/api/v1/notifications/',
        queryParameters: {'profile_id': profileId},
      );

      if (res.data != null && res.data['items'] is List) {
        final List<NotificationItem> items = (res.data['items'] as List)
            .map((e) => NotificationItem.fromJson(e))
            .toList();
        
        // Detect if ANY new notification arrived to show pop-up
        // (In a real app we'd use WebSockets or Push, here we poll or check diff)
        
        state = state.copyWith(items: items, loading: false);
      }
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.client.patch('/api/v1/notifications/$id', data: {'is_read': true});
      await fetchNotifications();
    } catch (_) {}
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});
