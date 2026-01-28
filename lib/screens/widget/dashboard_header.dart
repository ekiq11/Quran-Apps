// screens/dashboard/dashboard_header.dart - FIXED DATA LOADING
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/notification/notification_center.dart';
import 'package:myquran/notification/notification_service.dart';
import 'package:myquran/notification/notification_setting.dart';
import 'package:myquran/quran/util/islamic_geometries.dart';
import 'package:myquran/screens/widget/hijriah_bottom_sheet.dart';
import 'package:myquran/screens/widget/location_detail.dart';
import 'package:provider/provider.dart';
import 'package:myquran/provider/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:myquran/screens/util/constants.dart';
import '../../../quran/model/surah_model.dart';
import '../../doa/screens/doa_list_page.dart';
import '../../dzikir/screens/main_dzikir.dart';
import '../../quran/screens/quran_main.dart';
import '../../quran/screens/read_page.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({
    Key? key,
  }) : super(key: key);

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader>
  
   with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  AnimationController? _shimmerController;
  Animation<double>? _shimmerAnimation;
  late AnimationController _quranBreathingController;
  late Animation<double> _quranBreathingAnimation;
  bool _isPrayerExpanded = false;

  static const double _horizontalPadding = 16.0;
  static const double _verticalSpacing = 16.0;
  static const double _cardBorderRadius = 24.0;
  late String _randomGreeting;
final Random _random = Random();

 // Tambahkan di bagian initState - UPDATE EXISTING CODE
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _randomGreeting = _getRandomGreeting();
  
  _pulseController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1500),
  )..repeat(reverse: true);
  
  _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
  );
  
  _shimmerController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2000),
  )..repeat();
  
  _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
    CurvedAnimation(parent: _shimmerController!, curve: Curves.easeInOutSine),
  );
  
  _quranBreathingController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2500),
  )..repeat(reverse: true);
  
  _quranBreathingAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
    CurvedAnimation(
      parent: _quranBreathingController,
      curve: Curves.easeInOut,
    ),
  );
  
  // ✅ CRITICAL FIX: Update badge SETELAH frame pertama
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // ✅ Delay sedikit untuk memastikan SharedPreferences sudah ready
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        print('🔄 Dashboard: Force refreshing badge on init');
        NotificationService().updateBadgeCountManual();
      }
    });
    
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    if (!provider.isLoadingLocation && provider.locationData == null) {
      provider.loadLocation();
    }
  });
}

// ✅ METHOD UNTUK GENERATE RANDOM GREETING
String _getRandomGreeting() {
  final hour = DateTime.now().hour;
  List<String> greetings;
  
  if (hour < 12) {
    greetings = _morningGreetings;
  } else if (hour < 15) {
    greetings = _afternoonGreetings;
  } else if (hour < 18) {
    greetings = _eveningGreetings;
  } else {
    greetings = _nightGreetings;
  }
  
  return greetings[_random.nextInt(greetings.length)];
}

