// notification/notification_manager.dart - v19.0 COMPLETE PRAYER NOTIFICATIONS
// ✅ ALL PRAYER TIMES: Tahajud, Subuh, Duha, Dzuhur, Ashar, Maghrib, Isya
// ✅ Works even when app is closed (background scheduling)
// ✅ Smart quotes for each prayer time
// ✅ Full-screen notification support
// ✅ Auto-reschedule at midnight

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myquran/notification/notification_service.dart';
import 'package:myquran/quran/service/quran_service.dart';
import 'package:myquran/util/navigator_key.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final QuranService _quranService = QuranService();
  final Random _random = Random();
  
  bool _isInitialized = false;
  tz.Location? _userLocation;
  Timer? _midnightRescheduleTimer;  
  
  static const String _keyPrayerStats = 'prayer_statistics';

  static Function(BuildContext context, String type, Map<String, dynamic> data)? onNotificationTappedWithContext;
  static Function(String type, Map<String, dynamic> data)? onNotificationTapped;
  
  static const String _channelPrayer = 'prayer_critical_v10';
  static const String _channelDzikir = 'dzikir_critical_v10';
  static const String _channelTilawah = 'tilawah_critical_v10';
  static const String _channelDoa = 'doa_critical_v10';
  
  static const String _keyNotificationHistory = 'notification_history_v3';
  static const String _keyReadNotifications = 'read_notifications_v2';
  static const String _keyBadgeCount = 'notification_badge_count';
  
  // ✅ UPDATED: Notification IDs for ALL prayer times
  static const Map<String, int> _notifIds = {
    // Prayer times (ALL 7 times)
    'Tahajud': 1000,    // ✅ NEW
    'Subuh': 1001,
    'Duha': 1002,       // ✅ NEW
    'Dzuhur': 1003,
    'Ashar': 1004,
    'Maghrib': 1005,
    'Isya': 1006,
    
    // Other notifications
    'DzikirPagi': 2001,
    'DzikirPetang': 2002,
    'TilawahPagi': 3001,
    'TilawahSiang': 3002,
    'TilawahMalam': 3003,
    'DoaPagi': 4001,
    'DoaPetang': 4002,
  };

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💬 MOTIVATIONAL QUOTES - SPECIFIC FOR EACH PRAYER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  // ✅ TAHAJUD QUOTES (NEW - 15 quotes)
  static final List<String> _tahajudQuotes = [
    'Tahajud waktu paling mustajab',
    'Allah turun di sepertiga malam',
    'Tahajud kunci kesuksesan dunia akhirat',
    'Bangun tahajud, bangun keberkahan',
    'Tahajud sholat para nabi',
    'Malam tenang, doa dikabulkan',
    'Tahajud investasi terbesar',
    'Waktu spesial berdialog dengan Allah',
    'Tahajud menghapus dosa-dosa',
    'Bangun tahajud, dibuka pintu surga',
    'Tahajud amalan orang-orang sholeh',
    'Sepertiga malam penuh rahmat',
    'Tahajud benteng dari maksiat',
    'Waktu malaikat turun ke langit dunia',
    'Tahajud kunci pintu rezeki',
  ];

  // 🌅 SUBUH QUOTES (20 quotes)
  static final List<String> _subuhQuotes = [
    'Sholat Subuh cahaya seharian',
    'Bangun Subuh, bangun berkah',
    'Rezeki menanti yang sholat Subuh',
    'Subuh waktu berdoa mustajab',
    'Subuh tanda cinta kepada Allah',
    'Sholat Subuh dalam lindungan Allah',
    'Subuh awal kesuksesan hari ini',
    'Subuh investasi terbaik pagi',
    'Kemuliaan Subuh tak terulang',
    'Subuh waktu meminta kepada Allah',
    'Jaga Subuh, dijaga Allah',
    'Berkah waktu Subuh sangat istimewa',
    'Subuh membuka pintu rezeki',
    'Subuh janji setia kepada Allah',
    'Hari dimulai berkah dengan Subuh',
    'Subuh kunci kebahagiaan pagi',
    'Subuh waktu malaikat turun',
    'Subuh momentum bertemu Allah',
    'Pagi semangat dimulai Subuh',
    'Subuh waktu terbaik memulai',
  ];

  // ✅ DUHA QUOTES (NEW - 15 quotes)
  static final List<String> _duhaQuotes = [
    'Duha sholat pembuka rezeki',
    'Duha amalan pengganti sedekah',
    'Sholat Duha sunnah yang mulia',
    'Duha waktu dikabulkan doa',
    'Luangkan waktu untuk Duha',
    'Duha membawa keberkahan pagi',
    'Sholat Duha mencukupkan kebutuhan',
    'Duha kunci pintu rezeki',
    'Waktu istimewa di pagi hari',
    'Duha sholat para dermawan',
    'Pagi produktif dengan Duha',
    'Duha menghapus kesalahan',
    'Sholat Duha bentuk syukur pagi',
    'Duha waktu penuh berkah',
    'Rezeki berlimpah dengan Duha',
  ];

  // ☀️ DZUHUR QUOTES (15 quotes)
  static final List<String> _dzuhurQuotes = [
    'Istirahat sejenak untuk Dzuhur',
    'Dzuhur menyegarkan iman',
    'Luangkan waktu untuk Dzuhur',
    'Dzuhur membawa berkah siang',
    'Dzuhur recharge spiritual',
    'Dzuhur bentuk syukur tengah hari',
    'Dzuhur ketenangan di kesibukan',
    'Dzuhur istirahat terbaik',
    'Dzuhur kembali kepada Allah',
    'Dzuhur keberkahan siang',
    'Dzuhur jeda penuh makna',
    'Siang produktif dimulai Dzuhur',
    'Dzuhur prioritas utama',
    'Dzuhur reset mental',
    'Tepat waktu, urusan dimudahkan',
  ];

  // 🌤️ ASHAR QUOTES (15 quotes)
  static final List<String> _asharQuotes = [
    'Ashar waktu yang mulia',
    'Ashar bekal menjelang sore',
    'Ashar waktu malaikat berganti',
    'Tepat waktu, hidup teratur',
    'Ashar tanda ketakwaan',
    'Ashar kedamaian sore',
    'Ashar cahaya sore hari',
    'Ashar mustajab untuk berdoa',
    'Ashar bentuk syukur sore',
    'Ashar berkah menjelang malam',
    'Ashar waktu emas',
    'Ashar prioritas sore',
    'Ashar kembali kepada Allah',
    'Sore berkah dimulai Ashar',
    'Ashar ketenangan jiwa',
  ];

  // 🌆 MAGHRIB QUOTES (15 quotes)
  static final List<String> _maghribQuotes = [
    'Maghrib menutup aktivitas siang',
    'Maghrib waktu paling indah',
    'Maghrib keluarga berkumpul',
    'Maghrib waktu singkat, jangan lewat',
    'Maghrib awal malam berkah',
    'Maghrib kedamaian penghujung hari',
    'Maghrib syukur atas hari ini',
    'Maghrib berkumpul keluarga',
    'Malam dimulai berkah Maghrib',
    'Maghrib prioritas sore',
    'Maghrib moment istimewa',
    'Maghrib ketenangan malam',
    'Maghrib sangat berharga',
    'Maghrib penutup hari yang baik',
    'Maghrib waktu refleksi diri',
  ];

  // 🌙 ISYA QUOTES (15 quotes)
  static final List<String> _isyaQuotes = [
    'Isya penutup hari dengan ibadah',
    'Isya bekal tidur nyenyak',
    'Isya ketenangan malam',
    'Isya tidur lebih berkah',
    'Isya bentuk syukur malam',
    'Isya menutup hari',
    'Isya mimpi yang indah',
    'Isya malaikat mencatat amal',
    'Tepat waktu, malam tenang',
    'Isya prioritas malam',
    'Isya moment terakhir hari ini',
    'Isya penutup amal hari ini',
    'Isya kedamaian sebelum tidur',
    'Tidur dalam lindungan Allah',
    'Isya kunci malam tenang',
  ];

  // 📖 TILAWAH QUOTES
  static final List<String> _tilawahQuotesMorning = [
    'Mulai hari dengan cahaya Al-Qur\'an',
    'Pagi berkah dimulai tilawah',
    'Segarkan jiwa dengan ayat suci',
    'Al-Qur\'an energi pagi sejati',
    'Tilawah pagi menenangkan hati',
  ];
  
  static final List<String> _tilawahQuotesAfternoon = [
    'Sempatkan tilawah di siang hari',
    'Istirahat sejenak dengan Al-Qur\'an',
    'Recharge spiritual siang hari',
    'Tilawah siang menyegarkan iman',
  ];
  
  static final List<String> _tilawahQuotesEvening = [
    'Tutup hari dengan Al-Qur\'an',
    'Malam tenang dengan tilawah',
    'Akhiri hari dengan cahaya ilahi',
    'Tilawah malam berkah istimewa',
  ];

  // 🤲 DZIKIR QUOTES
  static final List<String> _dzikirQuotesMorning = [
    'Dzikir pagi melindungi seharian',
    'Mulai dengan mengingat Allah',
    'Pagi berkah dengan dzikir',
    'Dzikir benteng dari keburukan',
  ];
  
  static final List<String> _dzikirQuotesEvening = [
    'Dzikir petang benteng malam',
    'Akhiri hari mengingat Allah',
    'Perlindungan malam dari dzikir',
    'Dzikir petang kedamaian jiwa',
  ];

  // 🤲 DOA QUOTES
  static final List<String> _doaQuotesMorning = [
    'Minta kepada Allah di pagi hari',
    'Doa pagi mengantarkan kesuksesan',
    'Pagi berkah dengan berdoa',
    'Awali hari dengan doa',
  ];
  
  static final List<String> _doaQuotesEvening = [
    'Syukuri hari ini dengan doa',
    'Minta ampun di penghujung hari',
    'Doa petang ketenangan jiwa',
    'Tutup hari dengan berdoa',
  ];

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 HELPER METHODS FOR QUOTES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  String getRandomPrayerQuote(String prayerName) {
    List<String> quotes = [];
    
    switch (prayerName.toLowerCase()) {
      case 'tahajud':
        quotes = _tahajudQuotes;
        break;
      case 'subuh':
        quotes = _subuhQuotes;
        break;
      case 'duha':
        quotes = _duhaQuotes;
        break;
      case 'dzuhur':
        quotes = _dzuhurQuotes;
        break;
      case 'ashar':
        quotes = _asharQuotes;
        break;
      case 'maghrib':
        quotes = _maghribQuotes;
        break;
      case 'isya':
        quotes = _isyaQuotes;
        break;
      default:
        quotes = _subuhQuotes; // fallback
    }
    
    return quotes[_random.nextInt(quotes.length)];
  }

  String getContextAwareQuote(String type, String timeOfDay) {
    List<String> quotes = [];
    
    if (type == 'tilawah') {
      if (timeOfDay == 'Pagi') quotes = _tilawahQuotesMorning;
      else if (timeOfDay == 'Siang') quotes = _tilawahQuotesAfternoon;
      else quotes = _tilawahQuotesEvening;
    } else if (type == 'dzikir') {
      quotes = timeOfDay == 'Pagi' ? _dzikirQuotesMorning : _dzikirQuotesEvening;
    } else if (type == 'doa') {
      quotes = timeOfDay == 'Pagi' ? _doaQuotesMorning : _doaQuotesEvening;
    }
    
    return quotes.isNotEmpty ? quotes[_random.nextInt(quotes.length)] : '';
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 INITIALIZATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🧠 Notification Manager v19.0 - COMPLETE PRAYER SYSTEM');
    debugPrint('   ✅ ALL 7 Prayer Times: Tahajud, Subuh, Duha, Dzuhur, Ashar, Maghrib, Isya');
    debugPrint('   ✅ Background scheduling (works when app closed)');
    debugPrint('   ✅ Smart quotes for each prayer');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      await _initializeTimezone();
      await _initializePlugin();
      if (Platform.isAndroid) await _createCriticalChannels();
      
      final hasPerms = await ensurePermissions();
      
      if (!hasPerms) {
        debugPrint('❌ Permissions denied');
        return false;
      }
      
      _setupMidnightReschedule();
      
      _isInitialized = true;
      debugPrint('✅ Notification System Ready');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('');
      return true;
    } catch (e, stack) {
      debugPrint('❌ Init failed: $e\n$stack');
      return false;
    }
  }

  Future<bool> hasRequiredPermissions() async {
    try {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) return false;
      
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final canSchedule = await androidPlugin.canScheduleExactNotifications() ?? false;
          if (!canSchedule) return false;
        }
        
        final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
        if (!batteryStatus.isGranted) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ensurePermissions() async {
    final hasPermissions = await hasRequiredPermissions();
    
    if (hasPermissions) {
      debugPrint('✅ All permissions already granted');
      return true;
    }
    
    debugPrint('⚠️ Missing permissions, requesting...');
    final result = await requestPermissions();
    
    return result['notification'] == true;
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();
    final savedTz = prefs.getString('user_timezone') ?? 'Asia/Makassar';
    _userLocation = tz.getLocation(savedTz);
    tz.setLocalLocation(_userLocation!);
    debugPrint('📍 Timezone: $savedTz');
  }

  Future<void> _initializePlugin() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _notifications.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onDidReceiveNotification,
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveNotification,
    );

    debugPrint('✅ Notification plugin initialized');
  }

  @pragma('vm:entry-point')
  static Future<void> _onDidReceiveNotification(NotificationResponse response) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔔 NOTIFICATION RECEIVED');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      if (response.payload == null) {
        debugPrint('⚠️ No payload found');
        return;
      }
      
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      
      debugPrint('📋 Data: ${data['title']}');
      
      await _saveNotificationToHistory(data);
      await _forceUpdateBadgeCount();
      
      final prayerName = data['name'] as String?;
      if (prayerName != null && data['type'] == 'prayer') {
        await NotificationManager()._trackPrayerInteraction(prayerName);
      }
      
      debugPrint('✅ Processed successfully\n');
      
    } catch (e, stack) {
      debugPrint('❌ Error: $e');
      debugPrint('Stack: $stack');
    }
  }

  static Future<void> _saveNotificationToHistory(Map<String, dynamic> data, {bool isScheduled = false, int? scheduledTime}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      
      List<Map<String, dynamic>> history = [];
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson) as List<dynamic>;
        history = decoded.cast<Map<String, dynamic>>();
      }
      
      final notifId = data['id'] as String;
      final existingIndex = history.indexWhere((item) => item['id'] == notifId);
      
      final timeToUse = scheduledTime ?? DateTime.now().millisecondsSinceEpoch;

      if (existingIndex != -1) {
        history[existingIndex] = {
          ...history[existingIndex],
          'isScheduled': isScheduled,
          'timestamp': timeToUse,
          'isRead': false,
        };
      } else {
        final notificationData = {
          'id': notifId,
          'title': data['title'] ?? 'Notifikasi',
          'body': data['body'] ?? '',
          'type': data['notifType'] ?? 9,
          'timestamp': timeToUse,
          'isRead': false,
          'isScheduled': isScheduled,
        };
        
        history.add(notificationData);
      }
      
      history.sort((a, b) {
        final aTime = a['timestamp'] as int? ?? 0;
        final bTime = b['timestamp'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });
      
      if (history.length > 200) {
        history = history.sublist(0, 200);
      }
      
      await prefs.setString(_keyNotificationHistory, jsonEncode(history));
      
      debugPrint('   📊 History: ${history.length} total');
      
    } catch (e, stack) {
      debugPrint('   ❌ Save error: $e');
    }
  }

  static Future<void> checkFiredScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      if (historyJson == null) return;
      
      final List<dynamic> decoded = jsonDecode(historyJson);
      List<Map<String, dynamic>> history = decoded.cast<Map<String, dynamic>>();
      
      bool changed = false;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (var item in history) {
        if (item['isScheduled'] == true) {
          final timestamp = item['timestamp'] as int? ?? 0;
          if (timestamp <= now) {
            item['isScheduled'] = false;
            changed = true;
          }
        }
      }
      
      if (changed) {
        await prefs.setString(_keyNotificationHistory, jsonEncode(history));
        debugPrint('   🔄 Auto-fired scheduled notifications updated in history');
      }
    } catch (e) {
      debugPrint('   ❌ Error checking fired notifications: $e');
    }
  }

  static Future<void> _forceUpdateBadgeCount() async {
    try {
      await checkFiredScheduledNotifications(); // Check if any scheduled notification fired
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
        final id = item['id'].toString();
        
        if (!isScheduled && !readIds.contains(id)) {
          unreadCount++;
        }
      }
      
      await prefs.setInt(_keyBadgeCount, unreadCount);
      NotificationService.badgeCount.value = unreadCount;
      
      debugPrint('   🔢 Badge: $unreadCount');
      
    } catch (e) {
      debugPrint('   ❌ Badge error: $e');
    }
  }

  Future<void> _trackPrayerInteraction(String prayerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('prayer_statistics');
      
      Map<String, dynamic> stats = {};
      if (statsJson != null) {
        stats = jsonDecode(statsJson) as Map<String, dynamic>;
      }
      
      final key = 'notif_${prayerName.toLowerCase()}_count';
      stats[key] = (stats[key] as int? ?? 0) + 1;
      
      stats['last_${prayerName.toLowerCase()}'] = DateTime.now().toIso8601String();
      
      await prefs.setString('prayer_statistics', jsonEncode(stats));
      
    } catch (e) {
      debugPrint('   ⚠️ Track error: $e');
    }
  }

  Future<void> _createCriticalChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelPrayer, 'Adzan & Waktu Sholat',
        description: 'Notifikasi waktu sholat dengan prioritas tinggi',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 500, 200, 500]),
        showBadge: true,
      ),
    );
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelDzikir, 'Pengingat Dzikir',
        description: 'Dzikir pagi dan petang',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 300, 200, 300]),
        ledColor: const Color(0xFF06B6D4),
      ),
    );
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelTilawah, 'Pengingat Tilawah',
        description: 'Waktu membaca Al-Quran',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 400, 100, 400]),
        ledColor: const Color(0xFF10B981),
      ),
    );
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelDoa, 'Pengingat Doa',
        description: 'Pengingat untuk berdoa',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 350, 150, 350]),
        ledColor: const Color(0xFFA855F7),
      ),
    );
    
    debugPrint('✅ Channels created');
  }

  Future<Map<String, bool>> requestPermissions() async {
    debugPrint('🔐 Requesting permissions...');
    
    final result = <String, bool>{
      'notification': false,
      'exactAlarm': false,
      'batteryOptimization': false,
    };
    
    var status = await Permission.notification.request();
    result['notification'] = status.isGranted;
    
    if (!status.isGranted) {
      debugPrint('❌ Notification denied');
      return result;
    }
    
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        try {
          final canSchedule = await androidPlugin.canScheduleExactNotifications() ?? false;
          
          if (!canSchedule) {
            await androidPlugin.requestExactAlarmsPermission();
            final canNow = await androidPlugin.canScheduleExactNotifications() ?? false;
            result['exactAlarm'] = canNow;
          } else {
            result['exactAlarm'] = true;
          }
        } catch (e) {
          debugPrint('⚠️ Exact alarm error: $e');
        }
      }
      
      try {
        status = await Permission.ignoreBatteryOptimizations.status;
        
        if (!status.isGranted) {
          final granted = await Permission.ignoreBatteryOptimizations.request();
          result['batteryOptimization'] = granted.isGranted;
        } else {
          result['batteryOptimization'] = true;
        }
      } catch (e) {
        debugPrint('⚠️ Battery opt unavailable');
      }
    }
    
    return result;
  }

  void _setupMidnightReschedule() {
    _midnightRescheduleTimer?.cancel();
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 1);
    final duration = tomorrow.difference(now);
    
    debugPrint('⏰ Auto-reschedule: ${tomorrow.hour}:${tomorrow.minute}');
    
    _midnightRescheduleTimer = Timer(duration, () async {
      debugPrint('\n🌙 MIDNIGHT AUTO-RESCHEDULE');
      _setupMidnightReschedule();
    });
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    NotificationManager()._handleNotificationTap(response);
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    if (response.payload == null) return;
    
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final type = data['type'] as String? ?? 'unknown';
      
      onNotificationTapped?.call(type, data);
      
      if (onNotificationTappedWithContext != null) {
        try {
          final BuildContext? context = navigatorKey.currentContext;
          if (context != null) {
            onNotificationTappedWithContext?.call(context, type, data);
          }
        } catch (e) {
          debugPrint('⚠️ Context error: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Tap error: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📅 SCHEDULING METHODS - COMPLETE FOR ALL PRAYERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> scheduleAllNotifications({
    required Map<String, TimeOfDay> prayerTimes,
    Map<String, bool>? enabledPrayers,
    required Map<String, TimeOfDay> tilawahTimes,
    Map<String, TimeOfDay>? doaTimes,
  }) async {
    debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🧠 COMPLETE PRAYER SCHEDULING v19.0');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      await cancelAllNotifications();
      
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      
      debugPrint('\n📍 Context: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
      
      // ✅ Get enabled status for ALL prayer times
      final enabled = enabledPrayers ?? {
        'Tahajud': prefs.getBool('notif_enable_tahajud') ?? true,
        'Subuh': prefs.getBool('notif_enable_subuh') ?? true,
        'Duha': prefs.getBool('notif_enable_duha') ?? true,
        'Dzuhur': prefs.getBool('notif_enable_dzuhur') ?? true,
        'Ashar': prefs.getBool('notif_enable_ashar') ?? true,
        'Maghrib': prefs.getBool('notif_enable_maghrib') ?? true,
        'Isya': prefs.getBool('notif_enable_isya') ?? true,
      };
      
      int scheduled = 0;
      int skipped = 0;
      
      // ✅ Schedule ALL PRAYER NOTIFICATIONS
      debugPrint('\n1️⃣ PRAYER TIMES (ALL 7 TIMES):');
      
      // ✅ List of ALL prayer times (excluding Syuruk - not a prayer time)
      final allPrayers = ['Tahajud', 'Subuh', 'Duha', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
      
      for (final prayerName in allPrayers) {
        final prayerTime = prayerTimes[prayerName];
        
        if (prayerTime == null) {
          debugPrint('   ⚠️  $prayerName: time not available');
          continue;
        }
        
        if (enabled[prayerName] == true) {
          var prayerMinutes = prayerTime.hour * 60 + prayerTime.minute;
          
          // ✅ Special handling for Tahajud (after midnight)
          if (prayerName == 'Tahajud') {
            // Tahajud is early morning (e.g., 02:00)
            // If current time is after midnight (00:00-05:59) and before Tahajud
            if (now.hour < 6) {
              if (currentMinutes < prayerMinutes) {
                // Schedule for today
                try {
                  await _schedulePrayerSmart(prayerName, prayerTime, prayerTimes);
                  scheduled++;
                  final remaining = prayerMinutes - currentMinutes;
                  debugPrint('   ✅ $prayerName: ${_fmt(prayerTime)} (+${remaining}m)');
                } catch (e) {
                  debugPrint('   ❌ $prayerName: $e');
                }
              } else {
                skipped++;
                debugPrint('   ⏭️  $prayerName: ${_fmt(prayerTime)} (passed)');
              }
            } else {
              // Current time is daytime/evening, schedule Tahajud for tomorrow
              try {
                await _schedulePrayerSmart(prayerName, prayerTime, prayerTimes);
                scheduled++;
                final minutesUntilMidnight = (24 * 60) - currentMinutes;
                final totalMinutes = minutesUntilMidnight + prayerMinutes;
                debugPrint('   ✅ $prayerName: ${_fmt(prayerTime)} (+${totalMinutes}m - tomorrow)');
              } catch (e) {
                debugPrint('   ❌ $prayerName: $e');
              }
            }
          } else {
            // Regular prayer times
            if (prayerMinutes > currentMinutes) {
              try {
                await _schedulePrayerSmart(prayerName, prayerTime, prayerTimes);
                scheduled++;
                final remaining = prayerMinutes - currentMinutes;
                debugPrint('   ✅ $prayerName: ${_fmt(prayerTime)} (+${remaining}m)');
              } catch (e) {
                debugPrint('   ❌ $prayerName: $e');
              }
            } else {
              skipped++;
              debugPrint('   ⏭️  $prayerName: ${_fmt(prayerTime)} (passed)');
            }
          }
        } else {
          debugPrint('   🔕 $prayerName: disabled');
        }
      }
      
      // Dzikir
      debugPrint('\n2️⃣ DZIKIR:');
      if (prefs.getBool('notif_enable_dzikir_pagi') ?? true) {
        final subuhTime = prayerTimes['Subuh'];
        if (subuhTime != null) {
          final time = _addMin(subuhTime, 30);
          final dzikirMinutes = time.hour * 60 + time.minute;
          
          if (dzikirMinutes > currentMinutes) {
            try {
              await _scheduleDzikirSmart('Pagi', time);
              scheduled++;
              debugPrint('   ✅ Pagi: ${_fmt(time)}');
            } catch (e) {
              debugPrint('   ❌ Pagi: $e');
            }
          } else {
            skipped++;
          }
        }
      }
      
      if (prefs.getBool('notif_enable_dzikir_petang') ?? true) {
        final asharTime = prayerTimes['Ashar'];
        if (asharTime != null) {
          final time = _addMin(asharTime, 30);
          final dzikirMinutes = time.hour * 60 + time.minute;
          
          if (dzikirMinutes > currentMinutes) {
            try {
              await _scheduleDzikirSmart('Petang', time);
              scheduled++;
              debugPrint('   ✅ Petang: ${_fmt(time)}');
            } catch (e) {
              debugPrint('   ❌ Petang: $e');
            }
          } else {
            skipped++;
          }
        }
      }
      
      // Tilawah
      debugPrint('\n3️⃣ TILAWAH:');
      final tilawahSchedule = [
        ('Pagi', 'notif_enable_tilawah_pagi', true),
        ('Siang', 'notif_enable_tilawah_siang', false),
        ('Malam', 'notif_enable_tilawah_malam', true),
      ];
      
      for (var (type, prefKey, defaultEnabled) in tilawahSchedule) {
        if (prefs.getBool(prefKey) ?? defaultEnabled) {
          final time = tilawahTimes[type];
          if (time != null) {
            final tilawahMinutes = time.hour * 60 + time.minute;
            
            if (tilawahMinutes > currentMinutes) {
              try {
                await _scheduleTilawahSmart(type, time);
                scheduled++;
                debugPrint('   ✅ $type: ${_fmt(time)}');
              } catch (e) {
                debugPrint('   ❌ $type: $e');
              }
            } else {
              skipped++;
            }
          }
        }
      }
      
      // Doa
      debugPrint('\n4️⃣ DOA:');
      if (prefs.getBool('notif_enable_doa_pagi') ?? true) {
        final subuhTime = prayerTimes['Subuh'];
        if (subuhTime != null) {
          final time = doaTimes?['Pagi'] ?? _addMin(subuhTime, 15);
          final doaMinutes = time.hour * 60 + time.minute;
          
          if (doaMinutes > currentMinutes) {
            try {
              await _scheduleDoaSmart('Pagi', time);
              scheduled++;
              debugPrint('   ✅ Pagi: ${_fmt(time)}');
            } catch (e) {
              debugPrint('   ❌ Pagi: $e');
            }
          } else {
            skipped++;
          }
        }
      }
      
      if (prefs.getBool('notif_enable_doa_petang') ?? true) {
        final maghribTime = prayerTimes['Maghrib'];
        if (maghribTime != null) {
          final time = doaTimes?['Petang'] ?? _addMin(maghribTime, 10);
          final doaMinutes = time.hour * 60 + time.minute;
          
          if (doaMinutes > currentMinutes) {
            try {
              await _scheduleDoaSmart('Petang', time);
              scheduled++;
              debugPrint('   ✅ Petang: ${_fmt(time)}');
            } catch (e) {
              debugPrint('   ❌ Petang: $e');
            }
          } else {
            skipped++;
          }
        }
      }
      
      final pending = await _notifications.pendingNotificationRequests();
      debugPrint('\n📊 Summary:');
      debugPrint('   ✅ Scheduled: $scheduled');
      debugPrint('   ⏭️  Skipped: $skipped');
      debugPrint('   📋 Pending: ${pending.length}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
    } catch (e, stack) {
      debugPrint('❌ Fatal: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  // ✅ Smart Prayer Scheduling - Works for ALL prayer times
  Future<void> _schedulePrayerSmart(
    String name, 
    TimeOfDay time, 
    Map<String, TimeOfDay> allPrayerTimes,
  ) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    final motivationalQuote = getRandomPrayerQuote(name);
    
    // ✅ Emoji untuk setiap waktu sholat
    String emoji = '🕌';
    switch (name) {
      case 'Tahajud': emoji = '🌙'; break;
      case 'Subuh': emoji = '🌅'; break;
      case 'Duha': emoji = '☀️'; break;
      case 'Dzuhur': emoji = '🌞'; break;
      case 'Ashar': emoji = '🌤️'; break;
      case 'Maghrib': emoji = '🌆'; break;
      case 'Isya': emoji = '🌃'; break;
    }
    
    final title = '$emoji Waktu Sholat $name';
    final body = motivationalQuote;
    final id = '${name}_${scheduled.millisecondsSinceEpoch}';
    
    final payload = jsonEncode({
      'id': id,
      'type': 'prayer',
      'name': name,
      'time': scheduled.toIso8601String(),
      'title': title,
      'body': body,
      'motivationalQuote': motivationalQuote,
      'notifType': _getNotificationTypeIndex(name),
    });

    await _saveNotificationToHistory(
      jsonDecode(payload),
      isScheduled: true,
      scheduledTime: scheduled.millisecondsSinceEpoch,
    );
    
    await _notifications.zonedSchedule(
      _notifIds[name]!,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelPrayer, 
          'Adzan & Waktu Sholat',
          importance: Importance.max, 
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: !isSilent,
          sound: isSilent ? null : const RawResourceAndroidNotificationSound('adzan'),
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          icon: '@mipmap/ic_launcher', 
          color: const Color(0xFF059669),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'Bekal Muslim',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
          sound: 'adzan.wav',
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleDzikirSmart(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    final emoji = type == 'Pagi' ? '🌅' : '🌆';
    final quote = getContextAwareQuote('dzikir', type);
    
    final title = '$emoji Waktu Dzikir $type';
    final id = 'Dzikir${type}_${scheduled.millisecondsSinceEpoch}';
    
    final payload = jsonEncode({'id': id, 'type': 'dzikir', 'name': type, 'title': title, 'body': quote, 'notifType': 7});
    await _saveNotificationToHistory(
      jsonDecode(payload),
      isScheduled: true,
      scheduledTime: scheduled.millisecondsSinceEpoch,
    );
    
    await _notifications.zonedSchedule(
      type == 'Pagi' ? _notifIds['DzikirPagi']! : _notifIds['DzikirPetang']!,
      title,
      quote,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDzikir,
          'Pengingat Dzikir',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: !isSilent,
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF06B6D4),
          styleInformation: BigTextStyleInformation(quote, contentTitle: title),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleTilawahSmart(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    final lastRead = await _quranService.getLastRead();
    final lastReadText = lastRead != null 
        ? 'Lanjutkan: ${lastRead.surahName} Ayat ${lastRead.ayahNumber}'
        : 'Mulai Tilawah Al-Qur\'an';
    
    final quote = getContextAwareQuote('tilawah', type);
    
    String emoji = type == 'Pagi' ? '📖' : type == 'Siang' ? '☀️' : '🌙';
    final title = '$emoji Tilawah $type';
    final body = '$lastReadText\n\n$quote';
    final id = 'Tilawah${type}_${scheduled.millisecondsSinceEpoch}';
    
    final notifId = type == 'Pagi' ? _notifIds['TilawahPagi']! 
        : type == 'Siang' ? _notifIds['TilawahSiang']! 
        : _notifIds['TilawahMalam']!;
    
    final payload = jsonEncode({'id': id, 'type': 'tilawah', 'name': type, 'title': title, 'body': body, 'lastRead': lastRead?.toJson(), 'notifType': 8});
    await _saveNotificationToHistory(
      jsonDecode(payload),
      isScheduled: true,
      scheduledTime: scheduled.millisecondsSinceEpoch,
    );
    
    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelTilawah,
          'Pengingat Tilawah',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: !isSilent,
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 400, 100, 400]),
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF10B981),
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleDoaSmart(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    
    final quote = getContextAwareQuote('doa', type);
    final emoji = type == 'Pagi' ? '🤲' : '🌟';
    final title = '$emoji Waktu Doa $type';
    final id = 'Doa${type}_${scheduled.millisecondsSinceEpoch}';
    
    final payload = jsonEncode({'id': id, 'type': 'doa', 'name': type, 'title': title, 'body': quote, 'notifType': 10});
    await _saveNotificationToHistory(
      jsonDecode(payload),
      isScheduled: true,
      scheduledTime: scheduled.millisecondsSinceEpoch,
    );
    
    await _notifications.zonedSchedule(
      type == 'Pagi' ? _notifIds['DoaPagi']! : _notifIds['DoaPetang']!,
      title,
      quote,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDoa,
          'Pengingat Doa',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: !isSilent,
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 350, 150, 350]),
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFA855F7),
          styleInformation: BigTextStyleInformation(quote, contentTitle: title),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🛠️ HELPER METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  int _getNotificationTypeIndex(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'tahajud': return 10;   // ✅ FIXED
      case 'subuh': return 0;
      case 'duha': return 11;      // ✅ FIXED
      case 'dzuhur': return 1;
      case 'ashar': return 2;
      case 'maghrib': return 3;
      case 'isya': return 4;
      default: return 5;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ All notifications cancelled');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  String _fmt(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  TimeOfDay _addMin(TimeOfDay time, int minutes) {
    final total = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  void dispose() {
    _midnightRescheduleTimer?.cancel();
  }
}
// navigatorKey didefinisikan di lib/util/navigator_key.dart
// dan di-import di atas.