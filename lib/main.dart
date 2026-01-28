// main.dart - v12.0 - CLEAN START: Zero Permission Checks
// ✅ ABSOLUTELY NO permission checks on startup
// ✅ NO battery optimization checks at all
// ✅ Show onboarding FIRST on first launch
// ✅ ALL permissions requested ONLY in onboarding screen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/notification/notification_manager.dart';
import 'package:myquran/notification/notification_prayer.dart';
import 'package:myquran/notification/notification_service.dart';
import 'package:myquran/permission__onboarding_screen.dart';
import 'package:myquran/screens/widget/update_dialog.dart';
import 'package:myquran/services/update.dart';
import 'package:myquran/services/prayer_time_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:myquran/provider/dashboard_provider.dart';
import 'package:myquran/screens/dashboard/islamic_dashboard.dart';

// ✅ GLOBAL KEY untuk navigate dari background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🚀 STARTING BEKAL MUSLIM APP v12.0');
  print('   Clean Start: ZERO permission checks');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  // ✅ Basic setup only - NO permissions, NO battery checks
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  print('⏰ Initializing timezone...');
  tz.initializeTimeZones();
  print('✅ Timezone initialized\n');
  
  // ✅ Setup notification handlers (but don't initialize yet)
  _setupNotificationHandlers();
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ BASIC INITIALIZATION COMPLETE');
  print('   Ready to show onboarding or dashboard');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  runApp(const MyApp());
}

// ✅ INITIALIZE NOTIFICATIONS - Called ONLY after onboarding
Future<void> initializeNotificationsAfterOnboarding() async {
  try {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 Initializing Notification System (Post-Onboarding)...');
    
    final notificationManager = NotificationManager();
    final initialized = await notificationManager.initialize();
    
    if (initialized) {
      print('✅ Notification Manager Ready');
      
      // ✅ Schedule notifications IMMEDIATELY after init
      await scheduleAllNotificationsIfNeeded();
    } else {
      print('⚠️ Notification Manager initialization failed');
    }
    
    print('✅ Notification System Ready');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  } catch (e, stackTrace) {
    print('❌ Notification Init Failed: $e');
    print('Stack: $stackTrace');
  }
}

// ✅ SCHEDULE NOTIFICATIONS - PUBLIC (can be called from anywhere)
Future<void> scheduleAllNotificationsIfNeeded() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final notifManager = NotificationManager();
    
    // Check if we have required permissions
    final hasPerms = await notifManager.hasRequiredPermissions();
    if (!hasPerms) {
      print('⚠️ Missing permissions, cannot schedule notifications');
      return;
    }
    
    // ✅ Get ALL prayer times including Imsak, Syuruk, Duha
    var prayerTimes = await _loadPrayerTimes(prefs);
    
    // ✅ CRITICAL: If no prayer times, calculate them NOW
    if (prayerTimes.isEmpty) {
      print('⚠️ No prayer times found, calculating now...');
      try {
        final prayerService = PrayerTimeService();
        final model = await prayerService.calculatePrayerTimes(
          forceRefresh: true,
          autoSchedule: false, // Don't auto-schedule, we'll do it manually
        );
        prayerTimes = model.times;
        print('✅ Prayer times calculated successfully!');
      } catch (e) {
        print('❌ Failed to calculate prayer times: $e');
        return;
      }
    }
    
    print('📋 Prayer times loaded:');
    prayerTimes.forEach((name, time) {
      print('   $name: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
    });
    
    // Get tilawah times
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
    
    // Get doa times (based on prayer times)
    final doaTimes = {
      'Pagi': _addMinutes(prayerTimes['Subuh'] ?? const TimeOfDay(hour: 5, minute: 0), 15),
      'Petang': _addMinutes(prayerTimes['Maghrib'] ?? const TimeOfDay(hour: 18, minute: 0), 10),
    };
    
    print('📅 Scheduling all notifications...');
    
    await notifManager.scheduleAllNotifications(
      prayerTimes: prayerTimes,
      tilawahTimes: tilawahTimes,
      doaTimes: doaTimes,
    );
    
    // Save last schedule time
    await prefs.setInt('last_notification_schedule', DateTime.now().millisecondsSinceEpoch);
    
    print('✅ All notifications scheduled successfully');
    
  } catch (e, stack) {
    print('❌ Error scheduling notifications: $e');
    print('Stack: $stack');
  }
}

