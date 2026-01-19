// notification/notification_manager.dart - PRODUCTION READY v4.0
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🔔 UNIFIED NOTIFICATION MANAGER - COMPLETE WITH HISTORY
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 
/// Features:
/// ✅ Works when app is CLOSED/KILLED/BACKGROUND
/// ✅ Full-screen popup like WhatsApp
/// ✅ Saves to Notification Center automatically
/// ✅ Android 12+ & 13+ compatible
/// ✅ Exact alarm support
/// ✅ High priority + heads-up display
/// ✅ Notification history tracking
/// ✅ Badge count management
/// ✅ NULL-SAFE everywhere
/// 
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  tz.Location? _userLocation;
  
  // Channel IDs - MUST be unique and consistent
  static const String _channelPrayer = 'prayer_notifications_v7';
  static const String _channelDzikir = 'dzikir_notifications_v7';
  static const String _channelTilawah = 'tilawah_notifications_v7';
  static const String _channelTest = 'test_notifications_v7';
  
  // Notification IDs
  static const Map<String, int> _notifIds = {
    'Subuh': 1001,
    'Dzuhur': 1002,
    'Ashar': 1003,
    'Maghrib': 1004,
    'Isya': 1005,
    'DzikirPagi': 2001,
    'DzikirPetang': 2002,
    'TilawahPagi': 3001,
    'TilawahSiang': 3002,
    'TilawahMalam': 3003,
    'Test': 9999,
  };

  // Storage keys
  static const String _keyNotificationHistory = 'notification_history_v3';
  static const String _keyReadNotifications = 'read_notifications_v2';
  static const String _keyBadgeCount = 'notification_badge_count';

  // Callback for notification tap
  static Function(String type, Map<String, dynamic> data)? onNotificationTapped;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 INITIALIZATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 INITIALIZING NOTIFICATION MANAGER v4.0');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      // 1. Initialize timezone
      await _initializeTimezone();
      
      // 2. Initialize plugin
      await _initializePlugin();
      
      // 3. Create notification channels (CRITICAL for Android)
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }
      
      // 4. Request ALL necessary permissions
      final perms = await requestPermissions();
      if (perms['notification'] != true) {
        print('❌ Notification permission denied');
        return false;
      }
      
      _isInitialized = true;
      print('✅ NOTIFICATION MANAGER READY');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
      return true;
      
    } catch (e, stack) {
      print('❌ Initialization failed: $e');
      print('Stack: $stack');
      return false;
    }
  }

  Future<void> _initializeTimezone() async {
    print('📍 Initializing timezone...');
    
    tz.initializeTimeZones();
    
    final prefs = await SharedPreferences.getInstance();
    final savedTz = prefs.getString('user_timezone');
    
    if (savedTz != null) {
      _userLocation = tz.getLocation(savedTz);
      print('   Using saved: $savedTz');
    } else {
      _userLocation = tz.getLocation('Asia/Makassar'); // WITA (Bali)
      await prefs.setString('user_timezone', 'Asia/Makassar');
      print('   Using default: Asia/Makassar (WITA)');
    }
    
    tz.setLocalLocation(_userLocation!);
    print('   Current time: ${tz.TZDateTime.now(_userLocation!)}');
  }

  Future<void> _initializePlugin() async {
    print('📍 Initializing plugin...');
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );
    
    print('   ✅ Plugin initialized');
  }

  Future<void> _createNotificationChannels() async {
    print('📍 Creating notification channels...');
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) {
      print('❌ Android plugin not available');
      return;
    }
    
    // ⭐ CRITICAL: HIGH IMPORTANCE for popup notifications
    
    // Prayer channel - MAX IMPORTANCE for full-screen popup
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelPrayer,
        'Waktu Sholat',
        description: 'Pengingat waktu sholat 5 waktu',
        importance: Importance.max, // ⭐ CRITICAL
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFF059669),
      ),
    );
    
    // Dzikir channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelDzikir,
        'Dzikir Pagi & Petang',
        description: 'Pengingat dzikir pagi dan petang',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFF06B6D4),
      ),
    );
    
    // Tilawah channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelTilawah,
        'Tilawah Al-Quran',
        description: 'Pengingat membaca Al-Quran',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFF10B981),
      ),
    );
    
    // Test channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelTest,
        'Notifications',
        description: 'For testing notification system',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    
    print('   ✅ All channels created with HIGH IMPORTANCE');
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔐 PERMISSIONS (Android 13+ compatible) - FIXED v2.0
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<Map<String, bool>> requestPermissions() async {
    print('📍 Requesting permissions...');
    
    final results = <String, bool>{};
    
    // 1. POST_NOTIFICATIONS permission (Android 13+)
    final notifStatus = await Permission.notification.request();
    results['notification'] = notifStatus.isGranted;
    print('   Notification: ${notifStatus.isGranted ? '✅' : '❌'}');
    
    if (notifStatus.isPermanentlyDenied) {
      print('   ⚠️ PERMANENTLY DENIED - User must enable in settings');
      await openAppSettings();
    }
    
    if (Platform.isAndroid) {
      // ⭐ CRITICAL FIX #4: Request Full Screen Intent Permission via API
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        try {
          print('   📱 Requesting full screen intent permission...');
          await androidPlugin.requestFullScreenIntentPermission();
          results['fullScreen'] = true;
          print('   Full Screen Intent: ✅ REQUESTED');
        } catch (e) {
          print('   ⚠️ Full screen intent request error: $e');
          results['fullScreen'] = false;
        }
      }
      
      // 2. ⭐ CRITICAL: Request EXACT ALARM permission via API (Android 12+)
      try {
        print('   ⏰ Requesting exact alarms permission...');
        
        // First check if we can use exact alarms
        final canScheduleExactAlarms = await androidPlugin?.canScheduleExactNotifications() ?? false;
        
        if (!canScheduleExactAlarms) {
          print('   ⚠️ Cannot schedule exact alarms - requesting permission...');
          
          // Request permission via API
          await androidPlugin?.requestExactAlarmsPermission();
          
          // Check again after request
          final canScheduleAfterRequest = await androidPlugin?.canScheduleExactNotifications() ?? false;
          results['exactAlarm'] = canScheduleAfterRequest;
          print('   Exact Alarm: ${canScheduleAfterRequest ? '✅' : '❌'}');
          
          if (!canScheduleAfterRequest) {
            print('   ⚠️ CRITICAL: User denied exact alarm permission!');
            print('   Notifications may not work on Android 14+');
          }
        } else {
          results['exactAlarm'] = true;
          print('   Exact Alarm: ✅ Already granted');
        }
      } catch (e) {
        print('   ⚠️ Exact alarm permission error: $e');
        
        // Fallback: try using permission_handler
        try {
          final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
          
          if (!exactAlarmStatus.isGranted) {
            final result = await Permission.scheduleExactAlarm.request();
            results['exactAlarm'] = result.isGranted;
          } else {
            results['exactAlarm'] = true;
          }
          
          print('   Exact Alarm (fallback): ${results['exactAlarm'] == true ? '✅' : '❌'}');
        } catch (e2) {
          print('   ⚠️ Exact alarm not available on this device');
          results['exactAlarm'] = false;
        }
      }
      
      // 3. System Alert Window (for overlay - optional)
      try {
        final alertStatus = await Permission.systemAlertWindow.status;
        if (!alertStatus.isGranted) {
          await Permission.systemAlertWindow.request();
        }
        results['systemAlert'] = (await Permission.systemAlertWindow.status).isGranted;
        print('   System Alert: ${results['systemAlert'] == true ? '✅' : '⚠️'}');
      } catch (e) {
        results['systemAlert'] = true; // Default true for older Android
      }
      
      // 4. Ignore battery optimization
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
      results['battery'] = (await Permission.ignoreBatteryOptimizations.status).isGranted;
      print('   Battery Optimization: ${results['battery'] == true ? '✅' : '⚠️'}');
    }
    
    return results;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📅 SCHEDULE ALL NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> scheduleAllNotifications({
    required Map<String, TimeOfDay> prayerTimes,
    Map<String, bool>? enabledPrayers,
    required Map<String, TimeOfDay> tilawahTimes,
  }) async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📅 SCHEDULING ALL NOTIFICATIONS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Cancel all existing
    await cancelAllNotifications();
    
    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    
    final enabled = enabledPrayers ?? {
      'Subuh': prefs.getBool('notif_enable_subuh') ?? true,
      'Dzuhur': prefs.getBool('notif_enable_dzuhur') ?? true,
      'Ashar': prefs.getBool('notif_enable_ashar') ?? true,
      'Maghrib': prefs.getBool('notif_enable_maghrib') ?? true,
      'Isya': prefs.getBool('notif_enable_isya') ?? true,
    };
    
    final enableDzikirPagi = prefs.getBool('notif_enable_dzikir_pagi') ?? true;
    final enableDzikirPetang = prefs.getBool('notif_enable_dzikir_petang') ?? true;
    final enableTilawahPagi = prefs.getBool('notif_enable_tilawah_pagi') ?? true;
    final enableTilawahSiang = prefs.getBool('notif_enable_tilawah_siang') ?? false;
    final enableTilawahMalam = prefs.getBool('notif_enable_tilawah_malam') ?? true;
    
    int scheduled = 0;
    
    // Schedule prayer notifications
    for (var entry in prayerTimes.entries) {
      if (entry.key == 'Terbit') continue;
      
      if (enabled[entry.key] == true) {
        await _schedulePrayerNotification(entry.key, entry.value);
        scheduled++;
        print('✅ ${entry.key}: ${_formatTime(entry.value)}');
      }
    }
    
    // Calculate and schedule dzikir times
    if (enableDzikirPagi && prayerTimes.containsKey('Subuh')) {
      final dzikirPagiTime = _addMinutes(prayerTimes['Subuh']!, 30);
      await _scheduleDzikirNotification('Pagi', dzikirPagiTime);
      scheduled++;
      print('✅ Dzikir Pagi: ${_formatTime(dzikirPagiTime)}');
    }
    
    if (enableDzikirPetang && prayerTimes.containsKey('Ashar')) {
      final dzikirPetangTime = _addMinutes(prayerTimes['Ashar']!, 30);
      await _scheduleDzikirNotification('Petang', dzikirPetangTime);
      scheduled++;
      print('✅ Dzikir Petang: ${_formatTime(dzikirPetangTime)}');
    }
    
    // Schedule tilawah with custom times
    if (enableTilawahPagi) {
      final pagiTime = tilawahTimes['Pagi'] ?? const TimeOfDay(hour: 6, minute: 0);
      await _scheduleTilawahNotification('Pagi', pagiTime);
      scheduled++;
      print('✅ Tilawah Pagi: ${_formatTime(pagiTime)}');
    }
    
    if (enableTilawahSiang) {
      final siangTime = tilawahTimes['Siang'] ?? const TimeOfDay(hour: 13, minute: 0);
      await _scheduleTilawahNotification('Siang', siangTime);
      scheduled++;
      print('✅ Tilawah Siang: ${_formatTime(siangTime)}');
    }
    
    if (enableTilawahMalam) {
      final malamTime = tilawahTimes['Malam'] ?? const TimeOfDay(hour: 20, minute: 0);
      await _scheduleTilawahNotification('Malam', malamTime);
      scheduled++;
      print('✅ Tilawah Malam: ${_formatTime(malamTime)}');
    }
    
    // Show pending notifications
    final pending = await _notifications.pendingNotificationRequests();
    
    print('');
    print('📊 Summary:');
    print('   Total scheduled: $scheduled');
    print('   Pending notifications: ${pending.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🕌 SCHEDULE INDIVIDUAL NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> _schedulePrayerNotification(String name, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduledTime = tz.TZDateTime(
      _userLocation!,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // If time passed, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    final payload = jsonEncode({
      'type': 'prayer',
      'name': name,
      'time': scheduledTime.toIso8601String(),
      'id': _notifIds[name],
    });
    
    await _notifications.zonedSchedule(
      _notifIds[name]!,
      '🕌 Waktu Sholat $name',
      'Saatnya menunaikan sholat $name - ${_getPrayerMessage(name)}',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelPrayer,
          'Waktu Sholat',
          channelDescription: 'Pengingat waktu sholat 5 waktu',
          importance: Importance.max, // ⭐ CRITICAL for popup
          priority: Priority.max, // ⭐ CRITICAL for popup
          playSound: !isSilent,
          enableVibration: !isSilent,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF059669),
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true, // ⭐ ENABLES POPUP
          visibility: NotificationVisibility.public,
          showWhen: true,
          styleInformation: BigTextStyleInformation(
            '🕌 Masuk waktu sholat $name\n\n${_getPrayerMessage(name)}',
            htmlFormatBigText: false,
            contentTitle: '🕌 Waktu Sholat $name',
            summaryText: _formatTime(time),
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    // ⭐ SAVE TO HISTORY for Notification Center
    await _saveToHistory(
      id: _notifIds[name]!.toString(),
      title: '🕌 Waktu Sholat $name',
      body: 'Saatnya menunaikan sholat $name',
      type: 'prayer',
      scheduledTime: scheduledTime,
    );
  }

  Future<void> _scheduleDzikirNotification(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduledTime = tz.TZDateTime(
      _userLocation!,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    final emoji = type == 'Pagi' ? '🌅' : '🌆';
    final id = type == 'Pagi' ? _notifIds['DzikirPagi']! : _notifIds['DzikirPetang']!;
    
    final payload = jsonEncode({
      'type': 'dzikir',
      'name': type,
      'time': scheduledTime.toIso8601String(),
      'id': id,
    });
    
    await _notifications.zonedSchedule(
      id,
      '$emoji Waktu Dzikir $type',
      'Saatnya membaca dzikir $type hari ini',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDzikir,
          'Dzikir Pagi & Petang',
          importance: Importance.high,
          priority: Priority.high,
          playSound: !isSilent,
          enableVibration: !isSilent,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF06B6D4),
          fullScreenIntent: true,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    await _saveToHistory(
      id: id.toString(),
      title: '$emoji Waktu Dzikir $type',
      body: 'Saatnya membaca dzikir $type hari ini',
      type: 'dzikir',
      scheduledTime: scheduledTime,
    );
  }

  Future<void> _scheduleTilawahNotification(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduledTime = tz.TZDateTime(
      _userLocation!,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    String emoji;
    int id;
    
    switch (type) {
      case 'Pagi':
        emoji = '📖';
        id = _notifIds['TilawahPagi']!;
        break;
      case 'Siang':
        emoji = '☀️';
        id = _notifIds['TilawahSiang']!;
        break;
      case 'Malam':
        emoji = '🌙';
        id = _notifIds['TilawahMalam']!;
        break;
      default:
        emoji = '📖';
        id = _notifIds['TilawahPagi']!;
    }
    
    final payload = jsonEncode({
      'type': 'tilawah',
      'name': type,
      'time': scheduledTime.toIso8601String(),
      'id': id,
    });
    
    await _notifications.zonedSchedule(
      id,
      '$emoji Waktu Tilawah $type',
      'Luangkan waktu untuk membaca Al-Quran',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelTilawah,
          'Tilawah Al-Quran',
          importance: Importance.high,
          priority: Priority.high,
          playSound: !isSilent,
          enableVibration: !isSilent,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF10B981),
          fullScreenIntent: true,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    await _saveToHistory(
      id: id.toString(),
      title: '$emoji Waktu Tilawah $type',
      body: 'Luangkan waktu untuk membaca Al-Quran',
      type: 'tilawah',
      scheduledTime: scheduledTime,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💾 NOTIFICATION HISTORY (for Notification Center)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> _saveToHistory({
    required String id,
    required String title,
    required String body,
    required String type,
    required tz.TZDateTime scheduledTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      
      List<Map<String, dynamic>> history = [];
      
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        history = decoded.map((e) => e as Map<String, dynamic>).toList();
      }
      
      // Add new notification
      history.add({
        'id': id,
        'title': title,
        'body': body,
        'type': _getTypeIndex(type),
        'timestamp': scheduledTime.millisecondsSinceEpoch,
        'isRead': false,
        'isScheduled': true,
      });
      
      // Keep only last 100 notifications
      if (history.length > 100) {
        history = history.sublist(history.length - 100);
      }
      
      await prefs.setString(_keyNotificationHistory, jsonEncode(history));
      
      // Update badge count
      await _updateBadgeCount();
      
    } catch (e) {
      print('⚠️ Error saving to history: $e');
    }
  }

  int _getTypeIndex(String type) {
    switch (type) {
      case 'prayer': return 5;
      case 'dzikir': return 6;
      case 'tilawah': return 7;
      default: return 9;
    }
  }

  Future<void> _updateBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      final readIdsJson = prefs.getString(_keyReadNotifications);
      
      if (historyJson == null) return;
      
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔔 NOTIFICATION CALLBACKS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void _onNotificationResponse(NotificationResponse response) async {
    print('🔔 Notification tapped (foreground): ${response.id}');
    await _handleNotificationTap(response);
  }
  
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    print('🔔 Notification tapped (background): ${response.id}');
    // Handle background tap
  }
  
  Future<void> _handleNotificationTap(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;
    
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      // Mark as read
      final prefs = await SharedPreferences.getInstance();
      final readIdsJson = prefs.getString(_keyReadNotifications);
      
      Set<String> readIds = {};
      if (readIdsJson != null) {
        final List<dynamic> readList = jsonDecode(readIdsJson);
        readIds = readList.map((e) => e.toString()).toSet();
      }
      
      readIds.add(data['id'].toString());
      await prefs.setString(_keyReadNotifications, jsonEncode(readIds.toList()));
      
      // Update badge
      await _updateBadgeCount();
      
      // Notify listeners
      onNotificationTapped?.call(data['type'] ?? '', data);
      
    } catch (e) {
      print('⚠️ Error handling tap: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🧪 TEST NOTIFICATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> testNotification() async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🧪 TESTING NOTIFICATION SYSTEM');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSilent = prefs.getBool('notification_silent_mode') ?? false;
      
      final now = tz.TZDateTime.now(_userLocation ?? tz.local);
      print('Current time: ${_formatDateTime(now)}');
      
      // Immediate notification with FULL SCREEN
      await _notifications.show(
        _notifIds['Test']!,
        '✅ Assalamualaikum!',
        'Sistem notifikasi berfungsi dengan baik! Notifikasi akan muncul seperti ini.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelTest,
            'Notifications',
            channelDescription: 'For testing',
            importance: Importance.max, // ⭐ MAX for popup
            priority: Priority.max, // ⭐ MAX for popup
            playSound: !isSilent,
            enableVibration: !isSilent,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF059669),
            fullScreenIntent: true, // ⭐ ENABLES POPUP
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            showWhen: true,
            styleInformation: BigTextStyleInformation(
              'Alhamdulillah! Sistem notifikasi Bekal Muslim sudah siap.\n\n'
              'Notifikasi waktu sholat akan muncul seperti ini dengan popup penuh.\n\n'
              'Timezone: ${_userLocation?.name ?? "Unknown"}\n'
              'Waktu: ${_formatDateTime(now)}',
              contentTitle: '✅Notification Berhasil!',
              summaryText: 'Bekal Muslim',
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: !isSilent,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
      
      print('✅ Immediate notification sent');
      
      // Scheduled test (5 seconds)
      final scheduledTime = now.add(const Duration(seconds: 5));
      print('Scheduling test for: ${_formatDateTime(scheduledTime)}');
      
      await _notifications.zonedSchedule(
        _notifIds['Test']! + 1,
        '⏰ Scheduled',
        'Notifikasi terjadwal berhasil! (5 detik kemudian)',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelTest,
            'Notifications',
            importance: Importance.max,
            priority: Priority.max,
            playSound: !isSilent,
            enableVibration: !isSilent,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF3B82F6),
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: !isSilent,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Scheduled notification set');
      
      // Show pending count
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Total pending: ${pending.length} notifications');
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ TEST COMPLETE');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
    } catch (e, stackTrace) {
      print('❌ TEST FAILED: $e');
      print('Stack: $stackTrace');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🛠️ UTILITY METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ All notifications cancelled');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  String _getPrayerMessage(String name) {
    switch (name) {
      case 'Subuh': return 'Sholat Subuh adalah cahaya hari ini';
      case 'Dzuhur': return 'Luangkan waktu sejenak untuk sholat';
      case 'Ashar': return 'Jangan lewatkan waktu yang mulia ini';
      case 'Maghrib': return 'Akhiri hari dengan sholat yang khusyuk';
      case 'Isya': return 'Tutup hari dengan ibadah';
      default: return 'Sholat adalah tiang agama';
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(tz.TZDateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}