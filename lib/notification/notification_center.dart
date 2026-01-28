// screens/notification/notification_center_page.dart - MODERN UI
// ✅ Properly handle scheduled vs shown notifications
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/notification/notification_manager.dart';
import 'package:myquran/notification/notification_service.dart';
import 'package:myquran/screens/util/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ✅ PINDAHKAN ENUM KE TOP-LEVEL (di luar class)
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

// ✅ PINDAHKAN CLASS NOTIFICATIONITEM KE TOP-LEVEL (di luar class)
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

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({Key? key}) : super(key: key);

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> 
    with TickerProviderStateMixin {
  final NotificationManager _notificationManager = NotificationManager();
  
  List<NotificationItem> _allNotifications = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const String _keyNotificationHistory = 'notification_history_v3';
  static const String _keyReadNotifications = 'read_notifications_v2';
  static const String _keyBadgeCount = 'notification_badge_count';

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
  
  // ✅ CRITICAL: Force refresh badge SEBELUM load notifications
  print('🔔 NotificationCenter: Opening - refreshing badge');
  NotificationService().updateBadgeCountManual();
  
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

  // ✅ TAMBAHKAN fungsi untuk format waktu singkat
  String _getShortTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}j';
    if (difference.inDays == 1) return 'Kemarin';
    if (difference.inDays < 7) return '${difference.inDays}h';
    
    return '${dateTime.day}/${dateTime.month}';
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
      
      _allNotifications.sort((a, b) {
        if (a.isScheduled && !b.isScheduled) return -1;
        if (!a.isScheduled && b.isScheduled) return 1;
        if (!a.isRead && b.isRead) return -1;
        if (a.isRead && !b.isRead) return 1;
        return b.timestamp.compareTo(a.timestamp);
      });
      
      print('📱 Loaded ${_allNotifications.length} notifications');
      print('📊 Scheduled: ${_allNotifications.where((n) => n.isScheduled).length}');
      print('📊 Unread: ${_allNotifications.where((n) => !n.isRead && !n.isScheduled).length}');
      
    } catch (e) {
      print('Error loading notifications: $e');
    }
    
    setState(() => _isLoading = false);
    _fadeController.forward();
      // ✅ CRITICAL: Update badge setelah data loaded
  Future.delayed(Duration(milliseconds: 200), () {
    print('🔄 NotificationCenter: Badge refresh after load complete');
    _updateBadgeCount();
  });
  }

  Future<void> _updateBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      final readIdsJson = prefs.getString(_keyReadNotifications);
      
      if (historyJson == null) {
        await prefs.setInt(_keyBadgeCount, 0);
        NotificationService.badgeCount.value = 0;
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
        final isScheduled = item['isScheduled'] as bool? ?? false;
        if (!isScheduled && !readIds.contains(item['id'].toString())) {
          unreadCount++;
        }
      }
      
      await prefs.setInt(_keyBadgeCount, unreadCount);
      NotificationService.badgeCount.value = unreadCount;
      print('🔢 Badge updated: $unreadCount');
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
      
      await _updateBadgeCount();
      NotificationService().updateBadgeCountManual();
      
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
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
                    Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Text('Muat Ulang', style: TextStyle(fontSize: 14))
                  ]),
                ),
                if (unreadCount > 0)
                  PopupMenuItem(
                    value: 'mark_all',
                    child: Row(children: [
                      Icon(Icons.done_all_rounded, color: Color(0xFF10B981), size: 20),
                      SizedBox(width: 12),
                      Text('Tandai Semua Dibaca', style: TextStyle(fontSize: 14))
                    ]),
                  ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(children: [
                    Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 20),
                    SizedBox(width: 12),
                    Text('Hapus Semua', style: TextStyle(fontSize: 14))
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
  padding: EdgeInsets.zero, // ✅ Sudah benar
  itemCount: _allNotifications.length,
  separatorBuilder: (_, __) => SizedBox.shrink(), // ✅ Sudah benar
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
      padding: EdgeInsets.symmetric(
        horizontal: _getPadding(context),
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_rounded,
            color: AppColors.primary,
            size: _getIconSize(context) - 2,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count notifikasi belum dibaca',
              style: TextStyle(
                fontSize: _getContentFontSize(context),
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          TextButton(
            onPressed: _markAllAsRead,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Tandai semua',
              style: TextStyle(
                fontSize: _getContentFontSize(context) - 1,
                fontWeight: FontWeight.w600,
              ),
            ),
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
  final isScheduled = notification.isScheduled;
  
  return Dismissible(
    key: Key(notification.id),
    background: _buildSwipeBackground(true),
    secondaryBackground: _buildSwipeBackground(false),
    confirmDismiss: (direction) async {
      if (direction == DismissDirection.startToEnd) {
        if (!isScheduled) _markAsRead(notification.id);
        return false;
      }
      return true;
    },
    onDismissed: (_) => _deleteNotification(notification.id),
    child: Container(
      decoration: BoxDecoration(
        // ✅ Background berbeda untuk yang belum dibaca
        color: !notification.isRead && !isScheduled
            ? notification.type.color.withOpacity(0.04)
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (!notification.isRead && !isScheduled) {
              _markAsRead(notification.id);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getPadding(context),
              vertical: 14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _getIconSize(context) * 1.8,
                  height: _getIconSize(context) * 1.8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isScheduled
                          ? [Color(0xFF047857), Color(0xFF059669)]
                          : !notification.isRead
                              ? [notification.type.color, notification.type.color.withOpacity(0.85)]
                              : [Color(0xFF9CA3AF), Color(0xFF6B7280)], // ✅ Abu-abu untuk yang sudah dibaca
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isScheduled ? Icons.schedule_rounded : notification.type.icon,
                    color: Colors.white,
                    size: _getIconSize(context),
                  ),
                ),
                SizedBox(width: 12),
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
                                fontSize: _getTitleFontSize(context),
                                // ✅ Font weight lebih jelas perbedaannya
                                fontWeight: notification.isRead 
                                    ? FontWeight.w400  // ✅ Lebih tipis untuk yang sudah dibaca
                                    : FontWeight.w700, // ✅ Bold untuk yang belum dibaca
                                // ✅ Warna lebih kontras
                                color: notification.isRead 
                                    ? Color(0xFF6B7280) // ✅ Abu-abu untuk yang sudah dibaca
                                    : Color(0xFF111827), // ✅ Hitam untuk yang belum dibaca
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            _getShortTimeAgo(notification.timestamp),
                            style: TextStyle(
                              fontSize: _getContentFontSize(context) - 1.5,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (!notification.isRead && !isScheduled) ...[
                            SizedBox(width: 6),
                            Container(
                              width: 8, // ✅ Sedikit lebih besar
                              height: 8,
                              decoration: BoxDecoration(
                                color: notification.type.color,
                                shape: BoxShape.circle,
                                boxShadow: [ // ✅ Tambah shadow agar lebih terlihat
                                  BoxShadow(
                                    color: notification.type.color.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: _getContentFontSize(context),
                          // ✅ Warna lebih kontras
                          color: notification.isRead 
                              ? Color(0xFF9CA3AF) // ✅ Abu-abu terang untuk yang sudah dibaca
                              : Color(0xFF374151), // ✅ Lebih gelap untuk yang belum dibaca
                          height: 1.35,
                          fontWeight: notification.isRead 
                              ? FontWeight.w400
                              : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isScheduled) ...[
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Color(0xFF047857).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Color(0xFF047857).withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: Color(0xFF047857),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Terjadwal',
                                style: TextStyle(
                                  fontSize: _getContentFontSize(context) - 2,
                                  color: Color(0xFF047857),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
      decoration: BoxDecoration(
        color: isLeft ? Color(0xFF10B981) : Color(0xFFEF4444),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Icon(
        isLeft ? Icons.check_rounded : Icons.delete_outline_rounded,
        color: Colors.white,
        size: _getIconSize(context),
      ),
    );
  }
}