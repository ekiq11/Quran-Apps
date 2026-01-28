// lib/widgets/location_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/services/location_service.dart';
import 'package:intl/intl.dart';

class LocationDetailSheet extends StatelessWidget {
  final LocationData locationData;
  final VoidCallback onRefresh;

  const LocationDetailSheet({
    Key? key,
    required this.locationData,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header hijau dengan gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                SizedBox(height: 12),
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                
                // Icon & Title
                Row(
                  children: [
                    SizedBox(width: 20),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Lokasi',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            locationData.isFallback 
                                ? 'Lokasi Default' 
                                : 'Lokasi Terkini Anda',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close_rounded, color: Colors.white),
                      padding: EdgeInsets.all(8),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),

          // Content putih
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main location card
                  _buildMainLocationCard(isSmallScreen),
                  
                  SizedBox(height: 16),

                  // Location Details
                  _buildDetailItem(
                    icon: Icons.location_city_rounded,
                    label: 'Kota/Wilayah',
                    value: locationData.city ?? locationData.locationName,
                    iconColor: Color(0xFF3B82F6),
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: 16),

                  _buildDetailItem(
                    icon: Icons.home_rounded,
                    label: 'Alamat Lengkap',
                    value: locationData.address ?? locationData.locationName,
                    iconColor: Color(0xFF8B5CF6),
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: 16),

                  _buildDetailItem(
                    icon: Icons.public_rounded,
                    label: 'Negara',
                    value: locationData.country ?? 'Indonesia',
                    iconColor: Color(0xFFEC4899),
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: 16),

                  // Koordinat
                  _buildCoordinatesCard(isSmallScreen),
                  
                  SizedBox(height: 16),

                  // Status indicator
                  _buildStatusCard(isSmallScreen),

                  SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          label: 'Tutup',
                          icon: Icons.close_rounded,
                          color: Color(0xFF6B7280),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          label: 'Perbarui Lokasi',
                          icon: Icons.refresh_rounded,
                          color: Color(0xFF059669),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                            onRefresh();
                          },
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainLocationCard(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF059669).withOpacity(0.1),
            Color(0xFF047857).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF059669).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF059669),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF059669).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.place_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Saat Ini',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      locationData.displayName,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required bool isSmallScreen,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: isSmallScreen ? 20 : 22),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinatesCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gps_fixed_rounded, 
                   size: isSmallScreen ? 16 : 18, 
                   color: Color(0xFF6B7280)),
              SizedBox(width: 8),
              Text(
                'Koordinat GPS',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latitude',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      locationData.latitude.toStringAsFixed(6),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Longitude',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      locationData.longitude.toStringAsFixed(6),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isSmallScreen) {
    final isActive = !locationData.isFallback;
    final lastUpdate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(locationData.timestamp);
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive 
            ? Color(0xFF059669).withOpacity(0.1) 
            : Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? Color(0xFF059669).withOpacity(0.2) 
              : Color(0xFFF59E0B).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? Color(0xFF059669) : Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Lokasi Aktif' : 'Lokasi Default',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Color(0xFF059669) : Color(0xFFF59E0B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  isActive 
                      ? 'Terakhir diperbarui: $lastUpdate'
                      : 'Menggunakan lokasi default Jakarta',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 14,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to show the bottom sheet
void showLocationDetail({
  required BuildContext context,
  required LocationData locationData,
  required VoidCallback onRefresh,
}) {
  HapticFeedback.lightImpact();
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => LocationDetailSheet(
      locationData: locationData,
      onRefresh: onRefresh,
    ),
  );
}