// permission_onboarding_screen.dart - v4.0
// ✅ Request ALL permissions dalam onboarding
// ✅ Panggil initializeNotificationsAfterOnboarding() setelah sukses
// ✅ Enhanced UX dengan progress indicator

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/notification/notification_manager.dart';
import 'package:myquran/services/baterai_optimizer_helper.dart';
import 'package:permission_handler/permission_handler.dart';
// ✅ Import main.dart untuk akses fungsi inisialisasi
import 'package:myquran/main.dart' as app_main;

class PermissionOnboardingScreen extends StatefulWidget {
  const PermissionOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRequesting = false;
  String _currentPermission = '';
  int _permissionStep = 0;
  int _totalSteps = 6; // ✅ Updated: +1 for notification initialization

  // Color theme
  static const Color primary = Color(0xFF059669);
  static const Color primaryDark = Color(0xFF047857);

  final List<OnboardingPage> _pages = [
    // Page 1: Prayer - Green Gradient
    OnboardingPage(
      useGradient: true,
      gradientColors: [primary, primaryDark],
      backgroundColor: Colors.white,
      primaryColor: primary,
      textColor: Colors.white,
      icon: Icons.mosque_rounded,
      title: 'Pengingat Waktu Sholat',
      description: 'Dapatkan notifikasi tepat waktu untuk setiap waktu sholat, di mana pun Anda berada',
      benefits: [
        BenefitItem(
          icon: Icons.notifications_active_rounded,
          title: 'Notifikasi 5 Waktu Sholat',
          description: 'Pengingat otomatis setiap waktu sholat',
        ),
        BenefitItem(
          icon: Icons.volume_up_rounded,
          title: 'Realtime Notification',
          description: 'Pengingat waktu sholat realtime sesuai lokasi Anda',
        ),
        BenefitItem(
          icon: Icons.schedule_rounded,
          title: 'Tepat Waktu',
          description: 'Disesuaikan dengan lokasi Anda',
        ),
      ],
    ),
    
    // Page 2: Dzikir & Tilawah - White
    OnboardingPage(
      useGradient: false,
      gradientColors: [],
      backgroundColor: Colors.white,
      primaryColor: primary,
      textColor: Color(0xFF1F2937),
      icon: Icons.auto_stories_rounded,
      title: 'Dzikir & Tilawah Harian',
      description: 'Jangan lewatkan waktu dzikir pagi-petang dan tilawah Al-Qur\'an dengan pengingat yang lembut',
      benefits: [
        BenefitItem(
          icon: Icons.menu_book_rounded,
          title: 'Tilawah Al-Qur\'an',
          description: 'Motivasi membaca setiap hari',
        ),
        BenefitItem(
          icon: Icons.wb_sunny_rounded,
          title: 'Doa, Dzikir Pagi & Petang',
          description: 'Pengingat rutin untuk berdzikir',
        ),

        BenefitItem(
          icon: Icons.format_quote_rounded,
          title: 'Mufrodat Harian',
          description: 'Inspirasi mufradat bahasa arab',
        ),
      ],
    ),
    
    // Page 3: Permissions - Green Gradient
    OnboardingPage(
      useGradient: true,
      gradientColors: [primary, primaryDark],
      backgroundColor: Colors.white,
      primaryColor: primary,
      textColor: Colors.white,
      icon: Icons.security_rounded,
      title: 'Izin Aplikasi',
      description: 'Untuk memberikan pengalaman terbaik, aplikasi memerlukan beberapa izin berikut',
      benefits: [
        BenefitItem(
          icon: Icons.notifications_rounded,
          title: 'Notifikasi',
          description: 'Menampilkan pengingat ibadah',
        ),
        BenefitItem(
          icon: Icons.location_on_rounded,
          title: 'Lokasi',
          description: 'Mendeteksi waktu sholat yang akurat',
        ),
        BenefitItem(
          icon: Icons.alarm_rounded,
          title: 'Alarm Tepat Waktu',
          description: 'Notifikasi di waktu yang tepat',
        ),
        BenefitItem(
          icon: Icons.battery_charging_full_rounded,
          title: 'Optimasi Baterai',
          description: 'Notifikasi tetap aktif di background',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ✅ REQUEST ALL PERMISSIONS SEQUENTIALLY - ENHANCED
  Future<void> _requestAllPermissions() async {
    setState(() {
      _isRequesting = true;
      _permissionStep = 0;
      _currentPermission = 'Memulai permintaan izin...';
    });
    
    bool allGranted = true;
    List<String> failedPermissions = [];
    
    try {
      // 1️⃣ REQUEST NOTIFICATION PERMISSION
      _updateProgress(1, 'Meminta izin notifikasi...');
      print('📱 [1/6] Requesting notification permission...');
      
      final notificationStatus = await Permission.notification.request();
      print('   Status: ${notificationStatus.toString()}');
      
      if (!notificationStatus.isGranted) {
        print('   ⚠️ Notification permission DENIED');
        failedPermissions.add('Notifikasi');
        allGranted = false;
        
        // Show retry dialog
        final retry = await _showPermissionRetryDialog('Notifikasi', 
          'Izin notifikasi diperlukan untuk menampilkan pengingat ibadah.');
        
        if (retry) {
          final retryStatus = await Permission.notification.request();
          if (retryStatus.isGranted) {
            print('   ✅ Notification permission granted on retry');
            failedPermissions.remove('Notifikasi');
            allGranted = true;
          }
        }
      } else {
        print('   ✅ Notification permission GRANTED');
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 2️⃣ REQUEST LOCATION PERMISSION
      _updateProgress(2, 'Meminta izin lokasi...');
      print('📍 [2/6] Requesting location permission...');
      
      var locationStatus = await Permission.location.status;
      print('   Current status: ${locationStatus.toString()}');
      
      if (!locationStatus.isGranted) {
        locationStatus = await Permission.location.request();
        print('   After request: ${locationStatus.toString()}');
      }
      
      if (!locationStatus.isGranted) {
        print('   ⚠️ Location permission DENIED');
        // Location is optional but recommended
        final useWithoutLocation = await _showOptionalPermissionDialog(
          'Lokasi',
          'Izin lokasi membantu menentukan waktu sholat yang akurat sesuai lokasi Anda. '
          'Tanpa izin ini, waktu sholat akan menggunakan lokasi default.',
        );
        
        if (!useWithoutLocation) {
          final retryStatus = await Permission.location.request();
          if (retryStatus.isGranted) {
            print('   ✅ Location permission granted on retry');
          }
        }
      } else {
        print('   ✅ Location permission GRANTED');
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 3️⃣ REQUEST EXACT ALARM PERMISSION (Android 12+)
      _updateProgress(3, 'Meminta izin alarm tepat waktu...');
      print('⏰ [3/6] Requesting exact alarm permission...');
      
      try {
        final alarmStatus = await Permission.scheduleExactAlarm.status;
        print('   Current status: ${alarmStatus.toString()}');
        
        if (!alarmStatus.isGranted) {
          final requestedStatus = await Permission.scheduleExactAlarm.request();
          print('   After request: ${requestedStatus.toString()}');
          
          if (requestedStatus.isGranted) {
            print('   ✅ Exact alarm permission GRANTED');
          } else if (requestedStatus.isPermanentlyDenied) {
            print('   ⚠️ Exact alarm permission PERMANENTLY DENIED');
            await _showSettingsDialog('Alarm Tepat Waktu');
          } else {
            print('   ⚠️ Exact alarm permission DENIED');
          }
        } else {
          print('   ✅ Exact alarm already granted');
        }
      } catch (e) {
        print('   ⚠️ Exact alarm permission not available: $e');
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      
      // 4️⃣ REQUEST BATTERY OPTIMIZATION EXEMPTION
      _updateProgress(4, 'Meminta pengecualian optimasi baterai...');
      print('🔋 [4/6] Requesting battery optimization exemption...');
      
      try {
        final batteryOptDisabled = await BatteryOptimizationHelper.isBatteryOptimizationDisabled();
        print('   Current status: ${batteryOptDisabled ? "Already disabled" : "Enabled"}');
        
        if (!batteryOptDisabled) {
          print('   🔋 Requesting battery optimization exemption...');
          
          final granted = await BatteryOptimizationHelper.requestBatteryOptimizationExemption();
          
          // Wait a bit for system to process
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Verify the result
          final verified = await BatteryOptimizationHelper.isBatteryOptimizationDisabled();
          print('   Verification result: $verified');
          
          if (verified) {
            print('   ✅ Battery optimization exemption GRANTED');
          } else {
            print('   ⚠️ Battery optimization exemption DENIED or PENDING');
            
            // // Show explanation and retry option
            // final retry = await _showBatteryOptimizationDialog();
            // if (retry) {
            //   await BatteryOptimizationHelper.requestBatteryOptimizationExemption();
            //   await Future.delayed(const Duration(milliseconds: 1000));
            //   final retryVerified = await BatteryOptimizationHelper.isBatteryOptimizationDisabled();
            //   if (retryVerified) {
            //     print('   ✅ Battery optimization exemption granted on retry');
            //   }
            // }
          }
        } else {
          print('   ✅ Battery optimization already disabled');
        }
      } catch (e) {
        print('   ❌ Error requesting battery optimization: $e');
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 5️⃣ INITIALIZE NOTIFICATION SYSTEM
      _updateProgress(5, 'Menginisialisasi sistem notifikasi...');
      print('🔔 [5/6] Initializing notification system...');
      
      // ✅ Call the global initialization function
      await app_main.initializeNotificationsAfterOnboarding();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 6️⃣ SETUP PERIODIC WORK (background scheduler)
      _updateProgress(6, 'Mengatur penjadwalan background...');
      print('⚙️ [6/6] Setting up periodic work...');
      
      try {
        // ✅ Call native Android method to setup WorkManager
        const platform = MethodChannel('com.bekalsunnah.doa_harian/battery');
        await platform.invokeMethod('setupPeriodicWork');
        print('✅ Periodic work setup successful');
      } catch (e) {
        print('⚠️ Error setting up periodic work: $e');
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ PERMISSION REQUEST COMPLETED');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      if (mounted) {
        if (failedPermissions.isEmpty) {
          _showSuccessDialog();
        } else {
          _showPartialSuccessDialog(failedPermissions);
        }
      }
      
    } catch (e, stackTrace) {
      print('❌ Error requesting permissions: $e');
      print('Stack: $stackTrace');
      
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
          _currentPermission = '';
          _permissionStep = 0;
        });
      }
    }
  }

  void _updateProgress(int step, String message) {
    if (mounted) {
      setState(() {
        _permissionStep = step;
        _currentPermission = message;
      });
    }
  }

  // ✅ SHOW RETRY DIALOG FOR REQUIRED PERMISSIONS - Beautiful Design
  Future<bool> _showPermissionRetryDialog(String permissionName, String explanation) async {
    final size = MediaQuery.of(context).size;
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF59E0B), // Orange
                Color(0xFFFB923C),
              ],
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
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(size.width * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: size.width * 0.16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: size.height * 0.025),
                
                // Title
                Text(
                  'Izin $permissionName Diperlukan',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.015),
                
                // Explanation
                Container(
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    explanation,
                    style: TextStyle(
                      fontSize: size.width * 0.038,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: size.height * 0.025),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white, width: 2),
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.018,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Lewati',
                          style: TextStyle(
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFFF59E0B),
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.018,
                          ),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Coba Lagi',
                          style: TextStyle(
                            fontSize: size.width * 0.038,
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
        ),
      ),
    ) ?? false;
  }

