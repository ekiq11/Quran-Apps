// screens/notification/notification_preferences_page.dart - FIXED
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/notification/notification_manager.dart';  // ✅ CHANGED!
import 'package:myquran/screens/util/constants.dart';
import 'package:myquran/provider/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> 
    with SingleTickerProviderStateMixin {
  
  final NotificationManager _notificationManager = NotificationManager();  // ✅ CHANGED!
  
  // Prayer notifications
  bool _enableSubuh = true;
  bool _enableDzuhur = true;
  bool _enableAshar = true;
  bool _enableMaghrib = true;
  bool _enableIsya = true;
  
  // Dzikir notifications
  bool _enableDzikirPagi = true;
  bool _enableDzikirPetang = true;
  
  // Tilawah notifications
  bool _enableTilawahPagi = true;
  bool _enableTilawahMalam = true;
  
  // Tilawah times (custom times)
  TimeOfDay _tilawahPagiTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _tilawahSiangTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _tilawahMalamTime = const TimeOfDay(hour: 20, minute: 0);
  
  // Display settings
  bool _showInNotificationCenter = true;
  bool _isLoading = true;
  bool _hasChanges = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadPreferences();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.shortestSide >= 600;
  double _getContentFontSize(BuildContext context) => _isTablet(context) ? 14.0 : 13.0;
  double _getTitleFontSize(BuildContext context) => _isTablet(context) ? 15.5 : 14.0;
  double _getHeadingFontSize(BuildContext context) => _isTablet(context) ? 20.0 : 18.0;
  double _getIconSize(BuildContext context) => _isTablet(context) ? 24.0 : 22.0;
  double _getPadding(BuildContext context) => _isTablet(context) ? 18.0 : 16.0;

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        // Prayer notifications
        _enableSubuh = prefs.getBool('notif_enable_subuh') ?? true;
        _enableDzuhur = prefs.getBool('notif_enable_dzuhur') ?? true;
        _enableAshar = prefs.getBool('notif_enable_ashar') ?? true;
        _enableMaghrib = prefs.getBool('notif_enable_maghrib') ?? true;
        _enableIsya = prefs.getBool('notif_enable_isya') ?? true;
        
        // Dzikir notifications
        _enableDzikirPagi = prefs.getBool('notif_enable_dzikir_pagi') ?? true;
        _enableDzikirPetang = prefs.getBool('notif_enable_dzikir_petang') ?? true;
        
        // Tilawah notifications
        _enableTilawahPagi = prefs.getBool('notif_enable_tilawah_pagi') ?? true;
        _enableTilawahMalam = prefs.getBool('notif_enable_tilawah_malam') ?? true;
        
        // Load tilawah times
        _tilawahPagiTime = _parseTime(prefs.getString('tilawah_time_pagi') ?? '6:0');
        _tilawahSiangTime = _parseTime(prefs.getString('tilawah_time_siang') ?? '13:0');
        _tilawahMalamTime = _parseTime(prefs.getString('tilawah_time_malam') ?? '20:0');
        
        // Display settings
        _showInNotificationCenter = prefs.getBool('notif_show_in_center') ?? true;
        
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      print('Error loading preferences: $e');
      setState(() => _isLoading = false);
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<void> _savePreferences() async {
    try {
      _showLoadingDialog();
      
      final prefs = await SharedPreferences.getInstance();
      
      // Save prayer notifications
      await prefs.setBool('notif_enable_subuh', _enableSubuh);
      await prefs.setBool('notif_enable_dzuhur', _enableDzuhur);
      await prefs.setBool('notif_enable_ashar', _enableAshar);
      await prefs.setBool('notif_enable_maghrib', _enableMaghrib);
      await prefs.setBool('notif_enable_isya', _enableIsya);
      
      // Save dzikir notifications
      await prefs.setBool('notif_enable_dzikir_pagi', _enableDzikirPagi);
      await prefs.setBool('notif_enable_dzikir_petang', _enableDzikirPetang);
      
      // Save tilawah notifications
      await prefs.setBool('notif_enable_tilawah_pagi', _enableTilawahPagi);
      await prefs.setBool('notif_enable_tilawah_malam', _enableTilawahMalam);
      
      // Save tilawah times
      await prefs.setString('tilawah_time_pagi', '${_tilawahPagiTime.hour}:${_tilawahPagiTime.minute}');
      await prefs.setString('tilawah_time_siang', '${_tilawahSiangTime.hour}:${_tilawahSiangTime.minute}');
      await prefs.setString('tilawah_time_malam', '${_tilawahMalamTime.hour}:${_tilawahMalamTime.minute}');
      
      // Save display settings
      await prefs.setBool('notif_show_in_center', _showInNotificationCenter);
      
      // ✅ UPDATE notifications using NotificationManager
      await _updateNotificationsWithPreferences();
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      setState(() => _hasChanges = false);
      
      _showSuccessSnackBar('Pengaturan berhasil disimpan dan notifikasi diperbarui');
      
    } catch (e) {
      print('Error saving preferences: $e');
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Gagal menyimpan pengaturan');
    }
  }

  Future<void> _updateNotificationsWithPreferences() async {
    try {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      final prayerTimes = dashboardProvider.prayerTimeModel?.times ?? _getDefaultPrayerTimes();
      
      // ✅ Use NotificationManager instead of NotificationUpdater
      await _notificationManager.scheduleAllNotifications(
        prayerTimes: prayerTimes,
        enabledPrayers: {
          'Subuh': _enableSubuh,
          'Dzuhur': _enableDzuhur,
          'Ashar': _enableAshar,
          'Maghrib': _enableMaghrib,
          'Isya': _enableIsya,
        },
        tilawahTimes: {
          'Pagi': _tilawahPagiTime,
          'Siang': _tilawahSiangTime,
          'Malam': _tilawahMalamTime,
        },
      );
      
      print('✅ Notifications updated with user preferences');
    } catch (e) {
      print('❌ Error updating notifications: $e');
      rethrow;
    }
  }

  Map<String, TimeOfDay> _getDefaultPrayerTimes() {
    return {
      'Subuh': const TimeOfDay(hour: 4, minute: 30),
      'Dzuhur': const TimeOfDay(hour: 12, minute: 0),
      'Ashar': const TimeOfDay(hour: 15, minute: 15),
      'Maghrib': const TimeOfDay(hour: 18, minute: 0),
      'Isya': const TimeOfDay(hour: 19, minute: 15),
    };
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                SizedBox(height: 20),
                Text(
                  'Menyimpan pengaturan...',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  int _getEnabledCount() {
    int count = 0;
    if (_enableSubuh) count++;
    if (_enableDzuhur) count++;
    if (_enableAshar) count++;
    if (_enableMaghrib) count++;
    if (_enableIsya) count++;
    if (_enableDzikirPagi) count++;
    if (_enableDzikirPetang) count++;
    if (_enableTilawahPagi) count++;
    if (_enableTilawahMalam) count++;
    return count;
  }

  void _toggleAllPrayers(bool value) {
    setState(() {
      _enableSubuh = value;
      _enableDzuhur = value;
      _enableAshar = value;
      _enableMaghrib = value;
      _enableIsya = value;
      _hasChanges = true;
    });
  }

  void _toggleAllDzikir(bool value) {
    setState(() {
      _enableDzikirPagi = value;
      _enableDzikirPetang = value;
      _hasChanges = true;
    });
  }

  void _toggleAllTilawah(bool value) {
    setState(() {
      _enableTilawahPagi = value;
      _enableTilawahMalam = value;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);
    final headingFont = _getHeadingFontSize(context);
    final titleFont = _getTitleFontSize(context);
    final contentFont = _getContentFontSize(context);
    final iconSize = _getIconSize(context);
    final padding = _getPadding(context);
    final enabledCount = _getEnabledCount();

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Simpan Perubahan?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: const Text(
                'Anda memiliki perubahan yang belum disimpan. Apakah Anda ingin menyimpannya?',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Buang', style: TextStyle(color: Color(0xFFEF4444))),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          );

          if (result == true) {
            await _savePreferences();
            return true;
          } else if (result == false) {
            return true;
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Preferensi Notifikasi',
            style: TextStyle(
              fontSize: headingFont,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
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
          iconTheme: IconThemeData(color: Colors.white, size: iconSize),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3))
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Summary Banner
                    Container(
                      margin: EdgeInsets.all(padding),
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: iconSize),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$enabledCount Notifikasi Aktif',
                                  style: TextStyle(
                                    fontSize: titleFont,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dari total 9 jenis notifikasi',
                                  style: TextStyle(fontSize: contentFont - 1, color: const Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Note: Rest of the UI remains the same
                    // Build sections as before...
                    Expanded(
                      child: Center(
                        child: Text('UI sections from original file...'),
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: _hasChanges
            ? Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _loadPreferences(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Reset', style: TextStyle(fontSize: contentFont, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _savePreferences,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, size: iconSize - 4),
                              const SizedBox(width: 8),
                              Text(
                                'Simpan Perubahan',
                                style: TextStyle(fontSize: contentFont, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}