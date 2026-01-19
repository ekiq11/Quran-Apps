// notification/prayer_notification_handler.dart - WITH STOP BUTTON
import 'package:flutter/material.dart';



class PrayerNotificationHandler {
  static final PrayerNotificationHandler _instance = PrayerNotificationHandler._internal();
  factory PrayerNotificationHandler() => _instance;
  PrayerNotificationHandler._internal();


  
  /// Show full-screen adhan dialog with auto-play
  static Future<void> showAdhanDialog(
    BuildContext context, {
    required String prayerName,
    required String prayerTime,
  }) async {
    final handler = PrayerNotificationHandler();
    
    // Adzan sudah auto-play dari notifikasi
    // Tidak perlu play lagi di sini
    
    // Show full-screen dialog
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: true, // ✅ Bisa dismiss dengan tap di luar
      builder: (context) => WillPopScope(
        onWillPop: () async {
          // ✅ Stop adhan when dialog dismissed (back button)

          return true;
        },
        child: _AdhanDialogContent(
          prayerName: prayerName,
          prayerTime: prayerTime,
          onClose: () async {
            // ✅ Stop adhan when close button pressed
     
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
    
    // ✅ IMPORTANT: Stop adzan after dialog closed (jika belum di-stop)
  
  }
}

// ========== DIALOG WIDGET ==========

class _AdhanDialogContent extends StatefulWidget {
  final String prayerName;
  final String prayerTime;
  final VoidCallback onClose;

  const _AdhanDialogContent({
    required this.prayerName,
    required this.prayerTime,

    required this.onClose,
  });

  @override
  State<_AdhanDialogContent> createState() => _AdhanDialogContentState();
}

class _AdhanDialogContentState extends State<_AdhanDialogContent> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
    
    // Listen to playback state
  
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: isTablet ? 500 : size.width * 0.9,
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF059669),
                  Color(0xFF047857),
                  Color(0xFF065F46),
                ],
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
                // ========== ICON ==========
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mosque_rounded,
                    size: isTablet ? 80 : 64,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: isTablet ? 28 : 24),
                
                // ========== TITLE ==========
                Text(
                  'Waktu Sholat',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.5,
                  ),
                ),
                
                SizedBox(height: isTablet ? 12 : 8),
                
                // ========== PRAYER NAME ==========
                Text(
                  widget.prayerName,
                  style: TextStyle(
                    fontSize: isTablet ? 42 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isTablet ? 16 : 12),
                
                // ========== TIME ==========
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 28 : 24,
                    vertical: isTablet ? 14 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: isTablet ? 26 : 22,
                      ),
                      SizedBox(width: 12),
                      Text(
                        widget.prayerTime,
                        style: TextStyle(
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      
                    ],
                  ),
                ),
                
                SizedBox(height: isTablet ? 28 : 24),
                
                // ========== MESSAGE ==========
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🤲',
                        style: TextStyle(fontSize: isTablet ? 32 : 28),
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        'Mari Segera Tunaikan Sholat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Sholat adalah tiang agama',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 13,
                          color: Colors.white.withOpacity(0.85),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isTablet ? 32 : 28),
                
                // ========== AUDIO INDICATOR ==========
                if (_isPlaying)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSoundWave(isTablet),
                      SizedBox(width: 8),
                      _buildSoundWave(isTablet, delay: 200),
                      SizedBox(width: 8),
                      _buildSoundWave(isTablet, delay: 400),
                      SizedBox(width: 16),
                      Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: isTablet ? 26 : 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Adzan sedang diputar...',
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                
                if (_isPlaying) SizedBox(height: isTablet ? 32 : 28),
                
                // ========== ACTION BUTTONS ==========
                Row(
                  children: [
                    // ✅ CLOSE BUTTON - Stop adzan otomatis
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF047857),
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 18 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPlaying ? Icons.stop_rounded : Icons.check_rounded,
                              size: isTablet ? 26 : 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              _isPlaying ? 'Stop & Tutup' : 'OK',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
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

  Widget _buildSoundWave(bool isTablet, {int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: isTablet ? 6 : 4,
          height: (isTablet ? 24 : 20) * value,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
      onEnd: () {
        // Repeat animation
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted && _isPlaying) {
            setState(() {});
          }
        });
      },
    );
  }
}