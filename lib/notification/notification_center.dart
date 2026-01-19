// screens/notification/notification_center_page.dart - MIGRATED TO NotificationManager
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/notification/notification_manager.dart'; // ✅ CHANGED
import 'package:myquran/screens/util/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({Key? key}) : super(key: key);

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> 
    with TickerProviderStateMixin {
  final NotificationManager _notificationManager = NotificationManager(); // ✅ CHANGED
  
  List<NotificationItem> _allNotifications = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const String _keyNotificationHistory = 'notification_history_v3';
  static const String _keyReadNotifications = 'read_notifications_v2';
  static const String _keyBadgeCount = 'notification_badge_count'; // ✅ ADDED

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.shortestSide >= 600;
  double _getContentFontSize(BuildContext context) => _isTablet(context) ? 14.5 : 13.0;
  double _getTitleFontSize(BuildContext context) => _isTablet(context) ? 16.0 : 14.5;
  double _getHeadingFontSize(BuildContext context) => _isTablet(context) ? 22.0 : 20.0;
  double _getIconSize(BuildContext context) => _isTablet(context) ? 24.0 : 22.0;
  double _getPadding(BuildContext context) => _isTablet(context) ? 20.0 : 16.0;

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 60) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes} menit lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam yang lalu';
    if (difference.inDays == 1) return 'Kemarin';
    if (difference.inDays < 7) return '${difference.inDays} hari yang lalu';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      final readIdsJson = prefs.getString(_keyReadNotifications);
      
      List<NotificationItem> historyItems = [];
      Set<String> readIds = {};
      
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        historyItems = historyList.map((item) => NotificationItem.fromJson(item)).toList();
      }
      
      if (readIdsJson != null) {
        final List<dynamic> readList = jsonDecode(readIdsJson);
        readIds = readList.map((e) => e.toString()).toSet();
      }
      
      _allNotifications = historyItems;
      
      for (var i = 0; i < _allNotifications.length; i++) {
        if (readIds.contains(_allNotifications[i].id)) {
          _allNotifications[i] = _allNotifications[i].copyWith(isRead: true);
        }
      }
      
      _allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading notifications: $e');
    }
    
    setState(() => _isLoading = false);
    _fadeController.forward();
  }

  // ✅ UPDATED: Manual badge count update (NotificationManager handles this internally)
  Future<void> _updateBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      final readIdsJson = prefs.getString(_keyReadNotifications);
      
      if (historyJson == null) {
        await prefs.setInt(_keyBadgeCount, 0);
        return;
      }
      
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
      
      await prefs.setInt(_keyBadgeCount, unreadCount);
    } catch (e) {
      print('⚠️ Error updating badge: $e');
    }
  }

  Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final historyItems = _allNotifications;
      final historyJson = jsonEncode(historyItems.map((item) => item.toJson()).toList());
      await prefs.setString(_keyNotificationHistory, historyJson);
      
      final readIds = _allNotifications.where((item) => item.isRead).map((item) => item.id).toList();
      final readIdsJson = jsonEncode(readIds);
      await prefs.setString(_keyReadNotifications, readIdsJson);
      
      // ✅ UPDATED: Use manual badge update instead of NotificationService method
      await _updateBadgeCount();
      
    } catch (e) {
      print('Error saving notification history: $e');
    }
  }

  void _markAsRead(String id) async {
    setState(() {
      final index = _allNotifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _allNotifications[index] = _allNotifications[index].copyWith(isRead: true);
      }
    });
    
    await _saveNotificationHistory();
  }

  void _markAllAsRead() async {
    setState(() {
      _allNotifications = _allNotifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    
    await _saveNotificationHistory();
    
    _showSnackBar('Semua notifikasi ditandai telah dibaca', icon: Icons.done_all, color: Color(0xFF059669));
  }

  void _deleteNotification(String id) {
    final deleted = _allNotifications.firstWhere((n) => n.id == id);
    final deletedIndex = _allNotifications.indexWhere((n) => n.id == id);
    
    setState(() => _allNotifications.removeWhere((n) => n.id == id));
    _saveNotificationHistory();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('Notifikasi berhasil dihapus', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Color(0xFF1F2937),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'URUNGKAN',
          textColor: AppColors.primary,
          onPressed: () {
            setState(() => _allNotifications.insert(deletedIndex, deleted));
            _saveNotificationHistory();
          },
        ),
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 32),
            ),
            SizedBox(height: 20),
            Text(
              'Hapus Semua Notifikasi?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Tindakan ini tidak dapat dibatalkan. Semua riwayat notifikasi akan dihapus permanen.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Batal', style: TextStyle(fontSize: 15, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _allNotifications.clear());
              await _saveNotificationHistory();
              
              _showSnackBar('Semua notifikasi berhasil dihapus', icon: Icons.check_circle, color: Color(0xFFEF4444));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Hapus Semua', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required IconData icon, required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _allNotifications.where((n) => !n.isRead).length;
    
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontSize: _getHeadingFontSize(context),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          if (_allNotifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              offset: Offset(0, 50),
              onSelected: (value) {
                if (value == 'mark_all') _markAllAsRead();
                else if (value == 'clear_all') _clearAll();
                else if (value == 'refresh') _loadNotifications();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(children: [
                    Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 14),
                    Text('Muat Ulang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))
                  ]),
                ),
                PopupMenuItem(
                  value: 'mark_all',
                  child: Row(children: [
                    Icon(Icons.done_all_rounded, color: Color(0xFF059669), size: 22),
                    SizedBox(width: 14),
                    Text('Tandai Semua Dibaca', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))
                  ]),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(children: [
                    Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 22),
                    SizedBox(width: 14),
                    Text('Hapus Semua', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))
                  ]),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3))
          : Column(
              children: [
                if (unreadCount > 0) _buildUnreadBanner(unreadCount),
                if (_allNotifications.isEmpty)
                  Expanded(child: _buildEmptyState())
                else
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: EdgeInsets.all(_getPadding(context)),
                          itemCount: _allNotifications.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12),
                          itemBuilder: (context, index) => _buildNotificationCard(_allNotifications[index]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildUnreadBanner(int count) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Notifikasi Baru',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                Text(
                  'Anda memiliki $count notifikasi yang belum dibaca',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _markAllAsRead,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.white,
            ),
            child: Text('Tandai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.primary),
          ),
          SizedBox(height: 24),
          Text(
            'Belum Ada Notifikasi',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              'Notifikasi waktu sholat, dzikir, dan tilawah Al-Qur\'an akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      background: _buildSwipeBackground(true),
      secondaryBackground: _buildSwipeBackground(false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _markAsRead(notification.id);
          return false;
        }
        return true;
      },
      onDismissed: (_) => _deleteNotification(notification.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? Color(0xFFE5E7EB) : notification.type.color.withOpacity(0.3),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: notification.isRead 
                ? Colors.black.withOpacity(0.04)
                : notification.type.color.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (!notification.isRead) _markAsRead(notification.id);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [notification.type.color, notification.type.color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: notification.type.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(notification.type.icon, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                  color: Color(0xFF111827),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 10,
                                height: 10,
                                margin: EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [notification.type.color, notification.type.color.withOpacity(0.8)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: notification.type.color.withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          notification.body,
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF9CA3AF)),
                            SizedBox(width: 6),
                            Text(
                              _getTimeAgo(notification.timestamp),
                              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isLeft) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLeft 
            ? [Color(0xFF059669), Color(0xFF047857)]
            : [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLeft ? Icons.done_rounded : Icons.delete_outline_rounded,
            color: Colors.white,
            size: 28,
          ),
          SizedBox(height: 4),
          Text(
            isLeft ? 'Tandai Dibaca' : 'Hapus',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

enum NotificationType {
  subuh, dzuhur, ashar, maghrib, isya,
  prayer, dzikir, quran, doa, system;

  IconData get icon {
    switch (this) {
      case NotificationType.subuh: return Icons.wb_twilight;
      case NotificationType.dzuhur: return Icons.wb_sunny;
      case NotificationType.ashar: return Icons.wb_sunny_outlined;
      case NotificationType.maghrib: return Icons.nights_stay;
      case NotificationType.isya: return Icons.bedtime;
      case NotificationType.prayer: return Icons.mosque_rounded;
      case NotificationType.dzikir: return Icons.auto_stories_rounded;
      case NotificationType.quran: return Icons.menu_book_rounded;
      case NotificationType.doa: return Icons.volunteer_activism_rounded;
      case NotificationType.system: return Icons.info_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.subuh: return Color(0xFF8B5CF6);
      case NotificationType.dzuhur: return Color(0xFFF59E0B);
      case NotificationType.ashar: return Color(0xFFEF4444);
      case NotificationType.maghrib: return Color(0xFFEC4899);
      case NotificationType.isya: return Color(0xFF3B82F6);
      case NotificationType.prayer: return Color(0xFF059669);
      case NotificationType.dzikir: return Color(0xFF06B6D4);
      case NotificationType.quran: return Color(0xFF10B981);
      case NotificationType.doa: return Color(0xFFA855F7);
      case NotificationType.system: return Color(0xFF6B7280);
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isScheduled;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isScheduled = false,
  });

  NotificationItem copyWith({
    String? id, String? title, String? body,
    NotificationType? type, DateTime? timestamp,
    bool? isRead, bool? isScheduled,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isScheduled: isScheduled ?? this.isScheduled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.index,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isRead': isRead,
    'isScheduled': isScheduled,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values[json['type'] as int],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isRead: json['isRead'] as bool? ?? false,
      isScheduled: json['isScheduled'] as bool? ?? false,
    );
  }
}