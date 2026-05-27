// notification/notification_badge_manager.dart - SINGLETON + VALUENOTIFIER
// Inspired by WhatsApp, Telegram, and Firebase Cloud Messaging badge systems

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// ✅ POWERFUL SINGLETON PATTERN
/// Digunakan oleh: WhatsApp, Telegram, Instagram, Firebase
/// Keuntungan:
/// - Global access dari mana saja
/// - Single source of truth
/// - Tidak perlu Provider/Context
/// - Memory efficient
/// - Instant updates
class NotificationBadgeManager {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SINGLETON INSTANCE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  static final NotificationBadgeManager _instance = NotificationBadgeManager._internal();
  factory NotificationBadgeManager() => _instance;
  NotificationBadgeManager._internal();
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // VALUENOTIFIER - Ultra Fast & Lightweight
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Badge counter - Listen to this in UI
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  
  /// Total notifications
  final ValueNotifier<int> totalCount = ValueNotifier<int>(0);
  
  /// Loading state
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CONSTANTS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  static const String _keyHistory = 'notification_history_v3';
  static const String _keyReadIds = 'read_notifications';
  
  Timer? _autoRefreshTimer;
  bool _isInitialized = false;
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INITIALIZATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚀 INITIALIZING NOTIFICATION BADGE MANAGER (Singleton)');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // First load
    await refresh();
    
    // Start auto-refresh every 1 second
    _startAutoRefresh();
    
    _isInitialized = true;
    
    debugPrint('✅ Badge Manager Ready');
    debugPrint('   📊 Unread: ${unreadCount.value}');
    debugPrint('   📈 Total: ${totalCount.value}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
  
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!isLoading.value) {
        refresh(silent: true);
      }
    });
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CORE METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Refresh badge count from storage
  Future<void> refresh({bool silent = false}) async {
    if (isLoading.value) return;
    
    isLoading.value = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get data
      final historyJson = prefs.getString(_keyHistory);
      final readIdsJson = prefs.getString(_keyReadIds);
      
      if (historyJson == null || historyJson.isEmpty) {
        _updateCounts(0, 0, silent);
        return;
      }
      
      // Parse history
      final List<dynamic> historyList = jsonDecode(historyJson);
      
      // Filter real notifications (exclude scheduled)
      final realNotifications = historyList
          .where((item) => item['isScheduled'] != true)
          .toList();
      
      // Parse read IDs
      Set<String> readIds = {};
      if (readIdsJson != null && readIdsJson.isNotEmpty) {
        final List<dynamic> readList = jsonDecode(readIdsJson);
        readIds = readList.map((e) => e.toString()).toSet();
      }
      
      // Count unread
      int unread = 0;
      for (var item in realNotifications) {
        final id = item['id']?.toString() ?? '';
        if (id.isNotEmpty && !readIds.contains(id)) {
          unread++;
        }
      }
      
      _updateCounts(unread, realNotifications.length, silent);
      
    } catch (e) {
      debugPrint('❌ Badge refresh error: $e');
      _updateCounts(0, 0, silent);
    } finally {
      isLoading.value = false;
    }
  }
  
  void _updateCounts(int unread, int total, bool silent) {
    bool changed = false;
    
    if (unreadCount.value != unread) {
      unreadCount.value = unread;
      changed = true;
    }
    
    if (totalCount.value != total) {
      totalCount.value = total;
      changed = true;
    }
    
    if (changed && !silent) {
      debugPrint('🔔 Badge updated: $unread unread / $total total');
    }
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PUBLIC API
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Add new notification
  Future<void> addNotification({
    required String title,
    required String body,
    required int typeIndex,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyHistory);
      
      List<Map<String, dynamic>> history = [];
      if (historyJson != null && historyJson.isNotEmpty) {
        history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      }
      
      final id = 'notif_${DateTime.now().millisecondsSinceEpoch}';
      
      history.insert(0, {
        'id': id,
        'title': title,
        'body': body,
        'type': typeIndex,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
        'isScheduled': false,
      });
      
      if (history.length > 100) {
        history = history.sublist(0, 100);
      }
      
      await prefs.setString(_keyHistory, jsonEncode(history));
      
      // Instant update
      unreadCount.value++;
      totalCount.value++;
      
      debugPrint('➕ Notification added: $title');
      debugPrint('   Badge: ${unreadCount.value} unread');
      
    } catch (e) {
      debugPrint('❌ Add notification error: $e');
    }
  }
  
  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIdsJson = prefs.getString(_keyReadIds);
      
      Set<String> readIds = {};
      if (readIdsJson != null && readIdsJson.isNotEmpty) {
        final List<dynamic> readList = jsonDecode(readIdsJson);
        readIds = readList.map((e) => e.toString()).toSet();
      }
      
      if (readIds.contains(id)) {
        return; // Already read
      }
      
      readIds.add(id);
      await prefs.setString(_keyReadIds, jsonEncode(readIds.toList()));
      
      // Instant update
      if (unreadCount.value > 0) {
        unreadCount.value--;
        debugPrint('📖 Marked as read: $id');
        debugPrint('   Badge: ${unreadCount.value} unread');
      }
      
    } catch (e) {
      debugPrint('❌ Mark as read error: $e');
    }
  }
  
  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyHistory);
      
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        
        final allIds = historyList
            .where((item) => item['isScheduled'] != true)
            .map((item) => item['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        
        await prefs.setString(_keyReadIds, jsonEncode(allIds));
      }
      
      // Instant update
      unreadCount.value = 0;
      debugPrint('📖 All marked as read');
      
    } catch (e) {
      debugPrint('❌ Mark all as read error: $e');
    }
  }
  
  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHistory);
      await prefs.remove(_keyReadIds);
      
      // Instant update
      unreadCount.value = 0;
      totalCount.value = 0;
      
      debugPrint('🗑️ All notifications cleared');
      
    } catch (e) {
      debugPrint('❌ Clear all error: $e');
    }
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Get current unread count (synchronous)
  int get currentUnreadCount => unreadCount.value;
  
  /// Get current total count (synchronous)
  int get currentTotalCount => totalCount.value;
  
  /// Check if has unread
  bool get hasUnread => unreadCount.value > 0;
  
  /// Debug info
  void printDebugInfo() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🐛 NOTIFICATION BADGE DEBUG INFO');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('   Initialized: $_isInitialized');
    debugPrint('   Unread Count: ${unreadCount.value}');
    debugPrint('   Total Count: ${totalCount.value}');
    debugPrint('   Has Unread: $hasUnread');
    debugPrint('   Is Loading: ${isLoading.value}');
    debugPrint('   Auto-Refresh: ${_autoRefreshTimer?.isActive ?? false}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
  
  /// Dispose (call on app termination)
  void dispose() {
    _autoRefreshTimer?.cancel();
    unreadCount.dispose();
    totalCount.dispose();
    isLoading.dispose();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GLOBAL INSTANCE - Easy Access
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Global badge manager instance
/// Usage: badgeManager.unreadCount.value
final badgeManager = NotificationBadgeManager();