  // ✅ SHOW DIALOG FOR OPTIONAL PERMISSIONS - Beautiful Design
  Future<bool> _showOptionalPermissionDialog(String permissionName, String explanation) async {
    final size = MediaQuery.of(context).size;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6), // Blue
                Color(0xFF2563EB),
              ],
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
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(size.width * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_rounded,
                    size: size.width * 0.16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: size.height * 0.025),
                
                // Title
                Text(
                  'Izin $permissionName',
                  style: TextStyle(
                    fontSize: size.width * 0.052,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.01),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Opsional',
                    style: TextStyle(
                      fontSize: size.width * 0.032,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                
                // Explanation
                Container(
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    explanation,
                    style: TextStyle(
                      fontSize: size.width * 0.038,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: size.height * 0.025),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white, width: 2),
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.018,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Lanjut Tanpa Izin',
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF3B82F6),
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.018,
                          ),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Berikan Izin',
                          style: TextStyle(
                            fontSize: size.width * 0.038,
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
        ),
      ),
    ) ?? true;
  }

  // // ✅ SHOW BATTERY OPTIMIZATION DIALOG - Beautiful & Consistent Design
  // Future<bool> _showBatteryOptimizationDialog() async {
  //   final size = MediaQuery.of(context).size;
    
  //   return await showDialog<bool>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => Dialog(
  //       backgroundColor: Colors.transparent,
  //       child: Container(
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //             colors: [
  //               Color(0xFFF59E0B), // Orange gradient
  //               Color(0xFFEF4444), // Red gradient
  //             ],
  //           ),
  //           borderRadius: BorderRadius.circular(28),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.3),
  //               blurRadius: 30,
  //               spreadRadius: 5,
  //               offset: const Offset(0, 10),
  //             ),
  //           ],
  //         ),
  //         child: Padding(
  //           padding: EdgeInsets.all(size.width * 0.06),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // Animated Battery Icon
  //               Container(
  //                 padding: EdgeInsets.all(size.width * 0.05),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white.withOpacity(0.2),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: Icon(
  //                   Icons.battery_alert_rounded,
  //                   size: size.width * 0.16,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //               SizedBox(height: size.height * 0.025),
                
  //               // Title
  //               Text(
  //                 'Optimasi Baterai',
  //                 style: TextStyle(
  //                   fontSize: size.width * 0.055,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.white,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               SizedBox(height: size.height * 0.015),
                
  //               // Description Box
  //               Container(
  //                 padding: EdgeInsets.all(size.width * 0.04),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white.withOpacity(0.15),
  //                   borderRadius: BorderRadius.circular(16),
  //                   border: Border.all(
  //                     color: Colors.white.withOpacity(0.3),
  //                     width: 1,
  //                   ),
  //                 ),
  //                 child: Column(
  //                   children: [
  //                     Text(
  //                       'Untuk memastikan notifikasi berjalan dengan baik di background, '
  //                       'silakan matikan optimasi baterai untuk aplikasi ini.',
  //                       style: TextStyle(
  //                         fontSize: size.width * 0.038,
  //                         color: Colors.white.withOpacity(0.95),
  //                         height: 1.5,
  //                       ),
  //                       textAlign: TextAlign.center,
  //                     ),
  //                     SizedBox(height: size.height * 0.015),
                      
  //                     // Benefits List
  //                     _buildBatteryBenefit(
  //                       icon: Icons.notifications_active_rounded,
  //                       text: 'Notifikasi tepat waktu',
  //                       size: size,
  //                     ),
  //                     SizedBox(height: size.height * 0.008),
  //                     _buildBatteryBenefit(
  //                       icon: Icons.alarm_rounded,
  //                       text: 'Tidak melewatkan adzan',
  //                       size: size,
  //                     ),
  //                     SizedBox(height: size.height * 0.008),
  //                     _buildBatteryBenefit(
  //                       icon: Icons.check_circle_rounded,
  //                       text: 'Pengingat ibadah aktif',
  //                       size: size,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               SizedBox(height: size.height * 0.025),
                
  //               // Action Buttons
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: OutlinedButton(
  //                       onPressed: () => Navigator.pop(context, false),
  //                       style: OutlinedButton.styleFrom(
  //                         foregroundColor: Colors.white,
  //                         side: BorderSide(color: Colors.white, width: 2),
  //                         padding: EdgeInsets.symmetric(
  //                           vertical: size.height * 0.018,
  //                         ),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(16),
  //                         ),
  //                       ),
  //                       child: Text(
  //                         'Nanti Saja',
  //                         style: TextStyle(
  //                           fontSize: size.width * 0.038,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   SizedBox(width: size.width * 0.03),
  //                   Expanded(
  //                     flex: 2,
  //                     child: ElevatedButton(
  //                       onPressed: () => Navigator.pop(context, true),
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Colors.white,
  //                         foregroundColor: Color(0xFFF59E0B),
  //                         padding: EdgeInsets.symmetric(
  //                           vertical: size.height * 0.018,
  //                         ),
  //                         elevation: 8,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(16),
  //                         ),
  //                       ),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Icon(Icons.settings_rounded, size: size.width * 0.045),
  //                           SizedBox(width: size.width * 0.02),
  //                           Text(
  //                             'Buka Pengaturan',
  //                             style: TextStyle(
  //                               fontSize: size.width * 0.038,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   ) ?? false;
  // }
  
  // Helper widget for battery dialog benefits
  Widget _buildBatteryBenefit({
    required IconData icon,
    required String text,
    required Size size,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: size.width * 0.045,
          color: Colors.white,
        ),
        SizedBox(width: size.width * 0.025),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: size.width * 0.035,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ SHOW SETTINGS DIALOG - Beautiful Design
  Future<void> _showSettingsDialog(String permissionName) async {
    final size = MediaQuery.of(context).size;
    
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEF4444), // Red
                Color(0xFFDC2626),
              ],
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
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(size.width * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block_rounded,
                    size: size.width * 0.16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: size.height * 0.025),
                
                // Title
                Text(
                  'Izin Ditolak',
                  style: TextStyle(
                    fontSize: size.width * 0.055,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.015),
                
                // Message
                Container(
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Izin $permissionName ditolak secara permanen.',
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        'Silakan aktifkan di Pengaturan aplikasi untuk menggunakan fitur ini.',
                        style: TextStyle(
                          fontSize: size.width * 0.036,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.025),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white, width: 2),
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.018,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Nanti',
                          style: TextStyle(
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          openAppSettings();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFFEF4444),
                          padding: EdgeInsets.symmetric(
                            vertical: size.height * 0.018,
                          ),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.settings_rounded, size: size.width * 0.045),
                            SizedBox(width: size.width * 0.02),
                            Text(
                              'Buka Pengaturan',
                              style: TextStyle(
                                fontSize: size.width * 0.038,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: MediaQuery.of(context).size.width * 0.16,
                  color: primary,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Text(
                'Semua Siap! ✨',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.06,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Text(
                'Semua izin telah diberikan. Notifikasi pengingat ibadah telah aktif. Mari mulai perjalanan spiritual Anda!',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mulai Sekarang',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartialSuccessDialog(List<String> failedPermissions) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: MediaQuery.of(context).size.width * 0.16,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Text(
                'Beberapa Izin Belum Diberikan',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.055,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Text(
                'Izin yang belum diberikan:\n${failedPermissions.join(", ")}\n\n'
                'Aplikasi tetap dapat digunakan, namun beberapa fitur mungkin terbatas. '
                'Anda dapat mengaktifkan izin nanti di Pengaturan.',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terjadi Kesalahan'),
        content: Text(
          'Terjadi kesalahan saat meminta izin:\n$error\n\nSilakan coba lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
            },
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestAllPermissions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final page = _pages[_currentPage];
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: page.useGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: page.gradientColors,
                )
              : null,
          color: page.useGradient ? null : page.backgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with App Icon and Skip Button
              Padding(
                padding: EdgeInsets.all(size.width * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App Icon
                    Container(
                      padding: EdgeInsets.all(size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/other/icon.png',
                        width: size.width * 0.1,
                        height: size.width * 0.1,
                        errorBuilder: (context, error, stack) {
                          return Icon(
                            Icons.menu_book_rounded,
                            size: size.width * 0.1,
                            color: primary,
                          );
                        },
                      ),
                    ),
                    
                    // Skip Button
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            _pages.length - 1,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Lewati',
                          style: TextStyle(
                            color: page.textColor,
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      SizedBox(width: size.width * 0.14),
                  ],
                ),
              ),
              
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], size);
                  },
                ),
              ),
              
              // Page indicator and button
              Padding(
                padding: EdgeInsets.all(size.width * 0.08),
                child: Column(
                  children: [
                    // Progress indicator during permission request
                    if (_isRequesting) ...[
                      Container(
                        padding: EdgeInsets.all(size.width * 0.04),
                        decoration: BoxDecoration(
                          color: page.useGradient 
                              ? Colors.white.withOpacity(0.2)
                              : primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _permissionStep / _totalSteps,
                                backgroundColor: page.useGradient 
                                    ? Colors.white.withOpacity(0.3)
                                    : primary.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation(
                                  page.useGradient ? Colors.white : primary,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            SizedBox(height: size.height * 0.015),
                            Text(
                              'Langkah $_permissionStep dari $_totalSteps',
                              style: TextStyle(
                                fontSize: size.width * 0.03,
                                color: page.useGradient ? Colors.white.withOpacity(0.8) : primary.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: size.height * 0.01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: size.width * 0.04,
                                  width: size.width * 0.04,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      page.useGradient ? Colors.white : primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: size.width * 0.03),
                                Expanded(
                                  child: Text(
                                    _currentPermission,
                                    style: TextStyle(
                                      fontSize: size.width * 0.035,
                                      color: page.useGradient ? Colors.white : primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                    ],
                    
                    // Dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildDot(index, size),
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isRequesting ? null : () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // ✅ REQUEST ALL PERMISSIONS
                            _requestAllPermissions();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: page.useGradient ? Colors.white : primary,
                          foregroundColor: page.useGradient ? primary : Colors.white,
                          padding: EdgeInsets.symmetric(vertical: size.height * 0.022),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          disabledBackgroundColor: page.useGradient 
                              ? Colors.white.withOpacity(0.5) 
                              : primary.withOpacity(0.5),
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Lanjutkan'
                              : 'Aktifkan Semua Izin',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, Size size) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: size.height * 0.02),
          
          // Icon
          Container(
            padding: EdgeInsets.all(size.width * 0.08),
            decoration: BoxDecoration(
              color: page.useGradient 
                  ? Colors.white.withOpacity(0.2)
                  : primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: size.width * 0.2,
              color: page.useGradient ? Colors.white : primary,
            ),
          ),
          SizedBox(height: size.height * 0.04),
          
          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: size.width * 0.07,
              fontWeight: FontWeight.bold,
              color: page.textColor,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.02),
          
          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: size.width * 0.04,
              color: page.useGradient 
                  ? Colors.white.withOpacity(0.95)
                  : Colors.grey[600],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.05),
          
          // Benefits
          ...page.benefits.map((benefit) => _buildBenefit(benefit, page, size)).toList(),
          SizedBox(height: size.height * 0.02),
        ],
      ),
    );
  }

  Widget _buildBenefit(BenefitItem benefit, OnboardingPage page, Size size) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.015),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: page.useGradient 
            ? Colors.white.withOpacity(0.15)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: page.useGradient 
            ? null 
            : Border.all(color: primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(size.width * 0.025),
            decoration: BoxDecoration(
              color: page.useGradient 
                  ? Colors.white.withOpacity(0.25)
                  : primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              benefit.icon,
              color: page.useGradient ? Colors.white : primary,
              size: size.width * 0.06,
            ),
          ),
          SizedBox(width: size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    color: page.textColor,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: size.height * 0.004),
                Text(
                  benefit.description,
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: page.useGradient 
                        ? Colors.white.withOpacity(0.85)
                        : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Size size) {
    final page = _pages[_currentPage];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.01),
      height: size.width * 0.02,
      width: _currentPage == index ? size.width * 0.06 : size.width * 0.02,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? (page.useGradient ? Colors.white : primary)
            : (page.useGradient 
                ? Colors.white.withOpacity(0.4)
                : primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(size.width * 0.01),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📄 MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class OnboardingPage {
  final bool useGradient;
  final List<Color> gradientColors;
  final Color backgroundColor;
  final Color primaryColor;
  final Color textColor;
  final IconData icon;
  final String title;
  final String description;
  final List<BenefitItem> benefits;

  OnboardingPage({
    required this.useGradient,
    required this.gradientColors,
    required this.backgroundColor,
    required this.primaryColor,
    required this.textColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.benefits,
  });
}

class BenefitItem {
  final IconData icon;
  final String title;
  final String description;

  BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}