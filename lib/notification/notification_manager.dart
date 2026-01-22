// notification/notification_manager.dart - v13.0 WITH MOTIVATIONAL QUOTES
// ✅ Random motivational quotes untuk Tilawah, Dzikir, Doa
// ✅ Tetap pertahankan "Lanjutkan Tilawah Terakhir"
// ✅ Auto popup seperti WhatsApp
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myquran/notification/notification_service.dart';
import 'package:myquran/quran/service/quran_service.dart';
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
  
  // ✅ CALLBACK with BuildContext
  static Function(BuildContext context, String type, Map<String, dynamic> data)? onNotificationTappedWithContext;
  static Function(String type, Map<String, dynamic> data)? onNotificationTapped;
  
  static const String _channelPrayer = 'prayer_critical_v9';
  static const String _channelDzikir = 'dzikir_critical_v9';
  static const String _channelTilawah = 'tilawah_critical_v9';
  static const String _channelDoa = 'doa_critical_v9';
  
  static const String _keyNotificationHistory = 'notification_history_v3';
  static const String _keyReadNotifications = 'read_notifications_v2';
  static const String _keyBadgeCount = 'notification_badge_count';
  
  static const Map<String, int> _notifIds = {
    'Subuh': 1001, 'Dzuhur': 1002, 'Ashar': 1003, 'Maghrib': 1004, 'Isya': 1005,
    'DzikirPagi': 2001, 'DzikirPetang': 2002,
    'TilawahPagi': 3001, 'TilawahSiang': 3002, 'TilawahMalam': 3003,
    'DoaPagi': 4001, 'DoaPetang': 4002,
  };

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💬 MOTIVATIONAL QUOTES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  // 📖 TILAWAH QUOTES (40 quotes)
  static final List<String> _tilawahQuotes = [
    'Mari sempatkan waktu membaca Al-Qur\'an hari ini',
    'Setiap ayat yang dibaca adalah cahaya di hari akhir',
    'Al-Qur\'an adalah obat hati yang resah',
    'Membaca Al-Qur\'an adalah ibadah yang penuh berkah',
    'Jadikan Al-Qur\'an sebagai teman setia di setiap waktu',
    'Satu ayat hari ini, satu kebaikan untuk esok',
    'Al-Qur\'an membimbing kita menuju jalan yang lurus',
    'Tilawah adalah dialog indah dengan sang Pencipta',
    'Sempatkan membaca meski hanya satu halaman',
    'Al-Qur\'an adalah pedoman hidup yang sempurna',
    'Bacalah dengan tartil, renungkan maknanya',
    'Setiap huruf yang dibaca bernilai sepuluh kebaikan',
    'Al-Qur\'an menenangkan jiwa yang gelisah',
    'Jadikan membaca Al-Qur\'an sebagai kebiasaan',
    'Tilawah adalah investasi untuk akhirat',
    'Buka mushaf, buka pintu surga',
    'Al-Qur\'an adalah cahaya dalam kegelapan',
    'Membaca Al-Qur\'an adalah bentuk kecintaan kepada Allah',
    'Setiap tilawah mendekatkan diri kepada Rabbmu',
    'Al-Qur\'an menjawab semua pertanyaan hidup',
    'Jadikan Al-Qur\'an sebagai sumber inspirasi',
    'Tilawah pagi membawa berkah sepanjang hari',
    'Renungkan ayat demi ayat, rasakan keajaibannya',
    'Al-Qur\'an adalah mukjizat yang abadi',
    'Membaca Al-Qur\'an melembutkan hati yang keras',
    'Setiap tilawah adalah doa yang mustajab',
    'Al-Qur\'an memberikan solusi di setiap masalah',
    'Jadikan tilawah sebagai rutinitas harian',
    'Membaca Al-Qur\'an adalah amal yang tidak pernah sia-sia',
    'Al-Qur\'an adalah petunjuk bagi orang yang bertakwa',
    'Tilawah adalah cara terbaik mendekatkan diri kepada Allah',
    'Setiap ayat adalah mutiara hikmah yang berharga',
    'Al-Qur\'an menyembuhkan luka hati',
    'Membaca dengan khusyuk, mendapat pahala berlimpah',
    'Al-Qur\'an adalah kitab yang sempurna',
    'Tilawah adalah kunci kebahagiaan dunia dan akhirat',
    'Bacalah Al-Qur\'an sebelum dia bersaksi atasmu',
    'Setiap tilawah adalah cahaya yang menerangi jalan',
    'Al-Qur\'an adalah teman terbaik di setiap waktu',
    'Membaca Al-Qur\'an adalah ibadah yang mulia',
  ];

  // 📿 DZIKIR QUOTES (40 quotes)
  static final List<String> _dzikirQuotes = [
    'Dzikir menenangkan hati yang gelisah',
    'Ingatlah Allah, niscaya Allah mengingatmu',
    'Dzikir adalah obat dari segala penyakit hati',
    'Dengan berdzikir, hati menjadi tenteram',
    'Dzikir pagi melindungimu sepanjang hari',
    'Setiap tasbih adalah pintu menuju surga',
    'Berdzikir adalah cara mudah meraih pahala',
    'Dzikir menghapus dosa dan menambah kebaikan',
    'Hati yang berdzikir adalah hati yang hidup',
    'Dzikir adalah senjata mukmin yang paling ampuh',
    'Sempatkan berdzikir meski hanya beberapa menit',
    'Dengan dzikir, Allah selalu bersamamu',
    'Dzikir petang menjaga dari gangguan malam',
    'Setiap zikir adalah investasi untuk akhirat',
    'Berdzikir membuka pintu rahmat Allah',
    'Dzikir adalah bentuk syukur kepada Allah',
    'Hati yang berdzikir tidak akan pernah sepi',
    'Dzikir adalah cahaya di kegelapan',
    'Dengan berdzikir, hidup menjadi lebih bermakna',
    'Dzikir mendekatkan diri kepada sang Pencipta',
    'Setiap kalimat tayyibah bernilai surga',
    'Berdzikir adalah amal yang ringan namun besar pahalanya',
    'Dzikir melindungi dari godaan syetan',
    'Hati yang lalai adalah hati yang mati, maka berdzikirlah',
    'Dzikir adalah makanan ruh dan jiwa',
    'Dengan dzikir, semua urusan dipermudah',
    'Berdzikir adalah tanda kecintaan kepada Allah',
    'Dzikir membersihkan hati dari penyakit',
    'Setiap dzikir adalah doa yang dikabulkan',
    'Berdzikir membawa ketenangan dalam hidup',
    'Dzikir adalah benteng dari segala keburukan',
    'Hati yang berdzikir adalah hati yang bahagia',
    'Dzikir menghilangkan rasa khawatir dan cemas',
    'Dengan dzikir, Allah meridhai setiap langkahmu',
    'Berdzikir adalah ibadah yang tidak pernah putus',
    'Dzikir adalah kunci pembuka pintu surga',
    'Hati yang berdzikir selalu dalam lindungan Allah',
    'Dzikir membawa berkah di setiap waktu',
    'Berdzikir adalah cara terbaik mengisi waktu',
    'Dzikir adalah cahaya yang menerangi hati',
  ];

  // 🤲 DOA QUOTES (40 quotes)
  static final List<String> _doaQuotes = [
    'Doa adalah senjata mukmin yang paling ampuh',
    'Allah selalu mendengar setiap doa hambaNya',
    'Berdoa adalah tanda ketergantungan kepada Allah',
    'Setiap doa adalah ibadah yang mulia',
    'Dengan berdoa, semua kemustahilan menjadi mungkin',
    'Doa mengubah takdir, maka jangan berhenti berdoa',
    'Allah mencintai hamba yang rajin berdoa',
    'Doa adalah kunci dari segala kesuksesan',
    'Berdoa adalah bentuk iman kepada Allah',
    'Setiap doa tidak akan sia-sia di sisi Allah',
    'Doa di waktu pagi membawa berkah sepanjang hari',
    'Dengan berdoa, hati menjadi tenteram',
    'Doa adalah cara terbaik meminta kepada Allah',
    'Berdoa menunjukkan kerendahan hati kepada Sang Pencipta',
    'Setiap doa adalah harapan yang ditujukan kepada Allah',
    'Doa mengangkat derajat seorang hamba',
    'Dengan berdoa, pintu rahmat Allah terbuka lebar',
    'Berdoa adalah ibadah yang tidak pernah ditolak',
    'Doa melindungi dari segala marabahaya',
    'Setiap doa adalah investasi untuk akhirat',
    'Berdoa mendekatkan diri kepada Allah',
    'Doa adalah cahaya di tengah kegelapan',
    'Dengan berdoa, semua beban terasa ringan',
    'Berdoa adalah bentuk kepasrahan kepada Allah',
    'Doa membuka pintu yang tertutup',
    'Setiap doa adalah pahala yang besar',
    'Berdoa menghilangkan rasa cemas dan khawatir',
    'Doa adalah harapan di saat putus asa',
    'Dengan berdoa, Allah mengabulkan permintaan',
    'Berdoa adalah tanda keimanan yang kuat',
    'Doa membawa ketenangan dalam hidup',
    'Setiap doa adalah bentuk komunikasi dengan Allah',
    'Berdoa menunjukkan ketundukan kepada Sang Khalik',
    'Doa adalah kekuatan di saat lemah',
    'Dengan berdoa, semua urusan dipermudah',
    'Berdoa adalah jalan menuju ridha Allah',
    'Doa melindungi dari segala kejahatan',
    'Setiap doa adalah permohonan yang tulus',
    'Berdoa membawa berkah dalam hidup',
    'Doa adalah pelita yang menerangi jalan',
  ];

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎲 RANDOM QUOTE GETTERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  String getRandomTilawahQuote() {
    return _tilawahQuotes[_random.nextInt(_tilawahQuotes.length)];
  }

  String getRandomDzikirQuote() {
    return _dzikirQuotes[_random.nextInt(_dzikirQuotes.length)];
  }

  String getRandomDoaQuote() {
    return _doaQuotes[_random.nextInt(_doaQuotes.length)];
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 INITIALIZATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    print('🔔 Initializing notifications v13.0 with motivational quotes...');
    
    try {
      await _initializeTimezone();
      await _initializePlugin();
      if (Platform.isAndroid) await _createCriticalChannels();
      
      final perms = await requestPermissions();
      if (perms['notification'] != true) {
        print('❌ Permissions denied');
        return false;
      }
      
      _isInitialized = true;
      print('✅ Notification system ready');
      return true;
    } catch (e, stack) {
      print('❌ Init failed: $e\n$stack');
      return false;
    }
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();
    final savedTz = prefs.getString('user_timezone') ?? 'Asia/Makassar';
    _userLocation = tz.getLocation(savedTz);
    tz.setLocalLocation(_userLocation!);
    print('📍 Timezone: $savedTz');
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
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );
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
        enableLights: true, ledColor: const Color(0xFF059669), showBadge: true,
      ),
    );
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelDzikir, 'Pengingat Dzikir',
        description: 'Dzikir pagi dan petang',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 300, 200, 300]),
        enableLights: true, ledColor: const Color(0xFF06B6D4),
      ),
    );
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelTilawah, 'Pengingat Tilawah',
        description: 'Waktu membaca Al-Quran',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 400, 100, 400]),
        enableLights: true, ledColor: const Color(0xFF10B981),
      ),
    );
    
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelDoa, 'Pengingat Doa',
        description: 'Pengingat untuk berdoa',
        importance: Importance.max, playSound: true, enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 350, 150, 350]),
        enableLights: true, ledColor: const Color(0xFFA855F7),
      ),
    );
    
    print('✅ Critical channels created');
  }

  Future<Map<String, bool>> requestPermissions() async {
    print('🔐 Requesting permissions...');
    
    final result = <String, bool>{
      'notification': false,
      'exactAlarm': false,
      'scheduleExactAlarm': false,
      'batteryOptimization': false,
    };
    
    var status = await Permission.notification.request();
    result['notification'] = status.isGranted;
    
    if (!status.isGranted) {
      print('❌ Notification denied');
      return result;
    }
    print('✅ Notification');
    
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        try {
          final canSchedule = await androidPlugin.canScheduleExactNotifications() ?? false;
          
          if (!canSchedule) {
            await androidPlugin.requestExactAlarmsPermission();
            final canNow = await androidPlugin.canScheduleExactNotifications() ?? false;
            result['exactAlarm'] = canNow;
            print(canNow ? '✅ Exact Alarms' : '⚠️ Exact alarm denied');
          } else {
            result['exactAlarm'] = true;
            print('✅ Exact Alarms');
          }
        } catch (e) {
          print('⚠️ Exact alarm error: $e');
        }
        
        try {
          status = await Permission.scheduleExactAlarm.request();
          result['scheduleExactAlarm'] = status.isGranted;
          print('${status.isGranted ? '✅' : '⚠️'} Schedule Exact Alarm');
        } catch (e) {
          print('⚠️ Schedule exact alarm not available');
        }
      }
      
      try {
        status = await Permission.ignoreBatteryOptimizations.request();
        result['batteryOptimization'] = status.isGranted;
        print('${status.isGranted ? '✅' : '⚠️'} Battery optimization');
      } catch (e) {
        print('⚠️ Battery optimization unavailable');
      }
    }
    
    return result;
  }

  void _onNotificationResponse(NotificationResponse response) {
    print('🔔 Notification response (foreground)');
    _handleNotificationTap(response);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    print('🔔 Notification response (background)');
    NotificationManager()._handleNotificationTap(response);
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    if (response.payload == null) return;
    
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final notifId = data['id'] as String?;
      final showInCenter = data['showInCenter'] as bool? ?? true;
      final type = data['type'] as String? ?? 'unknown';
      
      print('📱 Handling notification: $type');
      
      if (notifId != null && showInCenter) {
        await _saveNotificationWhenShown(data);
      }
      
      onNotificationTapped?.call(type, data);
      
      if (onNotificationTappedWithContext != null) {
        try {
          final BuildContext? context = navigatorKey.currentContext;
          if (context != null) {
            onNotificationTappedWithContext?.call(context, type, data);
          }
        } catch (e) {
          print('⚠️ Context callback error: $e');
        }
      }
      
    } catch (e, stack) {
      print('❌ Error handling notification: $e');
      print('Stack: $stack');
    }
  }

  Future<void> _saveNotificationWhenShown(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      
      List<Map<String, dynamic>> history = [];
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson) as List<dynamic>;
        history = decoded.cast<Map<String, dynamic>>();
      }
      
      final notifId = data['id'] as String;
      
      final exists = history.any((item) => item['id'] == notifId);
      if (exists) return;
      
      final notificationData = {
        'id': notifId,
        'title': data['title'] ?? 'Notifikasi',
        'body': data['body'] ?? '',
        'type': data['notifType'] ?? 9,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
        'isScheduled': false,
      };
      
      history.add(notificationData);
      
      if (history.length > 100) {
        history = history.sublist(history.length - 100);
      }
      
      await prefs.setString(_keyNotificationHistory, jsonEncode(history));
      await _updateBadgeCount();
      
      print('✅ Notification saved: ${data['title']}');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  Future<void> _updateBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyNotificationHistory);
      
      if (historyJson == null) {
        await prefs.setInt(_keyBadgeCount, 0);
        NotificationService.badgeCount.value = 0;
        return;
      }
      
      final List<dynamic> history = jsonDecode(historyJson);
      final readIdsJson = prefs.getString(_keyReadNotifications);
      
      Set<String> readIds = {};
      if (readIdsJson != null) {
        final List<dynamic> readList = jsonDecode(readIdsJson);
        readIds = readList.map((e) => e.toString()).toSet();
      }
      
      int unread = 0;
      for (var item in history) {
        final isScheduled = item['isScheduled'] as bool? ?? false;
        if (!isScheduled && !readIds.contains(item['id'].toString())) {
          unread++;
        }
      }
      
      await prefs.setInt(_keyBadgeCount, unread);
      NotificationService.badgeCount.value = unread;
      print('🔢 Badge: $unread');
    } catch (e) {
      print('⚠️ Badge update error: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📅 SCHEDULE ALL NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> scheduleAllNotifications({
    required Map<String, TimeOfDay> prayerTimes,
    Map<String, bool>? enabledPrayers,
    required Map<String, TimeOfDay> tilawahTimes,
    Map<String, TimeOfDay>? doaTimes,
  }) async {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📅 SCHEDULING ALL NOTIFICATIONS v13.0');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      await cancelAllNotifications();
      
      final prefs = await SharedPreferences.getInstance();
      final enabled = enabledPrayers ?? {
        'Subuh': prefs.getBool('notif_enable_subuh') ?? true,
        'Dzuhur': prefs.getBool('notif_enable_dzuhur') ?? true,
        'Ashar': prefs.getBool('notif_enable_ashar') ?? true,
        'Maghrib': prefs.getBool('notif_enable_maghrib') ?? true,
        'Isya': prefs.getBool('notif_enable_isya') ?? true,
      };
      
      int scheduled = 0;
      
      // 1️⃣ PRAYER NOTIFICATIONS
      print('\n1️⃣ Prayer Notifications:');
      for (var entry in prayerTimes.entries) {
        if (entry.key == 'Terbit') continue;
        if (enabled[entry.key] == true) {
          try {
            await _schedulePrayer(entry.key, entry.value);
            scheduled++;
            print('   ✅ ${entry.key}: ${_fmt(entry.value)}');
          } catch (e) {
            print('   ❌ ${entry.key}: $e');
          }
        }
      }
      
      // 2️⃣ DZIKIR NOTIFICATIONS
      print('\n2️⃣ Dzikir Notifications:');
      if (prefs.getBool('notif_enable_dzikir_pagi') ?? true) {
        try {
          final time = _addMin(prayerTimes['Subuh']!, 30);
          await _scheduleDzikir('Pagi', time);
          scheduled++;
          print('   ✅ Dzikir Pagi: ${_fmt(time)}');
        } catch (e) {
          print('   ❌ Dzikir Pagi: $e');
        }
      }
      
      if (prefs.getBool('notif_enable_dzikir_petang') ?? true) {
        try {
          final time = _addMin(prayerTimes['Ashar']!, 30);
          await _scheduleDzikir('Petang', time);
          scheduled++;
          print('   ✅ Dzikir Petang: ${_fmt(time)}');
        } catch (e) {
          print('   ❌ Dzikir Petang: $e');
        }
      }
      
      // 3️⃣ TILAWAH NOTIFICATIONS
      print('\n3️⃣ Tilawah Notifications:');
      if (prefs.getBool('notif_enable_tilawah_pagi') ?? true) {
        try {
          final time = tilawahTimes['Pagi'] ?? const TimeOfDay(hour: 6, minute: 0);
          await _scheduleTilawah('Pagi', time);
          scheduled++;
          print('   ✅ Tilawah Pagi: ${_fmt(time)}');
        } catch (e) {
          print('   ❌ Tilawah Pagi: $e');
        }
      }
      
      if (prefs.getBool('notif_enable_tilawah_siang') ?? false) {
        try {
          final time = tilawahTimes['Siang'] ?? const TimeOfDay(hour: 13, minute: 0);
          await _scheduleTilawah('Siang', time);
          scheduled++;
          print('   ✅ Tilawah Siang: ${_fmt(time)}');
        } catch (e) {
          print('   ❌ Tilawah Siang: $e');
        }
      }
      
      if (prefs.getBool('notif_enable_tilawah_malam') ?? true) {
        try {
          final time = tilawahTimes['Malam'] ?? const TimeOfDay(hour: 20, minute: 0);
          await _scheduleTilawah('Malam', time);
          scheduled++;
          print('   ✅ Tilawah Malam: ${_fmt(time)}');
        } catch (e) {
          print('   ❌ Tilawah Malam: $e');
        }
      }
      
      // 4️⃣ DOA NOTIFICATIONS
      print('\n4️⃣ Doa Notifications:');
      if (prefs.getBool('notif_enable_doa_pagi') ?? true) {
        try {
          final time = doaTimes?['Pagi'] ?? _addMin(prayerTimes['Subuh']!, 15);
          await _scheduleDoa('Pagi', time);
          scheduled++;
          print('   ✅ Doa Pagi: ${_fmt(time)}');
        } catch (e) {
          print('   ❌ Doa Pagi: $e');
        }
      }
      
      if (prefs.getBool('notif_enable_doa_petang') ?? true) {
        try {
          final time = doaTimes?['Petang'] ?? _addMin(prayerTimes['Maghrib']!, 10);
          await _scheduleDoa('Petang', time);
          scheduled++;
          print('   ✅ Doa Petang: ${_fmt(time)}');
        } catch (e) {
          print('   ❌ Doa Petang: $e');
        }
      }
      
      final pending = await _notifications.pendingNotificationRequests();
      print('\n📊 Summary:');
      print('   Scheduled: $scheduled');
      print('   Pending: ${pending.length}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
    } catch (e, stack) {
      print('❌ Fatal error: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🕌 SCHEDULE PRAYER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _schedulePrayer(String name, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    final showInCenter = prefs.getBool('notif_show_in_center') ?? true;
    
    final title = '🕌 Waktu Sholat $name';
    final body = 'Saatnya menunaikan sholat $name - ${_getMessage(name)}';
    final id = '${name}_${scheduled.millisecondsSinceEpoch}';
    
    final payload = jsonEncode({
      'id': id,
      'type': 'prayer',
      'name': name,
      'time': scheduled.toIso8601String(),
      'title': title,
      'body': body,
      'showInCenter': showInCenter,
      'notifType': _getNotificationTypeIndex(name),
    });
    
    await _notifications.zonedSchedule(
      _notifIds[name]!,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelPrayer, 'Adzan & Waktu Sholat',
          channelDescription: 'Notifikasi waktu sholat',
          importance: Importance.max, priority: Priority.max,
          fullScreenIntent: true, category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: !isSilent,
          sound: isSilent ? null : const RawResourceAndroidNotificationSound('adzan'),
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          icon: '@mipmap/ic_launcher', color: const Color(0xFF059669),
          enableLights: true, ledColor: const Color(0xFF059669),
          autoCancel: true, ongoing: false,
          showWhen: true, when: scheduled.millisecondsSinceEpoch,
          styleInformation: BigTextStyleInformation(
            '🕌 Masuk waktu sholat $name\n\n${_getMessage(name)}\n\nWaktu: ${_fmt(time)}',
            htmlFormatBigText: false,
            contentTitle: title,
            summaryText: 'Bekal Muslim',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: !isSilent,
          sound: 'adzan.wav', interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📿 SCHEDULE DZIKIR - WITH RANDOM MOTIVATIONAL QUOTES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _scheduleDzikir(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    final showInCenter = prefs.getBool('notif_show_in_center') ?? true;
    final emoji = type == 'Pagi' ? '🌅' : '🌆';
    final notifId = type == 'Pagi' ? _notifIds['DzikirPagi']! : _notifIds['DzikirPetang']!;
    
    // ✅ RANDOM MOTIVATIONAL QUOTE
    final motivationalQuote = getRandomDzikirQuote();
    
    final title = '$emoji Waktu Dzikir $type';
    final body = motivationalQuote;
    final id = 'Dzikir${type}_${scheduled.millisecondsSinceEpoch}';
    
    final payload = jsonEncode({
      'id': id,
      'type': 'dzikir',
      'name': type,
      'title': title,
      'body': body,
      'showInCenter': showInCenter,
      'notifType': 7,
    });
    
    await _notifications.zonedSchedule(
      notifId, title, body, scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDzikir, 'Pengingat Dzikir',
          importance: Importance.max, priority: Priority.max,
          fullScreenIntent: true, category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: !isSilent, enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
          icon: '@mipmap/ic_launcher', color: const Color(0xFF06B6D4),
          autoCancel: true, showWhen: true,
          styleInformation: BigTextStyleInformation(
            motivationalQuote,
            htmlFormatBigText: false,
            contentTitle: title,
            summaryText: 'Bekal Muslim',
          ),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: !isSilent),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📖 SCHEDULE TILAWAH - WITH RANDOM QUOTES + LAST READ INFO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _scheduleTilawah(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    final showInCenter = prefs.getBool('notif_show_in_center') ?? true;
    
    // ✅ GET LAST READ INFO
    final lastRead = await _quranService.getLastRead();
    String lastReadText = '';
    if (lastRead != null) {
      lastReadText = '\n\nLanjutkan: ${lastRead.surahName} Ayat ${lastRead.ayahNumber}';
    }
    
    // ✅ RANDOM MOTIVATIONAL QUOTE
    final motivationalQuote = getRandomTilawahQuote();
    
    String emoji;
    int notifId;
    switch (type) {
      case 'Pagi': emoji = '📖'; notifId = _notifIds['TilawahPagi']!; break;
      case 'Siang': emoji = '☀️'; notifId = _notifIds['TilawahSiang']!; break;
      case 'Malam': emoji = '🌙'; notifId = _notifIds['TilawahMalam']!; break;
      default: emoji = '📖'; notifId = _notifIds['TilawahPagi']!;
    }
    
    final title = '$emoji Waktunya Tilawah $type';
    final body = '$motivationalQuote$lastReadText';
    final id = 'Tilawah${type}_${scheduled.millisecondsSinceEpoch}';
    
    final payload = jsonEncode({
      'id': id,
      'type': 'tilawah',
      'name': type,
      'title': title,
      'body': body,
      'motivationalQuote': motivationalQuote,
      'showInCenter': showInCenter,
      'notifType': 8,
      'lastRead': lastRead?.toJson(),
    });
    
    await _notifications.zonedSchedule(
      notifId, title, body, scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelTilawah, 'Pengingat Tilawah',
          importance: Importance.max, priority: Priority.max,
          fullScreenIntent: true, 
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: !isSilent, 
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 400, 100, 400]),
          icon: '@mipmap/ic_launcher', 
          color: const Color(0xFF10B981),
          autoCancel: true, 
          showWhen: true,
          styleInformation: BigTextStyleInformation(
            body,
            htmlFormatBigText: false,
            contentTitle: title,
            summaryText: 'Bekal Muslim',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, 
          presentBadge: true, 
          presentSound: !isSilent
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🤲 SCHEDULE DOA - WITH RANDOM MOTIVATIONAL QUOTES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _scheduleDoa(String type, TimeOfDay time) async {
    final now = tz.TZDateTime.now(_userLocation!);
    var scheduled = tz.TZDateTime(_userLocation!, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    final prefs = await SharedPreferences.getInstance();
    final isSilent = prefs.getBool('notification_silent_mode') ?? false;
    final showInCenter = prefs.getBool('notif_show_in_center') ?? true;
    
    // ✅ RANDOM MOTIVATIONAL QUOTE
    final motivationalQuote = getRandomDoaQuote();
    
    String emoji;
    int notifId;
    
    if (type == 'Pagi') {
      emoji = '🤲';
      notifId = _notifIds['DoaPagi']!;
    } else {
      emoji = '🌟';
      notifId = _notifIds['DoaPetang']!;
    }
    
    final title = '$emoji Waktu Berdoa $type';
    final body = motivationalQuote;
    final id = 'Doa${type}_${scheduled.millisecondsSinceEpoch}';
    
    final payload = jsonEncode({
      'id': id,
      'type': 'doa',
      'name': type,
      'title': title,
      'body': body,
      'showInCenter': showInCenter,
      'notifType': 10,
    });
    
    await _notifications.zonedSchedule(
      notifId, title, body, scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDoa, 'Pengingat Doa',
          importance: Importance.max, priority: Priority.max,
          fullScreenIntent: true, 
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: !isSilent, 
          enableVibration: !isSilent,
          vibrationPattern: Int64List.fromList([0, 350, 150, 350]),
          icon: '@mipmap/ic_launcher', 
          color: const Color(0xFFA855F7),
          autoCancel: true, 
          showWhen: true,
          styleInformation: BigTextStyleInformation(
            motivationalQuote,
            htmlFormatBigText: false,
            contentTitle: title,
            summaryText: 'Bekal Muslim',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, 
          presentBadge: true, 
          presentSound: !isSilent
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🛠️ HELPER METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  int _getNotificationTypeIndex(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh': return 0;
      case 'dzuhur': return 1;
      case 'ashar': return 2;
      case 'maghrib': return 3;
      case 'isya': return 4;
      default: return 5;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ All notifications cancelled');
  }
  
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Cancelled notification: $id');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
  
  Future<void> showPendingNotifications() async {
    final pending = await getPendingNotifications();
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📋 PENDING NOTIFICATIONS (${pending.length})');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    for (var notif in pending) {
      print('ID ${notif.id}: ${notif.title}');
      print('   Body: ${notif.body}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  String _fmt(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  
  String _getMessage(String name) {
    switch (name) {
      case 'Subuh': return 'Sholat Subuh adalah cahaya hari ini';
      case 'Dzuhur': return 'Luangkan waktu sejenak untuk sholat';
      case 'Ashar': return 'Jangan lewatkan waktu yang mulia ini';
      case 'Maghrib': return 'Akhiri hari dengan sholat yang khusyuk';
      case 'Isya': return 'Tutup hari dengan ibadah';
      default: return 'Sholat adalah tiang agama';
    }
  }

  TimeOfDay _addMin(TimeOfDay time, int minutes) {
    final total = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }
}

// ✅ GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();