// ✅ Helper: Load prayer times from SharedPreferences
Future<Map<String, TimeOfDay>> _loadPrayerTimes(SharedPreferences prefs) async {
  final times = <String, TimeOfDay>{};
  
  final prayers = [
    'Imsak',
    'Subuh',
    'Syuruk',
    'Duha',
    'Dzuhur',
    'Ashar',
    'Maghrib',
    'Isya'
  ];
  
  for (final prayer in prayers) {
    final hourKey = 'prayer_${prayer.toLowerCase()}_hour';
    final minuteKey = 'prayer_${prayer.toLowerCase()}_minute';
    
    final hour = prefs.getInt(hourKey);
    final minute = prefs.getInt(minuteKey);
    
    if (hour != null && minute != null) {
      times[prayer] = TimeOfDay(hour: hour, minute: minute);
    }
  }
  
  return times;
}

// Helper: Add minutes to TimeOfDay
TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
  final totalMinutes = time.hour * 60 + time.minute + minutes;
  return TimeOfDay(
    hour: (totalMinutes ~/ 60) % 24,
    minute: totalMinutes % 60,
  );
}

// ✅ SETUP AUTO-POPUP HANDLERS
// ✅ SETUP AUTO-POPUP HANDLERS + BADGE UPDATE
void _setupNotificationHandlers() {
  print('🔧 Setting up auto-popup handlers...');
  
  NotificationManager.onNotificationTappedWithContext = (context, type, data) {
    print('📱 AUTO-POPUP TRIGGERED!');
    print('   Type: $type');
    print('   Context available: ${context != null}');
    
    // ✅ Show popup immediately
    _showPopupImmediately(context, type, data);
    
    // ✅ CRITICAL: Update badge count setelah notification ditampilkan
    // Ini memastikan badge sinkron dengan notification yang muncul
    Future.delayed(Duration(milliseconds: 500), () {
      NotificationService().updateBadgeCountManual();
      print('   ✅ Badge count refreshed after popup shown');
    });
  };
  
  print('✅ Auto-popup handlers configured with badge sync\n');
}

// ✅ SHOW POPUP IMMEDIATELY
void _showPopupImmediately(BuildContext context, String type, Map<String, dynamic> data) {
  print('🎯 Showing popup for: $type');
  
  switch (type) {
    case 'prayer':
      _showPrayerPopup(context, data);
      break;
      
    case 'dzikir':
      _showDzikirPopup(context, data);
      break;
      
    case 'tilawah':
      _showTilawahPopup(context, data);
      break;
      
    case 'doa':
      _showDoaPopup(context, data);
      break;
      
    default:
      print('⚠️ Unknown notification type: $type');
  }
}

// ✅ PRAYER POPUP
// ✅ PRAYER POPUP
void _showPrayerPopup(BuildContext context, Map<String, dynamic> data) {
  final prayerName = data['name'] as String? ?? 'Sholat';
  final prayerTime = data['time'] as String? ?? '';
  
  print('🕌 Showing prayer popup for: $prayerName');
  
  PrayerNotificationHandler.showAdhanDialog(
    context,
    prayerName: prayerName,
    prayerTime: prayerTime,
  );
  
  // ✅ Update badge setelah popup shown
  Future.delayed(Duration(milliseconds: 300), () {
    NotificationService().updateBadgeCountManual();
  });
}