// ✅ METHOD UNTUK REFRESH GREETING (optional - bisa dipanggil saat pull-to-refresh)
void _refreshGreeting() {
  setState(() {
    _randomGreeting = _getRandomGreeting();
  });
}

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController?.dispose();
    _quranBreathingController.dispose();
    WidgetsBinding.instance.removeObserver(this as WidgetsBindingObserver);
    super.dispose();
  }
  // ✅ ADD LIFECYCLE CALLBACK
  @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);
  
  if (state == AppLifecycleState.resumed) {
    print('📱 App resumed - refreshing badge count');
    
    // ✅ CRITICAL: Delay untuk memastikan background process selesai
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        print('🔄 Dashboard: Force badge refresh after resume');
        NotificationService().updateBadgeCountManual();
      }
    });
  }
}
  void _openNotificationCenter() {
  HapticFeedback.lightImpact();
  
  // ✅ Force refresh SEBELUM buka (untuk memastikan data terbaru)
  NotificationService().updateBadgeCountManual();
  
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const NotificationCenterPage()),
  ).then((_) {
    // ✅ Force refresh SETELAH tutup
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        print('🔄 Dashboard: Badge refresh after closing NotificationCenter');
        NotificationService().updateBadgeCountManual();
      }
    });
  });
}
  void _showMenuOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.settings_rounded, color: Colors.blue, size: 22),
              ),
              title: Text('Pengaturan Notifikasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('Atur notifikasi waktu sholat & adzan', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationSettingsPage()));
              },
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.refresh_rounded, color: Colors.green, size: 22),
              ),
              title: Text('Muat Ulang Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('Perbarui data waktu sholat & lokasi', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              onTap: () {
                Navigator.pop(context);
                final provider = Provider.of<DashboardProvider>(context, listen: false);
                provider.loadLocation(forceRefresh: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Memuat ulang data...'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshLocation() async {
    HapticFeedback.mediumImpact();
    final provider = Provider.of<DashboardProvider>(context, listen: false);
     // ✅ TAMBAHKAN INI - Refresh greeting saat pull-to-refresh
  _refreshGreeting();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Memperbarui lokasi...'),
          ],
        ),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
    
    final hasPermission = await provider.requestLocationPermission();
    
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Izin lokasi diperlukan untuk fitur ini')),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    
    await provider.loadLocation(forceRefresh: true);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Lokasi berhasil diperbarui!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Helper method untuk cek apakah lebih dari 1 hari tidak dibaca
  bool _isMoreThanOneDayNotRead(BookmarkModel? lastRead) {
    if (lastRead == null || lastRead.lastRead == null) return true;
    
    final now = DateTime.now();
    final lastReadTime = lastRead.lastRead!;
    final difference = now.difference(lastReadTime);
    
    return difference.inHours >= 24;
  }

  // Helper method untuk mendapatkan gradient berdasarkan status
  List<Color> _getQuranGradient(bool isOverdue) {
    if (isOverdue) {
      return [Color(0xFFEF4444), Color(0xFFDC2626)]; // Red gradient
    }
    return AppColors.primaryGradient; // Green gradient
  }

  // Helper untuk mendapatkan text berapa hari tidak dibaca
  String _getDaysNotRead(BookmarkModel? lastRead) {
    if (lastRead == null || lastRead.lastRead == null) return '1h+';
    
    final now = DateTime.now();
    final lastReadTime = lastRead.lastRead!;
    final difference = now.difference(lastReadTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}h';
    } else if (difference.inHours >= 24) {
      return '1h+';
    }
    return '24j+';
  }

  void _navigateToQuranRead(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    if (provider.lastRead == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReadPage(
          surahNumber: provider.lastRead!.surahNumber,
          initialAyah: provider.lastRead!.ayahNumber,
        ),
      ),
    ).then((_) {
      if (mounted) {
        provider.loadLastRead();
      }
    });
  }

  String _getHijriDate() {
    try {
      final hijri = HijriCalendar.now();
      final dayName = _getHijriDayName(hijri.hDay);
      final monthName = _getHijriMonthName(hijri.hMonth);
      return '$dayName, ${hijri.hDay} $monthName ${hijri.hYear} H';
    } catch (e) {
      return 'Tanggal Hijriah';
    }
  }

  String _getGregorianDate() {
    try {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE', 'id_ID').format(now);
      final date = DateFormat('d MMMM yyyy', 'id_ID').format(now);
      return '$dayName, $date';
    } catch (e) {
      final now = DateTime.now();
      final dayName = _getIndonesianDayName(now.weekday);
      final monthName = _getIndonesianMonthName(now.month);
      return '$dayName, ${now.day} $monthName ${now.year}';
    }
  }

  String _getHijriDayName(int day) {
    final weekday = DateTime.now().weekday;
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Ahad'];
    return days[(weekday - 1) % 7];
  }

  String _getHijriMonthName(int month) {
    const months = ['Muharram', 'Safar', 'Rabiul Awal', 'Rabiul Akhir', 'Jumadil Awal', 'Jumadil Akhir', 'Rajab', 'Syakban', 'Ramadan', 'Syawal', 'Dzulqaidah', 'Dzulhijjah'];
    return months[month - 1];
  }

  String _getIndonesianDayName(int weekday) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[weekday - 1];
  }

  String _getIndonesianMonthName(int month) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return months[month - 1];
  }

  String _getGreetingTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_outlined;
    if (hour < 15) return Icons.wb_sunny_rounded;
    if (hour < 18) return Icons.wb_twilight_rounded;
    return Icons.nights_stay_outlined;
  }

  Color _getGreetingColor() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Colors.amber.shade100;
    if (hour < 15) return Colors.orange.shade100;
    if (hour < 18) return Colors.deepOrange.shade100;
    return Colors.indigo.shade100;
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'Subuh':
        return Icons.wb_twilight;
      case 'Dzuhur':
        return Icons.wb_sunny;
      case 'Ashar':
        return Icons.wb_cloudy;
      case 'Maghrib':
        return Icons.nights_stay_outlined;
      case 'Isya':
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 400;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isSmallScreen ? 16 : 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: _buildPremiumHeader(isSmallScreen, isMediumScreen),
        ),
        SizedBox(height: _verticalSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: _buildInfoCard(isSmallScreen, isMediumScreen),
        ),
        SizedBox(height: _verticalSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: _buildPrayerTimeCard(isSmallScreen, isMediumScreen),
        ),
        SizedBox(height: _verticalSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: _buildLastReadCard(isSmallScreen, isMediumScreen),
        ),
        SizedBox(height: _verticalSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: _buildMainMenu(isSmallScreen, isMediumScreen),
        ),
        SizedBox(height: _verticalSpacing),
      ],
    );
  }

  Widget _buildPremiumHeader(bool isSmallScreen, bool isMediumScreen) {
  return Stack(
    children: [
      // ✅ TAMBAHKAN ClipRRect di sini untuk mencegah overflow
      ClipRRect(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        child: AnimatedBuilder(
          animation: _shimmerAnimation ?? AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            final animValue = _shimmerAnimation?.value ?? 0.0;
            return Container(
              height: isSmallScreen ? 140 : 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF065F46)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(_cardBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge, // ✅ TAMBAHKAN INI
                children: [
                  // Shimmer effect
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_cardBorderRadius),
                      child: Transform.translate(
                        offset: Offset(animValue * 200, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.0),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Modern Islamic Pattern - Top Right
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.03),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.6, 1.0],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.star_outline_rounded,
                          size: 45,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),

                  // Modern Islamic Pattern - Bottom Left  
                  Positioned(
                    bottom: -15,
                    left: -15,
                    child: Stack(
                      children: [
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          top: 20,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Additional accent - subtle geometric lines
                  Positioned(
                    right: 30,
                    bottom: 30,
                    child: CustomPaint(
                      size: Size(40, 40),
                      painter: IslamicGeometricPainter(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      
      // Content layer
      Container(
        height: isSmallScreen ? 140 : 160,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... rest of your content
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getGreetingIcon(),
                          color: _getGreetingColor(),
                          size: isSmallScreen ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 14,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Text(
                          'Selamat ${_getGreetingTime()}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11.5 : 13.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Row(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: NotificationService.badgeCount,
                      builder: (context, unreadCount, child) {
                        return _buildActionButton(
                          icon: unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                          onTap: _openNotificationCenter,
                          hasNotification: unreadCount > 0,
                          notificationCount: unreadCount,
                          isSmallScreen: isSmallScreen,
                        );
                      },
                    ),
                    SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.more_vert_rounded,
                      onTap: _showMenuOptions,
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            Text(
              'Assalamu\'alaikum',
              style: TextStyle(
                fontSize: isSmallScreen ? 26.0 : 32.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.1,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            SizedBox(height: 6),
            Text(
              _randomGreeting,
              style: TextStyle(
                fontSize: isSmallScreen ? 13.0 : 14.5,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasNotification = false,
    int notificationCount = 0,
    required bool isSmallScreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.white, size: isSmallScreen ? 22 : 24),
              if (hasNotification && notificationCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: EdgeInsets.all(notificationCount > 9 ? 3 : 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFEF4444).withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 16 : 18,
                        minHeight: isSmallScreen ? 16 : 18,
                      ),
                      child: Center(
                        child: Text(
                          notificationCount > 99 ? '99+' : notificationCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: notificationCount > 9 ? 7 : 8,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
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

  Widget _buildInfoCard(bool isSmallScreen, bool isMediumScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
        border: Border.all(color: Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tanggal Hijriah & Masehi dalam 1 kolom
          _buildDateInfo(isSmallScreen, isMediumScreen),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildDivider(),
          SizedBox(height: isSmallScreen ? 10 : 12),
          // Lokasi
          _buildLocationInfo(context, isSmallScreen, isMediumScreen),
          SizedBox(height: isSmallScreen ? 10 : 12),
          _buildDivider(),
          SizedBox(height: isSmallScreen ? 10 : 12),
          // Mahfudzot
          _buildMahfudzotInfo(isSmallScreen, isMediumScreen),
        ],
      ),
    );
  }

  Widget _buildDateInfo(bool isSmallScreen, bool isMediumScreen) {
  return InkWell(
    onTap: () => _showHijriCalendar(context),  // Tambahkan onTap
    borderRadius: BorderRadius.circular(10),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: Color(0xFFD4AF37).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFFD4AF37),
            size: isSmallScreen ? 18 : 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getHijriDate(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : (isMediumScreen ? 14 : 15),
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                _getGregorianDate(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : (isMediumScreen ? 13 : 14),
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(  // Tambahkan ikon chevron
          Icons.chevron_right,
          color: Color(0xFF9CA3AF),
          size: 20,
        ),
      ],
    ),
  );
}
void _showHijriCalendar(BuildContext context) {
  final now = DateTime.now();
  final hijriNow = HijriCalendar.fromDate(now);
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => HijriCalendarBottomSheet(
      initialHijriDate: hijriNow,
    ),
  );
}
  Widget _buildMahfudzotInfo(bool isSmallScreen, bool isMediumScreen) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final mahfudzot = provider.dailyMahfudzot;
        
        if (provider.isLoadingMahfudzot) {
          return Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                   color: Color(0xFF059669).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: isSmallScreen ? 18 : 20,
                  height: isSmallScreen ? 18 : 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF059669),
                    strokeWidth: 2,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mahfudzot',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10.5 : 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Memuat...',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13.5 : (isMediumScreen ? 14.5 : 15.5),
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (mahfudzot == null) {
          return Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: Color(0xFF6B7280).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF6B7280),
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mahfudzot',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10.5 : 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tidak tersedia',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13.5 : (isMediumScreen ? 14.5 : 15.5),
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return InkWell(
          onTap: () => _showMahfudzotDetail(context, mahfudzot, isSmallScreen, isMediumScreen),
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: Color(0xFF6B7280).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF6B7280),
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mutiara Hari Ini',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10.5 : 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      mahfudzot['meaning'] ?? '',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13.5 : (isMediumScreen ? 14.5 : 15.5),
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF6B7280),
                size: isSmallScreen ? 18 : 20,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMahfudzotDetail(BuildContext context, Map<String, dynamic> mahfudzot, bool isSmallScreen, bool isMediumScreen) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF6B7280).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Nasihat Hari Ini',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Arabic Text
          Text(
            mahfudzot['arabic'] ?? '',
            style: TextStyle(
              fontFamily: 'Arabic',
              fontSize: isSmallScreen ? 22 : 24,
              height: 2.0,
                 color: Color.fromARGB(255, 77, 78, 81),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
          
          SizedBox(height: 16),
          
          // Latin Text
          Text(
            mahfudzot['latin'] ?? '',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 77, 78, 81),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          
          SizedBox(height: 8),
          
          // Meaning
          Text(
            mahfudzot['meaning'] ?? '',
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Color.fromARGB(255, 77, 78, 81),
              height: 1.5,
            ),
          ),
          
          SizedBox(height: 24),
          
          // Close Button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B7280),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Tutup',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
  );
}

// Update juga widget _buildMahfudzotInfo untuk konsistensi warna

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE5E7EB).withOpacity(0.0),
            Color(0xFFE5E7EB),
            Color(0xFFE5E7EB).withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(BuildContext context, bool isSmallScreen, bool isMediumScreen) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final locationData = provider.locationData;
        
        if (provider.isLoadingLocation) {
          return Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: isSmallScreen ? 18 : 20,
                  height: isSmallScreen ? 18 : 20,
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10.5 : 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Mencari lokasi...',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13.5 : (isMediumScreen ? 14.5 : 15.5),
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (locationData == null) {
          return InkWell(
            onTap: _refreshLocation,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_off_outlined,
                    color: Color(0xFFF59E0B),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lokasi',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10.5 : 11.5,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Aktifkan Lokasi',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13.5 : (isMediumScreen ? 14.5 : 15.5),
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFF59E0B),
                  size: isSmallScreen ? 14 : 16,
                ),
              ],
            ),
          );
        }

        return InkWell(
          onTap: () => showLocationDetail(
            context: context,
            locationData: locationData,
            onRefresh: _refreshLocation,
          ),
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: locationData.isFallback
                      ? Color(0xFFF59E0B).withOpacity(0.15)
                      : Color(0xFF059669).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  locationData.isFallback ? Icons.location_off : Icons.location_on,
                  color: locationData.isFallback ? Color(0xFFF59E0B) : Color(0xFF059669),
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10.5 : 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      locationData.displayName,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13.5 : (isMediumScreen ? 14.5 : 15.5),
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF6B7280),
                size: isSmallScreen ? 18 : 20,
              ),
            ],
          ),
        );
      },
    );
  }
  // ✅ IMPROVED _buildLastReadCard - REPLACE EXISTING METHOD
