// main.dart - FIXED v7.0 - AUTO POPUP NOTIFICATION
// ✅ Popup muncul otomatis saat notifikasi trigger
// ✅ Tidak perlu tap notifikasi
// ✅ Seperti WhatsApp call notification
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/notification/notification_manager.dart';
import 'package:myquran/notification/notification_prayer.dart';
import 'package:myquran/screens/widget/update_dialog.dart';
import 'package:myquran/services/update.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:myquran/provider/dashboard_provider.dart';
import 'package:myquran/screens/dashboard/islamic_dashboard.dart';

// ✅ GLOBAL KEY untuk navigate dari background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🚀 STARTING BEKAL MUSLIM APP v7.0');
  print('   Features: Auto Popup Notifications');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  print('⏰ Initializing timezone...');
  tz.initializeTimeZones();
  print('✅ Timezone initialized\n');
  
  await _initializeNotifications();
  _setupNotificationHandlers();
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ APP INITIALIZATION COMPLETE');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  runApp(const MyApp());
}

Future<void> _initializeNotifications() async {
  try {
    print('🔔 Initializing Notification System...');
    
    final notificationManager = NotificationManager();
    final initialized = await notificationManager.initialize();
    
    if (initialized) {
      print('✅ Notification Manager Ready');
    } else {
      print('⚠️ Notification Manager initialization failed');
    }
    
    print('✅ Notification System Ready\n');
  } catch (e, stackTrace) {
    print('❌ Notification Init Failed: $e');
    print('Stack: $stackTrace');
  }
}

// ✅ SETUP AUTO-POPUP HANDLERS
void _setupNotificationHandlers() {
  print('🔧 Setting up auto-popup handlers...');
  
  // ✅ NEW: Use context-aware callback for immediate popup
  NotificationManager.onNotificationTappedWithContext = (context, type, data) {
    print('📱 AUTO-POPUP TRIGGERED!');
    print('   Type: $type');
    print('   Context available: ${context != null}');
    
    // ✅ Show popup IMMEDIATELY when notification fires
    _showPopupImmediately(context, type, data);
  };
  
  print('✅ Auto-popup handlers configured');
  print('   Prayer → Adhan Dialog');
  print('   Dzikir → Dzikir Popup');
  print('   Tilawah → Tilawah Popup');
  print('   Doa → Doa Popup\n');
}

// ✅ SHOW POPUP IMMEDIATELY (No need to tap notification)
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

// ✅ PRAYER POPUP - With Adzan Audio
void _showPrayerPopup(BuildContext context, Map<String, dynamic> data) {
  final prayerName = data['name'] as String? ?? 'Sholat';
  final prayerTime = data['time'] as String? ?? '';
  
  print('🕌 Showing prayer popup for: $prayerName');
  
  PrayerNotificationHandler.showAdhanDialog(
    context,
    prayerName: prayerName,
    prayerTime: prayerTime,
  );
}

// ✅ DZIKIR POPUP - With Motivational Quote
void _showDzikirPopup(BuildContext context, Map<String, dynamic> data) {
  final dzikirType = data['name'] as String? ?? 'Pagi';
  final title = data['title'] as String? ?? 'Waktu Dzikir';
  final body = data['body'] as String? ?? 'Saatnya berdzikir';
  
  print('📿 Showing dzikir popup for: $dzikirType');
  print('   Quote: ${body.substring(0, body.length > 50 ? 50 : body.length)}...');
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => _buildSimplePopup(
      context: context,
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF06B6D4),
      title: title,
      body: body,
      actionText: 'Buka Dzikir',
      onAction: () {
        Navigator.pop(context);
        // TODO: Navigate to dzikir page
        print('→ Navigate to dzikir page');
      },
    ),
  );
}

// ✅ TILAWAH POPUP - With Motivational Quote + Last Read Info
void _showTilawahPopup(BuildContext context, Map<String, dynamic> data) {
  final tilawahType = data['name'] as String? ?? 'Pagi';
  final title = data['title'] as String? ?? 'Waktunya Tilawah';
  final body = data['body'] as String? ?? 'Mari membaca Al-Qur\'an';
  final motivationalQuote = data['motivationalQuote'] as String? ?? '';
  final lastRead = data['lastRead'] as Map<String, dynamic>?;
  
  print('📖 Showing tilawah popup for: $tilawahType');
  print('   Quote: ${motivationalQuote.substring(0, motivationalQuote.length > 50 ? 50 : motivationalQuote.length)}...');
  
  // ✅ Display motivational quote + last read info
  String displayBody = body;
  
  // If we have separate motivational quote, prioritize it
  if (motivationalQuote.isNotEmpty) {
    displayBody = motivationalQuote;
    
    // Add last read info if available
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
      color: Color(0xFF10B981),
      title: title,
      body: displayBody,
      actionText: 'Buka Al-Qur\'an',
      onAction: () {
        Navigator.pop(context);
        // TODO: Navigate to Quran page
        print('→ Navigate to Quran page');
      },
    ),
  );
}

// ✅ DOA POPUP - With Motivational Quote
void _showDoaPopup(BuildContext context, Map<String, dynamic> data) {
  final doaType = data['name'] as String? ?? 'Pagi';
  final title = data['title'] as String? ?? 'Waktu Berdoa';
  final body = data['body'] as String? ?? 'Mari berdoa kepada Allah';
  
  print('🤲 Showing doa popup for: $doaType');
  print('   Quote: ${body.substring(0, body.length > 50 ? 50 : body.length)}...');
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => _buildSimplePopup(
      context: context,
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFFA855F7),
      title: title,
      body: body,
      actionText: 'Aamiin',
      onAction: () {
        Navigator.pop(context);
        print('→ Doa popup dismissed with Aamiin');
      },
    ),
  );
}

// ✅ SIMPLE POPUP WIDGET (Reusable)
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
      padding: EdgeInsets.all(24),
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
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.white),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              body,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white, width: 2),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Nanti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    actionText,
                    style: TextStyle(
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
        navigatorKey: navigatorKey, // ✅ CRITICAL: Global navigator key
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
  bool _isCheckingUpdate = true;
  String _statusMessage = 'Memulai aplikasi...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        setState(() => _statusMessage = 'Memeriksa pembaruan...');
      }
      
      await _checkForUpdates();
      
    } catch (e) {
      print('⚠️ Initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
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
    if (_isCheckingUpdate) {
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
                  'v7.0.0 - Auto Popup',
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