// ✅ DZIKIR POPUP
// ✅ DZIKIR POPUP
void _showDzikirPopup(BuildContext context, Map<String, dynamic> data) {
  final dzikirType = data['name'] as String? ?? 'Pagi';
  final title = data['title'] as String? ?? 'Waktu Dzikir';
  final body = data['body'] as String? ?? 'Saatnya berdzikir';
  
  print('📿 Showing dzikir popup for: $dzikirType');
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => _buildSimplePopup(
      context: context,
      icon: Icons.auto_stories_rounded,
      color: const Color(0xFF06B6D4),
      title: title,
      body: body,
      actionText: 'Buka Dzikir',
      onAction: () {
        Navigator.pop(context);
        print('→ Navigate to dzikir page');
      },
    ),
  ).then((_) {
    // ✅ Update badge setelah dialog ditutup
    NotificationService().updateBadgeCountManual();
  });
}

// ✅ TILAWAH POPUP
// ✅ TILAWAH POPUP
void _showTilawahPopup(BuildContext context, Map<String, dynamic> data) {
  final tilawahType = data['name'] as String? ?? 'Pagi';
  final title = data['title'] as String? ?? 'Waktunya Tilawah';
  final body = data['body'] as String? ?? 'Mari membaca Al-Qur\'an';
  final motivationalQuote = data['motivationalQuote'] as String? ?? '';
  final lastRead = data['lastRead'] as Map<String, dynamic>?;
  
  print('📖 Showing tilawah popup for: $tilawahType');
  
  String displayBody = body;
  
  if (motivationalQuote.isNotEmpty) {
    displayBody = motivationalQuote;
    
    if (lastRead != null) {
      final surahName = lastRead['surahName'] as String? ?? '';
      final ayahNumber = lastRead['ayahNumber'] as int? ?? 0;
      if (surahName.isNotEmpty) {
        displayBody += '\n\n📍 Lanjutkan: $surahName Ayat $ayahNumber';
      }
    }
  }
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => _buildSimplePopup(
      context: context,
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF10B981),
      title: title,
      body: displayBody,
      actionText: 'Buka Al-Qur\'an',
      onAction: () {
        Navigator.pop(context);
        print('→ Navigate to Quran page');
      },
    ),
  ).then((_) {
    // ✅ Update badge setelah dialog ditutup
    NotificationService().updateBadgeCountManual();
  });
}

// ✅ DOA POPUP
// ✅ DOA POPUP
void _showDoaPopup(BuildContext context, Map<String, dynamic> data) {
  final doaType = data['name'] as String? ?? 'Pagi';
  final title = data['title'] as String? ?? 'Waktu Berdoa';
  final body = data['body'] as String? ?? 'Mari berdoa kepada Allah';
  
  print('🤲 Showing doa popup for: $doaType');
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => _buildSimplePopup(
      context: context,
      icon: Icons.volunteer_activism_rounded,
      color: const Color(0xFFA855F7),
      title: title,
      body: body,
      actionText: 'Aamiin',
      onAction: () {
        Navigator.pop(context);
        print('→ Doa popup dismissed with Aamiin');
      },
    ),
  ).then((_) {
    // ✅ Update badge setelah dialog ditutup
    NotificationService().updateBadgeCountManual();
  });
}