Widget _buildLastReadCard(bool isSmallScreen, bool isMediumScreen) {
  return Consumer<DashboardProvider>(
    builder: (context, provider, child) {
      final lastRead = provider.lastRead;
      final isLoading = provider.isLoadingLastRead;
      final isOverdue = _isMoreThanOneDayNotRead(lastRead);

      if (isLoading) {
        return _buildLoadingCard(isSmallScreen, isMediumScreen);
      }

      return _buildLastReadContent(
        lastRead: lastRead,
        isOverdue: isOverdue,
        isSmallScreen: isSmallScreen,
        isMediumScreen: isMediumScreen,
      );
    },
  );
}
// ✅ LOADING STATE
Widget _buildLoadingCard(bool isSmallScreen, bool isMediumScreen) {
  return Container(
    height: isSmallScreen ? 110 : 130,
    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_cardBorderRadius),
      border: Border.all(color: Color(0xFFE5E7EB), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: isSmallScreen ? 70 : 80,
          height: isSmallScreen ? 70 : 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 14 : 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[150],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
// ✅ MAIN CONTENT - ISLAMIC DESIGN WITH ANIMATIONS
Widget _buildLastReadContent({
  required BookmarkModel? lastRead,
  required bool isOverdue,
  required bool isSmallScreen,
  required bool isMediumScreen,
}) {
  final gradient = _getQuranGradient(isOverdue);
  final iconSize = isSmallScreen ? 70.0 : 80.0;

  return Container(
    height: isSmallScreen ? 110 : 130,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_cardBorderRadius),
      border: Border.all(
        color: isOverdue ? Color(0xFFEF4444).withOpacity(0.3) : Color(0xFFE5E7EB),
        width: isOverdue ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isOverdue 
            ? Color(0xFFEF4444).withOpacity(0.15)
            : Colors.black.withOpacity(0.06),
          blurRadius: isOverdue ? 16 : 12,
          offset: Offset(0, isOverdue ? 6 : 4),
          spreadRadius: isOverdue ? 1 : 0,
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_cardBorderRadius),
      child: InkWell(
        onTap: lastRead != null
            ? () {
                HapticFeedback.mediumImpact();
                _navigateToQuranRead(context);
              }
            : null,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        child: Stack(
          children: [
            // ✅ ISLAMIC PATTERN BACKGROUND
            _buildIslamicPattern(isOverdue),
            
            // ✅ MAIN CONTENT
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Row(
                children: [
                  // ✅ ANIMATED QURAN ICON
                  _buildAnimatedQuranIcon(
                    gradient: gradient,
                    isOverdue: isOverdue,
                    iconSize: iconSize,
                    isSmallScreen: isSmallScreen,
                  ),
                  
                  SizedBox(width: isSmallScreen ? 14 : 18),
                  
                  // ✅ TEXT CONTENT
                  Expanded(
                    child: _buildTextContent(
                      lastRead: lastRead,
                      isOverdue: isOverdue,
                      isSmallScreen: isSmallScreen,
                      isMediumScreen: isMediumScreen,
                    ),
                  ),
                  
                  SizedBox(width: 8),
                  
                  // ✅ ARROW ICON
                  if (lastRead != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isOverdue ? Color(0xFFEF4444) : AppColors.primary,
                      size: isSmallScreen ? 18 : 20,
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
// ✅ ISLAMIC PATTERN BACKGROUND
Widget _buildIslamicPattern(bool isOverdue) {
  return Positioned.fill(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(_cardBorderRadius),
      child: Stack(
        children: [
          // Subtle gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isOverdue
                    ? [
                        Color(0xFFEF4444).withOpacity(0.03),
                        Color(0xFFFEF2F2),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.02),
                        Colors.white,
                      ],
              ),
            ),
          ),
          
          // Islamic geometric pattern
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 100,
                color: isOverdue ? Color(0xFFEF4444) : AppColors.primary,
              ),
            ),
          ),
          
          // Decorative circles
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOverdue 
                  ? Color(0xFFEF4444).withOpacity(0.05)
                  : AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


// ✅ ANIMATED QURAN ICON WITH BREATHING EFFECT
Widget _buildAnimatedQuranIcon({
  required List<Color> gradient,
  required bool isOverdue,
  required double iconSize,
  required bool isSmallScreen,
}) {
  return AnimatedBuilder(
    animation: _quranBreathingAnimation,
    builder: (context, child) {
      return Transform.scale(
        scale: _quranBreathingAnimation.value,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ✅ MAIN ICON CONTAINER
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                    spreadRadius: isOverdue ? 2 : 0,
                  ),
                  // Inner glow effect
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(-2, -2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle border highlight
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                  
                  // Quran icon
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                      child: Image.asset(
                        AppAssets.iconQuran,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 36 : 42,
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Shine effect
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation ?? AlwaysStoppedAnimation(0.0),
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: [
                                0.0,
                                (_shimmerAnimation?.value ?? 0.0).clamp(0.0, 1.0),
                                1.0,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // ✅ OVERDUE BADGE (Warning Icon)
            if (isOverdue)
              Positioned(
                top: -6,
                right: -6,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: isSmallScreen ? 28 : 32,
                    height: isSmallScreen ? 28 : 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFF59E0B).withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}


// ✅ TEXT CONTENT
Widget _buildTextContent({
  required BookmarkModel? lastRead,
  required bool isOverdue,
  required bool isSmallScreen,
  required bool isMediumScreen,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Title with badge
      Row(
        children: [
          Expanded(
            child: Text(
              lastRead != null ? 'Lanjutkan Membaca' : 'Tilawah Hari Ini',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : (isMediumScreen ? 16 : 17),
                fontWeight: FontWeight.bold,
                color: isOverdue ? Color(0xFFEF4444) : Color(0xFF111827),
                letterSpacing: 0.3,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Days not read badge
          if (isOverdue && lastRead != null) ...[
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8,
                vertical: isSmallScreen ? 3 : 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _getDaysNotRead(lastRead),
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ],
      ),
      
      SizedBox(height: 6),
      
      // Subtitle
      Text(
        lastRead != null
            ? '${lastRead.surahName} - Ayat ${lastRead.ayahNumber}'
            : 'Mulai tilawah Al-Qur\'an hari ini',
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : (isMediumScreen ? 13 : 14),
          color: isOverdue && lastRead != null 
              ? Color(0xFFEF4444).withOpacity(0.8)
              : Color(0xFF6B7280),
          height: 1.3,
          fontWeight: isOverdue && lastRead != null 
              ? FontWeight.w600 
              : FontWeight.w500,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      
      // Motivational text if overdue
      if (isOverdue && lastRead != null) ...[
        SizedBox(height: 4),
        Text(
          'Yuk, lanjutkan bacaanmu! 📖',
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 11,
            color: Color(0xFFF59E0B),
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ],
  );
}
    Widget _buildPrayerTimeCard(bool isSmallScreen, bool isMediumScreen) {
  return Consumer<DashboardProvider>(
    builder: (context, provider, child) {
      final prayerTimeModel = provider.prayerTimeModel;
      final nextPrayerInfo = provider.nextPrayerInfo;
      final isLoading = provider.isLoadingPrayerTimes;

      if (isLoading) {
        return Container(
          height: isSmallScreen ? 80 : 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: isSmallScreen ? 24 : 28,
              height: isSmallScreen ? 24 : 28,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          ),
        );
      }

      if (prayerTimeModel == null || nextPrayerInfo == null) {
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gagal memuat waktu sholat',
                  style: TextStyle(
                    color: Color(0xFF424242),
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 18,
                isSmallScreen ? 14 : 16,
                isSmallScreen ? 14 : 16,
                isSmallScreen ? 14 : 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_cardBorderRadius),
                  topRight: Radius.circular(_cardBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.access_time_filled,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sholat Berikutnya',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                       
                        Text(
                          nextPrayerInfo.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        nextPrayerInfo.timeString,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 22 : 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          nextPrayerInfo.remainingTime,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _isPrayerExpanded = !_isPrayerExpanded;
                });
              },
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(_isPrayerExpanded ? 0 : _cardBorderRadius),
                bottomRight: Radius.circular(_isPrayerExpanded ? 0 : _cardBorderRadius),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 14 : 16,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isPrayerExpanded ? 'Sembunyikan' : 'Lihat Jadwal Lengkap',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      _isPrayerExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryDark,
                      size: isSmallScreen ? 16 : 18,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              child: _isPrayerExpanded
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 14,
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(_cardBorderRadius),
                          bottomRight: Radius.circular(_cardBorderRadius),
                        ),
                      ),
                      child: Column(
                        children: _buildAllPrayerRows(
                          prayerTimeModel.times,
                          nextPrayerInfo.name,
                          isSmallScreen,
                          isMediumScreen,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      );
    },
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ✅ FIXED: _buildAllPrayerRows & _buildPrayerRow
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 
// PASTE THESE 2 METHODS INTO dashboard_header.dart
// Replace the existing _buildAllPrayerRows and _buildPrayerRow
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ✅ Build all prayer rows in proper order with visual grouping
List<Widget> _buildAllPrayerRows(
  Map<String, TimeOfDay> times,
  String nextPrayerName,
  bool isSmallScreen,
  bool isMediumScreen,
) {
  final rows = <Widget>[];
  
  // Order of prayers to display
  final orderedPrayers = [
    'Tahajud',  // ✅ Included in display
    'Subuh',
    'Syuruk',
    'Duha',
    'Dzuhur',
    'Ashar',
    'Maghrib',
    'Isya',
  ];
  
  // ✅ CRITICAL FIX: Only Syuruk is informational (not a prayer time)
  // Tahajud and Duha ARE included in next prayer calculation
  final informationalOnly = {'Syuruk'}; // ONLY Syuruk is non-prayer
  
  for (int i = 0; i < orderedPrayers.length; i++) {
    final prayerName = orderedPrayers[i];
    final time = times[prayerName];
    
    if (time != null) {
      // Add divider before Duha and Dzuhur for visual grouping
      if (prayerName == 'Duha' || prayerName == 'Dzuhur') {
        rows.add(Padding(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[200],
          ),
        ));
      }
      
      rows.add(_buildPrayerRow(
        prayerName,
        time,
        nextPrayerName,
        isSmallScreen,
        isMediumScreen,
        isInformational: informationalOnly.contains(prayerName),
      ));
    }
  }
  
  return rows;
}

Widget _buildPrayerRow(
  String name,
  TimeOfDay time,
  String nextPrayerName,
  bool isSmallScreen,
  bool isMediumScreen, {
  bool isInformational = false, // Only true for Syuruk
}) {
  final isNext = name == nextPrayerName;
  final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  
  // ✅ Determine prayer type for styling
  final isSunnah = (name == 'Tahajud' || name == 'Duha'); // Sunnah prayers
  
  // Icons for different prayer times
  IconData getIcon() {
    switch (name) {
      case 'Tahajud':
        return Icons.nightlight;
      case 'Subuh':
        return Icons.nights_stay_outlined;
      case 'Syuruk':
        return Icons.wb_sunny_outlined;
      case 'Duha':
        return Icons.wb_twilight;
      case 'Dzuhur':
        return Icons.sunny;
      case 'Ashar':
        return Icons.wb_cloudy_outlined;
      case 'Maghrib':
        return Icons.wb_twilight;
      case 'Isya':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }
  
  // Label for special times
  String? getLabel() {
    switch (name) {
      case 'Tahajud':
        return 'Sepertiga Malam Terakhir';
      case 'Syuruk':
        return 'Terbit Matahari';
      case 'Duha':
        return 'Sholat Duha';
      default:
        return null;
    }
  }
  
  // ✅ Background color logic
  Color getBackgroundColor() {
    if (isNext) {
      return AppColors.primary.withOpacity(0.08); // Green for next prayer
    }
    if (isSunnah) {
      return Colors.purple[50]!; // Purple for sunnah (Tahajud, Duha)
    }
    if (isInformational) {
      return Colors.amber[50]!; // Amber for informational (Syuruk only)
    }
    return Colors.grey[50]!; // Grey for regular fardhu
  }
  
  // ✅ Icon color logic
  Color getIconColor() {
    if (isNext) {
      return AppColors.primary;
    }
    if (isSunnah) {
      return Colors.purple[700]!;
    }
    if (isInformational) {
      return Colors.amber[800]!;
    }
    return Color(0xFF616161);
  }
  
  // ✅ Icon background color logic
  Color getIconBackgroundColor() {
    if (isNext) {
      return AppColors.primary.withOpacity(0.15);
    }
    if (isSunnah) {
      return Colors.purple[100]!;
    }
    if (isInformational) {
      return Colors.amber[100]!;
    }
    return Colors.grey[200]!;
  }
  
  return Container(
    margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
    padding: EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 10 : 12,
      vertical: isSmallScreen ? 10 : 12,
    ),
    decoration: BoxDecoration(
      color: getBackgroundColor(),
      borderRadius: BorderRadius.circular(10),
      border: isNext
          ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
          : null,
    ),
    child: Row(
      children: [
        // Icon container
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 7),
          decoration: BoxDecoration(
            color: getIconBackgroundColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            getIcon(),
            size: isSmallScreen ? 16 : 18,
            color: getIconColor(),
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prayer name with optional badge
              Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                      color: isNext ? AppColors.primaryDark : Color(0xFF212121),
                    ),
                  ),
                  // ✅ SUNNAH Badge for Tahajud & Duha
                  if (isSunnah) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SUNNAH',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Label text
              if (getLabel() != null) ...[
                SizedBox(height: 2),
                Text(
                  getLabel()!,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: isSunnah 
                        ? Colors.purple[700]
                        : (isInformational ? Colors.amber[800] : Colors.grey[600]),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Time text
        Text(
          timeString,
          style: TextStyle(
            fontSize: isSmallScreen ? 15 : 16,
            fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
            color: isNext ? AppColors.primary : Color(0xFF424242),
            letterSpacing: 0.5,
          ),
        ),
        
        // Notification icon if next
        if (isNext) ...[
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              size: isSmallScreen ? 12 : 14,
              color: Colors.white,
            ),
          ),
        ],
      ],
    ),
  );
}
  

  Widget _buildMainMenu(bool isSmallScreen, bool isMediumScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.widgets_rounded,
                color: Color.fromARGB(255, 229, 229, 229),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                 color: Color.fromARGB(255, 229, 229, 229),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        _buildMenuItem(
          title: 'Al-Qur\'an',
          subtitle: 'Baca & Pahami Kitab Suci',
          customImage: AppAssets.iconQuran,
          gradient: AppColors.primaryGradient,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QuranMainPage()),
            );
          },
          isSmallScreen: isSmallScreen,
          isMediumScreen: isMediumScreen,
        ),
        SizedBox(height: 12),
        _buildMenuItem(
          title: 'Doa-Doa',
          subtitle: 'Kumpulan Doa Harian',
          icon: Icons.menu_book,
          gradient: AppColors.secondaryGradient,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DoaListPage()),
            );
          },
          isSmallScreen: isSmallScreen,
          isMediumScreen: isMediumScreen,
        ),
        SizedBox(height: 12),
        _buildMenuItem(
          title: 'Dzikir',
          subtitle: 'Dzikir Pagi & Petang',
          icon: Icons.wb_twilight_rounded,
          gradient: AppColors.purpleGradient,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DzikirMainPage()),
            );
          },
          isSmallScreen: isSmallScreen,
          isMediumScreen: isMediumScreen,
        ),
      ],
    );
  }

 Widget _buildMenuItem({
  required String title,
  required String subtitle,
  IconData? icon,
  String? customImage,
  required List<Color> gradient,
  required VoidCallback onTap,
  required bool isSmallScreen,
  required bool isMediumScreen,
}) {
  return ClipRRect( // ✅ WRAP dengan ClipRRect
    borderRadius: BorderRadius.circular(_cardBorderRadius),
    child: Container(
      height: isSmallScreen ? 120 : (isMediumScreen ? 130 : 140),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          child: Stack(
            clipBehavior: Clip.hardEdge, // ✅ TAMBAHKAN INI
            children: [
              // Islamic Geometric Pattern - Top Right
              Positioned(
                top: -25,
                right: -25,
                child: Stack(
                  children: [
                    // Outer circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 2,
                        ),
                      ),
                    ),
                    // Middle circle
                    Positioned(
                      left: 15,
                      top: 15,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Inner star/crescent accent
                    Positioned(
                      left: 30,
                      top: 30,
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.white.withOpacity(0.15),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),

              // Islamic Crescent Pattern - Bottom Left
              Positioned(
                bottom: -20,
                left: -20,
                child: Stack(
                  children: [
                    // Crescent moon shape
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.02),
                          ],
                        ),
                      ),
                    ),
                    // Inner crescent icon
                    Positioned(
                      left: 15,
                      top: 15,
                      child: Icon(
                        Icons.brightness_3_rounded,
                        color: Colors.white.withOpacity(0.12),
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ),

              // Decorative dots pattern (Islamic geometric style)
              Positioned(
                right: 40,
                bottom: 20,
                child: Column(
                  children: [
                    Row(
                      children: List.generate(
                        3,
                        (i) => Container(
                          width: 5,
                          height: 5,
                          margin: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: List.generate(
                        3,
                        (i) => Container(
                          width: 5,
                          height: 5,
                          margin: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Subtle Arabic calligraphy or mosque silhouette
              Positioned(
                left: 20,
                top: 20,
                child: Opacity(
                  opacity: 0.06,
                  child: Icon(
                    Icons.mosque_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMenuTextContent(title, subtitle, isSmallScreen, isMediumScreen),
                          _buildMenuButton(isSmallScreen),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    _buildMenuIcon(icon, customImage, isSmallScreen, isMediumScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildMenuTextContent(String title, String subtitle, bool isSmallScreen, bool isMediumScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : (isMediumScreen ? 22 : 24),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : (isMediumScreen ? 13 : 14),
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMenuButton(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 14,
        vertical: isSmallScreen ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mulai',
            style: TextStyle(
              fontSize: isSmallScreen ? 11.5 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: isSmallScreen ? 14 : 16,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(IconData? icon, String? customImage, bool isSmallScreen, bool isMediumScreen) {
    final iconSize = isSmallScreen ? 64 : (isMediumScreen ? 70 : 76);
    
    return Container(
      width: iconSize.toDouble(),
      height: iconSize.toDouble(),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: customImage != null
          ? Padding(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              child: Image.asset(
                customImage,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white.withOpacity(0.6),
                      size: isSmallScreen ? 32 : 36,
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: isSmallScreen ? 32 : (isMediumScreen ? 36 : 40),
              ),
            ),
    );
  }
 
  // ✅ SHOW TILAWAH REMINDER dengan Last Read Info
// ✅ COLLECTION GREETING MESSAGES - Bisa disesuaikan/ditambah
static const List<String> _morningGreetings = [
  'Semoga pagi Anda penuh berkah',
  'Awali hari dengan penuh semangat',
  'Semoga hari ini penuh kebaikan',
  'Pagi yang indah untuk beribadah',
  'Raih keberkahan di pagi hari',
  'Mulai hari dengan bismillah',
  'Semoga dipermudah segala urusan',
  'Pagi cerah penuh harapan',
];

static const List<String> _afternoonGreetings = [
  'Semoga siang Anda produktif',
  'Tetap semangat di siang hari',
  'Luangkan waktu untuk sholat',
  'Jaga ibadah di tengah kesibukan',
  'Semoga dimudahkan segala urusan',
  'Siang yang penuh berkah',
  'Istirahat sejenak untuk dzikir',
  'Jangan lupa istirahat sejenak',
];

static const List<String> _eveningGreetings = [
  'Semoga sore Anda menyenangkan',
  'Nikmati ketenangan sore hari',
  'Persiapkan ibadah maghrib',
  'Tutup hari dengan penuh syukur',
  'Semoga sore penuh kedamaian',
  'Waktunya refleksi diri',
  'Akhiri hari dengan amal baik',
  'Sore yang penuh keberkahan',
];

static const List<String> _nightGreetings = [
  'Semoga malam penuh ketenangan',
  'Istirahat yang cukup yaa',
  'Jangan lupa sholat isya',
  'Malam untuk mendekatkan diri',
  'Semoga bermimpi indah',
  'Tutup hari dengan dzikir',
  'Malam yang penuh berkah',
  'Istirahat dengan hati tenang',
];
}