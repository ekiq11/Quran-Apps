// main.dart - PRODUCTION v4.0 FIXED - NO DUPLICATE PERMISSIONS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/notification/notification_manager.dart';
import 'package:myquran/screens/widget/update_dialog.dart';
import 'package:myquran/services/update.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:myquran/provider/dashboard_provider.dart';
import 'package:myquran/screens/dashboard/islamic_dashboard.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🚀 MAIN ENTRY POINT - FIXED v2.0
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🚀 STARTING BEKAL MUSLIM APP v4.0');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  // 🔒 Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // ⏰ Initialize timezone FIRST (critical for notifications)
  print('⏰ Initializing timezone...');
  tz.initializeTimeZones();
  print('✅ Timezone initialized\n');
  
  // 🔔 Initialize notification service
  // ⭐ IMPORTANT: NotificationManager.initialize() handles ALL permissions
  // No need for separate permission request here!
  await _initializeNotifications();
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ APP INITIALIZATION COMPLETE');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  runApp(const MyApp());
}

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🔔 NOTIFICATION INITIALIZATION
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Future<void> _initializeNotifications() async {
  try {
    print('🔔 Initializing Notification System...');
    
    final notificationManager = NotificationManager();
    
    // ⭐ initialize() already handles:
    // - Permission requests
    // - Channel creation
    // - Plugin initialization
    final initialized = await notificationManager.initialize();
    
    if (initialized) {
      print('✅ Notification Manager Ready');
      
      // ⭐ REMOVED: No automatic test notification
      // Test notification should only be triggered manually from settings
      
    } else {
      print('⚠️ Notification Manager initialization failed');
      print('   Some features may not work properly');
    }
    
    print('✅ Notification System Ready\n');
  } catch (e, stackTrace) {
    print('❌ Notification Init Failed: $e');
    print('Stack: $stackTrace');
    
    // ⭐ Don't crash app if notifications fail
    // App should still be usable without notifications
    print('⚠️ App will continue without notification support\n');
  }
}

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🎨 APP WIDGET
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),
      ],
      child: MaterialApp(
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

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🚀 APP INITIALIZER WITH SPLASH SCREEN
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
      // Show splash for minimum duration
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Check for updates
      if (mounted) {
        setState(() {
          _statusMessage = 'Memeriksa pembaruan...';
        });
      }
      
      await _checkForUpdates();
      
    } catch (e) {
      print('⚠️ Initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await _updateService.checkForUpdate();
      
      if (updateInfo != null && mounted) {
        setState(() {
          _statusMessage = 'Pembaruan tersedia...';
        });
        
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
                // App Icon
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
                
                // App Name
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
                
                // Tagline
                const Text(
                  'Aplikasi Islami Lengkap',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Loading Indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Status Message
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
                
                // Version
                const Text(
                  'v4.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}