// ✅ SIMPLE POPUP WIDGET
Widget _buildSimplePopup({
  required BuildContext context,
  required IconData icon,
  required Color color,
  required String title,
  required String body,
  required String actionText,
  required VoidCallback onAction,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Nanti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Bekal Muslim',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF059669),
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF059669),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF059669),
            primary: const Color(0xFF059669),
            secondary: const Color(0xFF10B981),
          ),
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final UpdateService _updateService = UpdateService();
  bool _isInitializing = true;
  String _statusMessage = 'Memulai aplikasi...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // ✅ CEK apakah first launch TERLEBIH DAHULU
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
      
      if (isFirstLaunch) {
        // ✅ FIRST LAUNCH: Show onboarding IMMEDIATELY
        // NO permission checks, NO battery checks, NO nothing!
        print('\n🎉 FIRST LAUNCH DETECTED');
        print('   → Showing onboarding screen immediately...\n');
        
        if (mounted) {
          setState(() {
            _statusMessage = 'Mempersiapkan pengalaman pertama...';
          });
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          // Navigate to onboarding
          final permissionsGranted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const PermissionOnboardingScreen(),
            ),
          );
          
          if (permissionsGranted == true) {
            // Mark first launch as complete
            await prefs.setBool('is_first_launch', false);
            
            print('\n✅ ONBOARDING COMPLETED');
            print('   → User granted permissions');
            print('   → Initializing notifications...\n');
            
            // NOW initialize notifications (after onboarding)
            if (mounted) {
              setState(() => _statusMessage = 'Mengatur notifikasi...');
            }
            
            await initializeNotificationsAfterOnboarding();
            
            // Calculate prayer times
            if (mounted) {
              setState(() => _statusMessage = 'Menghitung waktu sholat...');
            }
            
            try {
              final prayerService = PrayerTimeService();
              await prayerService.calculatePrayerTimes(
                forceRefresh: true,
                autoSchedule: true,
              );
              print('✅ Prayer times calculated and scheduled\n');
            } catch (e) {
              print('⚠️ Error calculating prayer times: $e');
            }
          } else {
            // User skipped or denied permissions
            print('\n⚠️ ONBOARDING SKIPPED/DENIED');
            print('   → User can grant permissions later in settings\n');
            await prefs.setBool('is_first_launch', false);
          }
        }
        
      } else {
        // ✅ RETURNING USER: Check for updates first
        print('\n👋 RETURNING USER');
        print('   → Checking for updates...\n');
        
        if (mounted) {
          setState(() => _statusMessage = 'Memeriksa pembaruan...');
        }
        
        await _checkForUpdates();
        
        // ✅ SILENTLY re-schedule notifications if permissions exist
        // NO battery checks, NO permission requests
        if (mounted) {
          setState(() => _statusMessage = 'Memperbarui notifikasi...');
        }
        
        final notifManager = NotificationManager();
        final hasPerms = await notifManager.hasRequiredPermissions();
        
        if (hasPerms) {
          print('   → User has permissions, re-scheduling notifications...');
          await notifManager.initialize();
          
          final prayerService = PrayerTimeService();
          final savedTimes = await prayerService.loadSavedPrayerTimes();
          
          if (savedTimes.isEmpty) {
            print('   → No saved times, calculating...');
            try {
              await prayerService.calculatePrayerTimes(
                forceRefresh: true,
                autoSchedule: true,
              );
              print('   ✅ Prayer times calculated and scheduled\n');
            } catch (e) {
              print('   ❌ Error: $e');
              await scheduleAllNotificationsIfNeeded();
            }
          } else {
            print('   → Using saved times, re-scheduling...');
            await scheduleAllNotificationsIfNeeded();
            print('   ✅ Notifications re-scheduled\n');
          }
        } else {
          print('   ⚠️ Missing permissions, notifications not scheduled');
          print('   → User can grant permissions in settings\n');
        }
      }
      
    } catch (e, stack) {
      print('❌ Initialization error: $e');
      print('Stack: $stack');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await _updateService.checkForUpdate();
      
      if (updateInfo != null && mounted) {
        setState(() => _statusMessage = 'Pembaruan tersedia...');
        
        await showDialog(
          context: context,
          barrierDismissible: !updateInfo.mandatory,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );
      }
    } catch (e) {
      print('⚠️ Update check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildSplashScreen();
    }
    
    return const IslamicDashboardPage();
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/other/icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.menu_book_rounded,
                        size: 60,
                        color: Color(0xFF059669),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Bekal Muslim',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aplikasi Islami Lengkap',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'v12.0',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
}