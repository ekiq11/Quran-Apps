// notification/notification_service.dart - MIGRATED TO USE NOTIFICATION MANAGER v2.0
// ✅ UPDATED: Badge management synced with NotificationManager fixes
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:myquran/notification/notification_manager.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🔄 NOTIFICATION SERVICE - WRAPPER FOR NOTIFICATION MANAGER
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 
/// This is a compatibility layer that wraps NotificationManager
/// to maintain backward compatibility with existing code.
/// 
/// ✅ v2.0 Changes:
/// - Fixed badge count management to sync with NotificationManager
/// - Badge updates when notifications are received (not when scheduled)
/// - Proper ValueNotifier usage for reactive UI updates
/// - Auto-refresh badge on app lifecycle changes
/// 
/// Features:
/// ✅ All functionality uses NotificationManager under the hood
/// ✅ Maintains the same public API for backward compatibility
/// ✅ Badge count management synced with NotificationManager
/// ✅ Easy migration path - no breaking changes
/// ✅ Callback adapter for old signature format
/// ✅ Silent mode support
/// ✅ Permission checking
/// ✅ Pending notifications info
/// 
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 BACKEND & STATE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// ✅ Use NotificationManager as backend
  final NotificationManager _manager = NotificationManager();
  
  /// ✅ Maintain compatibility with old callback signature
  /// Old: Function(String type, String data)
  /// New: Function(String type, Map<String, dynamic> data)
  static Function(String type, String data)? onNotificationTapped;
  
  /// ✅ Badge count - REACTIVE with ValueNotifier
  /// This syncs with NotificationManager's badge system
  static final ValueNotifier<int> badgeCount = ValueNotifier<int>(0);
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💾 STORAGE KEYS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  static const String _keySilentMode = 'notification_silent_mode';
  static const String _keyBadgeCount = 'notification_badge_count';
  static const String _keyNotificationHistory = 'notification_history_v3';
  static const String _keyReadNotifications = 'read_notifications_v2';

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 INITIALIZATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> initialize() async {
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔄 NOTIFICATION SERVICE v2.0 (Compatibility Layer)');
    debugPrint('   Backend: NotificationManager v8.0');
    debugPrint('   Features: Badge Auto-Update, Reactive UI');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      // ✅ Initialize NotificationManager backend
      final success = await _manager.initialize();
      
      if (!success) {
        debugPrint('❌ NotificationManager initialization failed');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('');
        return;
      }
      
      // ✅ Setup callback adapter (converts new signature to old signature)
      NotificationManager.onNotificationTapped = _adaptCallback;
      
      // ✅ Update badge count from storage
      await updateBadgeCountManual();
      
      debugPrint('✅ NotificationService Ready');
      debugPrint('   Using NotificationManager backend');
      debugPrint('   Badge count: ${badgeCount.value}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('');
      
    } catch (e, stack) {
      debugPrint('❌ NotificationService initialization error: $e');
      debugPrint('Stack: $stack');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('');
    }
  }

  /// ✅ Callback adapter: New signature → Old signature
  /// Converts Map<String, dynamic> to String for backward compatibility
  static void _adaptCallback(String type, Map<String, dynamic> data) {
    try {
      // Convert map to string (old code expects string)
      final dataString = data.toString();
      onNotificationTapped?.call(type, dataString);
      debugPrint('🔔 Callback adapted: $type → $dataString');
      
      // ✅ AUTO-UPDATE BADGE when notification is received
      NotificationService().updateBadgeCountManual();
      
    } catch (e) {
      debugPrint('⚠️ Error in callback adapter: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🕌 PRAYER NOTIFICATION SCHEDULING
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Schedule prayer notifications for today
  /// Old method signature - maintained for compatibility
  Future<void> scheduleTodayPrayerNotifications(
    Map<String, TimeOfDay> prayerTimes
  ) async {
    debugPrint('🔄 NotificationService.scheduleTodayPrayerNotifications()');
    debugPrint('   → Forwarding to NotificationManager.scheduleAllNotifications()');
    
    try {
      // ✅ Convert to NotificationManager format
      // NotificationManager needs tilawah times too
      final prefs = await SharedPreferences.getInstance();
      
      final tilawahTimes = {
        'Pagi': TimeOfDay(
          hour: prefs.getInt('tilawah_pagi_hour') ?? 6,
          minute: prefs.getInt('tilawah_pagi_minute') ?? 0,
        ),
        'Siang': TimeOfDay(
          hour: prefs.getInt('tilawah_siang_hour') ?? 13,
          minute: prefs.getInt('tilawah_siang_minute') ?? 0,
        ),
        'Malam': TimeOfDay(
          hour: prefs.getInt('tilawah_malam_hour') ?? 20,
          minute: prefs.getInt('tilawah_malam_minute') ?? 0,
        ),
      };
      
      await _manager.scheduleAllNotifications(
        prayerTimes: prayerTimes,
        tilawahTimes: tilawahTimes,
      );
      
      debugPrint('✅ Prayer notifications scheduled via NotificationManager');
      
      // ✅ NOTE: Badge count TIDAK update di sini!
      // Badge hanya update saat notifikasi benar-benar muncul
      
    } catch (e) {
      debugPrint('❌ Schedule failed: $e');
      rethrow;
    }
  }

  /// Alternative method name - same functionality
  Future<void> scheduleAllNotifications({
    required Map<String, TimeOfDay> prayerTimes
  }) async {
    debugPrint('🔄 NotificationService.scheduleAllNotifications()');
    debugPrint('   → Forwarding to scheduleTodayPrayerNotifications()');
    
    await scheduleTodayPrayerNotifications(prayerTimes);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🗑️ CANCEL NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    debugPrint('🔄 NotificationService.cancelAllNotifications()');
    debugPrint('   → Forwarding to NotificationManager.cancelAllNotifications()');
    
    try {
      await _manager.cancelAllNotifications();
      debugPrint('✅ All notifications cancelled via NotificationManager');
    } catch (e) {
      debugPrint('❌ Cancel failed: $e');
      rethrow;
    }
  }

  /// Cancel only prayer notifications
  /// Note: NotificationManager's cancelAll handles all types
  Future<void> cancelAllPrayerNotifications() async {
    debugPrint('🔄 NotificationService.cancelAllPrayerNotifications()');
    debugPrint('   → Forwarding to NotificationManager.cancelAllNotifications()');
    debugPrint('   (NotificationManager cancels all notification types)');
    
    await cancelAllNotifications();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💾 STORAGE & SETTINGS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Set silent mode (no sound/vibration)
  Future<void> setSilentMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySilentMode, enabled);
      debugPrint('🔇 Silent mode: ${enabled ? "ON" : "OFF"}');
    } catch (e) {
      debugPrint('⚠️ Error setting silent mode: $e');
    }
  }

  /// Get silent mode status
  Future<bool> getSilentMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keySilentMode) ?? false;
    } catch (e) {
      debugPrint('⚠️ Error getting silent mode: $e');
      return false;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔢 BADGE COUNT MANAGEMENT - UPDATED v2.0
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// ✅ Update badge count manually from SharedPreferences
  /// This method syncs with NotificationManager's badge system
  /// Call this when:
  /// - App starts
  /// - Opening Notification Center
  /// - After marking notifications as read
  /// - After deleting notifications
  Future<void> updateBadgeCountManual() async {
    try {
      await NotificationManager.checkFiredScheduledNotifications();
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      final readIdsJson = prefs.getString(_keyReadNotifications);
      
      if (historyJson == null) {
        await prefs.setInt(_keyBadgeCount, 0);
        badgeCount.value = 0;
        debugPrint('📊 Badge count: 0 (no history)');
        return;
      }
      
      // ✅ Calculate unread count
      final List<dynamic> history = jsonDecode(historyJson);
      Set<String> readIds = {};
      
      if (readIdsJson != null) {
        final List<dynamic> readList = jsonDecode(readIdsJson);
        readIds = readList.map((e) => e.toString()).toSet();
      }
      
      int unreadCount = 0;
      for (var item in history) {
        if (!readIds.contains(item['id'].toString())) {
          unreadCount++;
        }
      }
      
      // ✅ Update both SharedPreferences and ValueNotifier
      await prefs.setInt(_keyBadgeCount, unreadCount);
      badgeCount.value = unreadCount;
      
      debugPrint('📊 Badge count updated: $unreadCount unread notifications');
      
    } catch (e) {
      debugPrint('⚠️ Error updating badge count: $e');
      badgeCount.value = 0;
    }
  }

  /// ✅ Get badge count from storage (for initial load)
  Future<int> getBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyBadgeCount) ?? 0;
    } catch (e) {
      debugPrint('⚠️ Error getting badge count: $e');
      return 0;
    }
  }

  /// ✅ Clear badge (when user marks all as read)
  Future<void> clearBadge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyBadgeCount, 0);
      badgeCount.value = 0;
      debugPrint('✅ Badge cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing badge: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ℹ️ INFORMATION METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Get list of pending (scheduled) notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    debugPrint('🔄 NotificationService.getPendingNotifications()');
    debugPrint('   → Forwarding to NotificationManager.getPendingNotifications()');
    
    try {
      final pending = await _manager.getPendingNotifications();
      debugPrint('📋 Found ${pending.length} pending notifications');
      return pending;
    } catch (e) {
      debugPrint('⚠️ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Check if notification permission is granted
  Future<bool> checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      final isGranted = status.isGranted;
      debugPrint('🔐 Notification permission: ${isGranted ? "GRANTED" : "DENIED"}');
      return isGranted;
    } catch (e) {
      debugPrint('⚠️ Error checking permission: $e');
      return false;
    }
  }

  /// Get current timezone being used
  /// NotificationManager uses Asia/Makassar by default
  String getCurrentTimezone() {
    return 'Asia/Makassar';
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🧹 CLEANUP
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Dispose/cleanup (currently no-op as NotificationManager handles everything)
  void dispose() {
    debugPrint('🧹 NotificationService disposed');
    // NotificationManager is a singleton, no need to dispose
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎨 NOTIFICATION TYPE ENUM (Maintained for Compatibility)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum NotificationType {
  // Prayer times
  subuh, 
  dzuhur, 
  ashar, 
  maghrib, 
  isya,
  
  // General categories
  prayer, 
  dzikir, 
  quran, 
  doa, 
  system,
  
  // New prayer times
  tahajud,
  duha;

  /// Get icon for notification type
  IconData get icon {
    switch (this) {
      case NotificationType.tahajud:
        return Icons.nights_stay;
      case NotificationType.subuh:
        return Icons.wb_twilight;
      case NotificationType.duha:
        return Icons.wb_sunny_outlined;
      case NotificationType.dzuhur:
        return Icons.wb_sunny;
      case NotificationType.ashar:
        return Icons.wb_sunny_outlined;
      case NotificationType.maghrib:
        return Icons.nights_stay;
      case NotificationType.isya:
        return Icons.bedtime;
      case NotificationType.prayer:
        return Icons.mosque_rounded;
      case NotificationType.dzikir:
        return Icons.auto_stories_rounded;
      case NotificationType.quran:
        return Icons.menu_book_rounded;
      case NotificationType.doa:
        return Icons.volunteer_activism_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
    }
  }

  /// Get color for notification type
  Color get color {
    switch (this) {
      case NotificationType.tahajud:
        return Color(0xFF4F46E5); // Indigo
      case NotificationType.subuh:
        return Color(0xFF8B5CF6); // Purple
      case NotificationType.duha:
        return Color(0xFFFBBF24); // Yellow
      case NotificationType.dzuhur:
        return Color(0xFFF59E0B); // Amber
      case NotificationType.ashar:
        return Color(0xFFEF4444); // Red
      case NotificationType.maghrib:
        return Color(0xFFEC4899); // Pink
      case NotificationType.isya:
        return Color(0xFF3B82F6); // Blue
      case NotificationType.prayer:
        return Color(0xFF059669); // Green
      case NotificationType.dzikir:
        return Color(0xFF06B6D4); // Cyan
      case NotificationType.quran:
        return Color(0xFF10B981); // Emerald
      case NotificationType.doa:
        return Color(0xFFA855F7); // Purple
      case NotificationType.system:
        return Color(0xFF6B7280); // Gray
    }
  }

  /// Get display name for notification type
  String get displayName {
    switch (this) {
      case NotificationType.tahajud:
        return 'Tahajud';
      case NotificationType.subuh:
        return 'Subuh';
      case NotificationType.duha:
        return 'Duha';
      case NotificationType.dzuhur:
        return 'Dzuhur';
      case NotificationType.ashar:
        return 'Ashar';
      case NotificationType.maghrib:
        return 'Maghrib';
      case NotificationType.isya:
        return 'Isya';
      case NotificationType.prayer:
        return 'Sholat';
      case NotificationType.dzikir:
        return 'Dzikir';
      case NotificationType.quran:
        return 'Al-Quran';
      case NotificationType.doa:
        return 'Doa';
      case NotificationType.system:
        return 'System';
    }
  }

  /// Parse from string
  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'tahajud':
        return NotificationType.tahajud;
      case 'subuh':
        return NotificationType.subuh;
      case 'duha':
        return NotificationType.duha;
      case 'dzuhur':
        return NotificationType.dzuhur;
      case 'ashar':
        return NotificationType.ashar;
      case 'maghrib':
        return NotificationType.maghrib;
      case 'isya':
        return NotificationType.isya;
      case 'prayer':
        return NotificationType.prayer;
      case 'dzikir':
        return NotificationType.dzikir;
      case 'quran':
      case 'tilawah':
        return NotificationType.quran;
      case 'doa':
        return NotificationType.doa;
      default:
        return NotificationType.system;
    }
  }
}