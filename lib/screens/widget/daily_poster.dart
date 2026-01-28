// ✅ POSTER NASIHAT HARIAN - Responsive & Beautiful Design
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DailyAdvicePosterPage extends StatefulWidget {
  final String hijriDate; // "3 Syaban 1447 H"
  final String gregorianDate; // "22 Januari 2026"
  final String advice;
  final String source;

  const DailyAdvicePosterPage({
    Key? key,
    required this.hijriDate,
    required this.gregorianDate,
    required this.advice,
    required this.source,
  }) : super(key: key);

  @override
  State<DailyAdvicePosterPage> createState() => _DailyAdvicePosterPageState();
}

class _DailyAdvicePosterPageState extends State<DailyAdvicePosterPage> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;
  int _selectedBackground = 0;

  // ✅ BACKGROUND THEMES dengan kontras tinggi
  final List<Map<String, dynamic>> _backgrounds = [
    {
      'name': 'Teal Ocean',
      'gradient': [Color(0xFF0D9488), Color(0xFF0E7490), Color(0xFF0C4A6E)],
      'textColor': Colors.white,
    },
    {
      'name': 'Purple Night',
      'gradient': [Color(0xFF7C3AED), Color(0xFF5B21B6), Color(0xFF4C1D95)],
      'textColor': Colors.white,
    },
    {
      'name': 'Emerald Forest',
      'gradient': [Color(0xFF059669), Color(0xFF047857), Color(0xFF065F46)],
      'textColor': Colors.white,
    },
    {
      'name': 'Royal Blue',
      'gradient': [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF1E40AF)],
      'textColor': Colors.white,
    },
    {
      'name': 'Rose Gold',
      'gradient': [Color(0xFFE11D48), Color(0xFFBE123C), Color(0xFF9F1239)],
      'textColor': Colors.white,
    },
    {
      'name': 'Golden Sand',
      'gradient': [Color(0xFFD97706), Color(0xFFB45309), Color(0xFF92400E)],
      'textColor': Colors.white,
    },
    {
      'name': 'Deep Navy',
      'gradient': [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
      'textColor': Colors.white,
    },
    {
      'name': 'Sunset Orange',
      'gradient': [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF9A3412)],
      'textColor': Colors.white,
    },
  ];

  Future<void> _shareAsImage() async {
    if (!mounted) return;
    setState(() => _isSharing = true);
    
    try {
      await Future.delayed(Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      final RenderObject? renderObject = _repaintKey.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        if (mounted) setState(() => _isSharing = false);
        throw Exception('Render boundary tidak ditemukan');
      }
      
      final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        if (mounted) setState(() => _isSharing = false);
        throw Exception('Gagal convert gambar');
      }
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${directory.path}/nasihat_${timestamp}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Nasihat Harian - ${widget.hijriDate}\n\nDibagikan dari Bekal Muslim',
      );

      if (mounted) {
        setState(() => _isSharing = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Nasihat berhasil dibagikan!'),
              ],
            ),
            backgroundColor: Color(0xFFD4AF37),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }

      Future.delayed(Duration(seconds: 10), () {
        if (imageFile.existsSync()) imageFile.delete();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSharing = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Gagal membagikan: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showBackgroundSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Color(0xFF1E293B),
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
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Pilih Background',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _backgrounds.length,
                itemBuilder: (context, index) {
                  final bg = _backgrounds[index];
                  final isSelected = _selectedBackground == index;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedBackground = index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: bg['gradient'] as List<Color>,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Color(0xFFD4AF37) : Colors.white24,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 28)
                          : null,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    
    // ✅ Responsive poster dimensions
    final posterWidth = screenWidth * 0.92;
    final posterHeight = screenHeight * 0.75;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: _DailyAdvicePoster(
                hijriDate: widget.hijriDate,
                gregorianDate: widget.gregorianDate,
                advice: widget.advice,
                source: widget.source,
                width: posterWidth,
                height: posterHeight,
                backgroundGradient: _backgrounds[_selectedBackground]['gradient'] as List<Color>,
                textColor: _backgrounds[_selectedBackground]['textColor'] as Color,
              ),
            ),
          ),
          
          // TOP BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: screenWidth * 0.06),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.palette_rounded, color: Colors.white, size: screenWidth * 0.06),
                      onPressed: _showBackgroundSelector,
                      tooltip: 'Ganti Background',
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // BOTTOM BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.065,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareAsImage,
                    icon: _isSharing
                        ? SizedBox(
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Icon(Icons.share_rounded, size: screenWidth * 0.06),
                    label: Text(
                      _isSharing ? 'Membagikan...' : 'Bagikan Sekarang',
                      style: TextStyle(
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Color(0xFFD4AF37).withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ RESPONSIVE POSTER DESIGN
class _DailyAdvicePoster extends StatelessWidget {
  final String hijriDate;
  final String gregorianDate;
  final String advice;
  final String source;
  final double width;
  final double height;
  final List<Color> backgroundGradient;
  final Color textColor;

  const _DailyAdvicePoster({
    required this.hijriDate,
    required this.gregorianDate,
    required this.advice,
    required this.source,
    required this.width,
    required this.height,
    required this.backgroundGradient,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final baseFontSize = width * 0.04;
    final titleFontSize = baseFontSize * 3.5;
    final dateFontSize = baseFontSize * 1.1;
    final adviceFontSize = baseFontSize * 1.05;
    final sourceFontSize = baseFontSize * 0.85;
    final padding = width * 0.055;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ISLAMIC PATTERN OVERLAY
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Opacity(
                opacity: 0.12,
                child: CustomPaint(
                  painter: _IslamicPatternPainter(),
                ),
              ),
            ),
          ),
          
          // DECORATIVE CIRCLES
          Positioned(
            top: -width * 0.2,
            right: -width * 0.2,
            child: Container(
              width: width * 0.55,
              height: width * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFD4AF37).withOpacity(0.15),
                    Color(0xFFD4AF37).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: -width * 0.15,
            left: -width * 0.15,
            child: Container(
              width: width * 0.45,
              height: width * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // MAIN CONTENT
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  SizedBox(height: height * 0.02),
                  
                  // ✅ LOGO BEKAL MUSLIM
                  Container(
                    width: width * 0.18,
                    height: width * 0.18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFD4AF37).withOpacity(0.4),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/other/icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: height * 0.025),
                  
                  // HIJRI DATE - BIG & BOLD
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.065,
                      vertical: height * 0.025,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFFB8941F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(width * 0.04),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFD4AF37).withOpacity(0.5),
                          blurRadius: 25,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          hijriDate.split(' ').first,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 0.95,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: height * 0.005),
                        Text(
                          hijriDate.substring(hijriDate.indexOf(' ') + 1),
                          style: TextStyle(
                            fontSize: dateFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: height * 0.005),
                        Text(
                          gregorianDate,
                          style: TextStyle(
                            fontSize: dateFontSize * 0.75,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: height * 0.035),
                  
                  // DIVIDER ISLAMI
                  _buildDivider(width),
                  
                  SizedBox(height: height * 0.035),
                  
                  // ADVICE CONTENT
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(padding * 0.95),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(width * 0.045),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // QUOTE ICON
                            Icon(
                              Icons.format_quote,
                              size: width * 0.085,
                              color: Color(0xFFD4AF37).withOpacity(0.8),
                            ),
                            
                            SizedBox(height: height * 0.02),
                            
                            // ADVICE TEXT
                            Text(
                              advice,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: adviceFontSize,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                height: 1.7,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: height * 0.025),
                            
                            // SOURCE
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.045,
                                vertical: height * 0.012,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFFB8941F),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(width * 0.03),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFD4AF37).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: sourceFontSize * 1.1,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: width * 0.015),
                                  Flexible(
                                    child: Text(
                                      source,
                                      style: TextStyle(
                                        fontSize: sourceFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: height * 0.025),
                  
                  // FOOTER BRANDING
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: height * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Bekal Muslim',
                          style: TextStyle(
                            fontSize: baseFontSize * 0.9,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: width * 0.02),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.02,
                            vertical: height * 0.004,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'DOWNLOAD GRATIS',
                            style: TextStyle(
                              fontSize: baseFontSize * 0.6,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: height * 0.01),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: width * 0.01,
          height: width * 0.01,
          decoration: BoxDecoration(
            color: Color(0xFFD4AF37).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: width * 0.02),
        Container(
          width: width * 0.15,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD4AF37).withOpacity(0.3),
                Color(0xFFD4AF37),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: width * 0.015),
        Icon(
          Icons.circle,
          size: width * 0.015,
          color: Color(0xFFD4AF37),
        ),
        SizedBox(width: width * 0.015),
        Container(
          width: width * 0.15,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD4AF37),
                Color(0xFFD4AF37).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: width * 0.02),
        Container(
          width: width * 0.01,
          height: width * 0.01,
          decoration: BoxDecoration(
            color: Color(0xFFD4AF37).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// ✅ ISLAMIC PATTERN PAINTER
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const spacing = 55.0;
    
    for (double y = 0; y < size.height + spacing; y += spacing) {
      for (double x = 0; x < size.width + spacing; x += spacing) {
        _drawStar(canvas, paint, Offset(x, y), 20);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    const points = 8;
    final path = Path();
    
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * 3.14159 / points) - 3.14159 / 2;
      final r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + r * angle.cos();
      final y = center.dy + r * angle.sin();
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Extension for trigonometric functions
extension NumExtension on num {
  double cos() => this * (180 / 3.14159);
  double sin() => this * (180 / 3.14159);
}