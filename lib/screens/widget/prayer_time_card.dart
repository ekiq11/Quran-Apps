// screens/dashboard/widgets/prayer_time_card.dart
import 'package:flutter/material.dart';
import 'package:myquran/model/prayer_time_model.dart';
import 'package:myquran/screens/util/constants.dart';

class PrayerTimeCard extends StatefulWidget {
  final PrayerTimeModel? prayerTimeModel;
  final NextPrayerInfo? nextPrayerInfo;
  final bool isLoading;

  const PrayerTimeCard({
    Key? key,
    required this.prayerTimeModel,
    required this.nextPrayerInfo,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<PrayerTimeCard> createState() => _PrayerTimeCardState();
}

class _PrayerTimeCardState extends State<PrayerTimeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingCard(context);
    }

    if (widget.prayerTimeModel == null || widget.nextPrayerInfo == null) {
      return _buildErrorCard(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / 375; // Base width 375 (iPhone X)
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.paddingLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8 * scale,
                offset: Offset(0, 2 * scale),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header dengan waktu dan waktu tersisa
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 16 * scale,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.paddingLarge),
                    topRight: Radius.circular(AppDimensions.paddingLarge),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      color: Colors.white,
                      size: 22 * scale,
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sholat Berikutnya',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            widget.nextPrayerInfo!.name,
                            style: TextStyle(
                              fontSize: 20 * scale,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.nextPrayerInfo!.timeString,
                          style: TextStyle(
                            fontSize: 24 * scale,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * scale,
                            vertical: 4 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6 * scale),
                          ),
                          child: Text(
                            widget.nextPrayerInfo!.remainingTime,
                            style: TextStyle(
                              fontSize: 11 * scale,
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

              // Tombol expand/collapse
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.paddingLarge),
                  bottomRight: Radius.circular(AppDimensions.paddingLarge),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scale,
                    vertical: 12 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppDimensions.paddingLarge),
                      bottomRight: Radius.circular(AppDimensions.paddingLarge),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? 'Sembunyikan' : 'Lihat Jadwal Lengkap',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primaryDark,
                        size: 18 * scale,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded List
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                child: _isExpanded
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14 * scale,
                          vertical: 12 * scale,
                        ),
                        child: Column(
                          children: widget.prayerTimeModel!.times.entries
                              .where((e) => e.key != 'Terbit')
                              .map((entry) => _buildCompactRow(
                                    entry.key,
                                    entry.value,
                                    scale,
                                  ))
                              .toList(),
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

  Widget _buildCompactRow(String name, TimeOfDay time, double scale) {
    final isNext = widget.nextPrayerInfo!.name == name;
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.only(bottom: 10 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: isNext ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(AppDimensions.paddingMedium),
        border: isNext
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: isNext ? AppColors.primary : Colors.grey[300],
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            child: Icon(
              _getPrayerIcon(name),
              color: isNext ? Colors.white : Colors.grey[600],
              size: 18 * scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
                color: isNext ? AppColors.primaryDark : Color(0xFF424242),
              ),
            ),
          ),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 17 * scale,
              fontWeight: FontWeight.bold,
              color: isNext ? AppColors.primaryDark : Color(0xFF424242),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildLoadingCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375;
    
    return Container(
      height: 90 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.paddingLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 28 * scale,
          height: 28 * scale,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18 * scale,
        vertical: 16 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.paddingLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 24 * scale,
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              'Gagal memuat waktu sholat',
              style: TextStyle(
                color: Color(0xFF424242),
                fontSize: 13 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}