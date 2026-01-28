// notification/notification_handler.dart - AUTO ADD TO NOTIFICATION CENTER
import 'dart:convert';
import 'package:myquran/notification/notification_center.dart';
import 'package:shared_preferences/shared_preferences.dart';


class NotificationHandler {
  static const String _keyNotificationHistory = 'notification_history_v3';
  
  // Add notification to history when it's triggered
  static Future<void> addToHistory({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user wants to show in notification center
      final showInCenter = prefs.getBool('notif_show_in_center') ?? true;
      if (!showInCenter) {
        print('⏭️ Skip adding to center - user disabled it');
        return;
      }
      
      // Load existing history
      final historyJson = prefs.getString(_keyNotificationHistory);
      List<NotificationItem> historyItems = [];
      
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        historyItems = historyList.map((item) => NotificationItem.fromJson(item)).toList();
      }
      
      // Create new notification item
      final newNotification = NotificationItem(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        isScheduled: false,
      );
      
      // Add to beginning of list
      historyItems.insert(0, newNotification);
      
      // Keep only last 100 notifications
      if (historyItems.length > 100) {
        historyItems = historyItems.sublist(0, 100);
      }
      
      // Save updated history
      final updatedJson = jsonEncode(historyItems.map((item) => item.toJson()).toList());
      await prefs.setString(_keyNotificationHistory, updatedJson);
      
      print('✅ Notification added to history: $title');
      
    } catch (e) {
      print('❌ Error adding notification to history: $e');
    }
  }
  
  // Get notification type from prayer name
  static NotificationType getTypeFromPrayer(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return NotificationType.subuh;
      case 'dzuhur':
        return NotificationType.dzuhur;
      case 'ashar':
        return NotificationType.ashar;
      case 'maghrib':
        return NotificationType.maghrib;
      case 'isya':
        return NotificationType.isya;
      default:
        return NotificationType.prayer;
    }
  }
  
  // Handle notification when received
  static Future<void> handleNotificationReceived(String? payload) async {
    if (payload == null) return;
    
    try {
      final parts = payload.split('|');
      if (parts.length < 3) return;
      
      final category = parts[0]; // 'prayer', 'dzikir', or 'tilawah'
      final name = parts[1]; // e.g., 'Subuh', 'Pagi', etc.
      final time = parts[2]; // e.g., '04:30'
      
      String title = '';
      String body = '';
      NotificationType type = NotificationType.system;
      
      switch (category) {
        case 'prayer':
          title = '🕌 Waktu Sholat $name';
          body = 'Saatnya sholat $name ($time WIB)';
          type = getTypeFromPrayer(name);
          break;
          
        case 'dzikir':
          final emoji = name == 'Pagi' ? '🌅' : '🌆';
          title = '$emoji Waktu Dzikir $name';
          body = 'Saatnya membaca dzikir $name hari ini';
          type = NotificationType.dzikir;
          break;
          
        case 'tilawah':
          final emoji = name == 'Pagi' ? '📖' : '🌙';
          title = '$emoji Waktu Tilawah $name';
          body = 'Luangkan waktu untuk membaca Al-Qur\'an';
          type = NotificationType.quran;
          break;
      }
      
      // Add to notification center
      await addToHistory(title: title, body: body, type: type);
      
    } catch (e) {
      print('❌ Error handling notification: $e');
    }
  }
  
  // Schedule test notification and add to history
  static Future<void> addTestNotification() async {
    await addToHistory(
      title: '✅ Test Notifikasi',
      body: 'Notifikasi test berhasil dikirim dan ditampilkan',
      type: NotificationType.system,
    );
  }
}