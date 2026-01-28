// lib/services/location_service.dart - UPDATED WITH GEOCODING
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String _keyLatitude = 'cached_latitude';
  static const String _keyLongitude = 'cached_longitude';
  static const String _keyLocationName = 'cached_location_name';
  static const String _keyCity = 'cached_city'; // ✅ NEW
  static const String _keyAddress = 'cached_address'; // ✅ NEW
  static const String _keyCountry = 'cached_country'; // ✅ NEW
  static const String _keyLastUpdate = 'location_last_update';
  
  // Cache duration: 6 hours (lebih lama karena lokasi jarang berubah)
  static const Duration _cacheDuration = Duration(hours: 6);

  // Get current location with caching and geocoding
  Future<LocationData> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = await _getCachedLocation();
      if (cached != null) {
        print('📍 Using cached location: ${cached.displayName}');
        return cached;
      }
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services disabled, using fallback');
        return _getFallbackLocation();
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied, using fallback');
          return _getFallbackLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission denied forever, using fallback');
        return _getFallbackLocation();
      }

      print('🔍 Getting current position...');
      // Get position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Location timeout');
          throw TimeoutException('Location request timeout');
        },
      );

      print('✅ Position found: ${position.latitude}, ${position.longitude}');

      // ✅ Get address from coordinates
      final addressData = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: addressData['locationName'] ?? 'Unknown Location',
        city: addressData['city'],
        address: addressData['address'],
        country: addressData['country'],
        timestamp: DateTime.now(),
      );

      // Cache the location
      await _cacheLocation(locationData);

      print('✅ Location updated: ${locationData.displayName}');
      return locationData;
    } catch (e) {
      print('❌ Error getting location: $e');
      // Try to use cached location even if expired
      final cached = await _getCachedLocation(ignoreExpiry: true);
      if (cached != null) {
        print('⚠️ Using expired cache due to error');
        return cached;
      }
      return _getFallbackLocation();
    }
  }

  // ✅ NEW: Get address from coordinates using reverse geocoding
  Future<Map<String, String?>> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      print('🔄 Reverse geocoding: $latitude, $longitude');
      
      // Get placemarks (geocoding 4.x doesn't support localeIdentifier)
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        print('⚠️ No placemarks found');
        return {
          'locationName': 'Lokasi Tidak Diketahui',
          'city': null,
          'address': null,
          'country': null,
        };
      }

      final place = placemarks.first;
      
      // Build location name with priority: locality > subAdministrativeArea > administrativeArea
      String locationName = 'Lokasi Tidak Diketahui';
      if (place.locality != null && place.locality!.isNotEmpty) {
        locationName = place.locality!; // City/Kota
      } else if (place.subAdministrativeArea != null && 
                 place.subAdministrativeArea!.isNotEmpty) {
        locationName = place.subAdministrativeArea!; // Kabupaten/Kota
      } else if (place.administrativeArea != null && 
                 place.administrativeArea!.isNotEmpty) {
        locationName = place.administrativeArea!; // Province
      }

      // Build full address
      final addressParts = <String>[];
      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.subAdministrativeArea != null && 
          place.subAdministrativeArea!.isNotEmpty &&
          place.subAdministrativeArea != place.locality) {
        addressParts.add(place.subAdministrativeArea!);
      }
      if (place.administrativeArea != null && 
          place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }

      final fullAddress = addressParts.isNotEmpty 
          ? addressParts.join(', ')
          : null;

      print('✅ Geocoding result:');
      print('   Location: $locationName');
      print('   City: ${place.locality}');
      print('   Address: $fullAddress');
      print('   Country: ${place.country}');

      return {
        'locationName': locationName,
        'city': place.locality,
        'address': fullAddress,
        'country': place.country ?? 'Indonesia',
      };
    } catch (e) {
      print('❌ Reverse geocoding error: $e');
      return {
        'locationName': 'Lat: ${latitude.toStringAsFixed(2)}, Long: ${longitude.toStringAsFixed(2)}',
        'city': null,
        'address': null,
        'country': null,
      };
    }
  }

  // ✅ UPDATED: Get cached location with new fields
  Future<LocationData?> _getCachedLocation({bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final latitude = prefs.getDouble(_keyLatitude);
      final longitude = prefs.getDouble(_keyLongitude);
      final locationName = prefs.getString(_keyLocationName);
      final city = prefs.getString(_keyCity);
      final address = prefs.getString(_keyAddress);
      final country = prefs.getString(_keyCountry);
      final lastUpdateStr = prefs.getString(_keyLastUpdate);

      if (latitude == null || longitude == null || lastUpdateStr == null) {
        return null;
      }

      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      
      // Check if cache is still valid
      if (!ignoreExpiry && now.difference(lastUpdate) > _cacheDuration) {
        print('⏰ Cache expired (${now.difference(lastUpdate).inHours}h old)');
        return null;
      }

      return LocationData(
        latitude: latitude,
        longitude: longitude,
        locationName: locationName ?? 'Unknown',
        city: city,
        address: address,
        country: country,
        timestamp: lastUpdate,
      );
    } catch (e) {
      print('❌ Error reading cached location: $e');
      return null;
    }
  }

  // ✅ UPDATED: Cache location with new fields
  Future<void> _cacheLocation(LocationData location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyLatitude, location.latitude);
      await prefs.setDouble(_keyLongitude, location.longitude);
      await prefs.setString(_keyLocationName, location.locationName);
      if (location.city != null) {
        await prefs.setString(_keyCity, location.city!);
      }
      if (location.address != null) {
        await prefs.setString(_keyAddress, location.address!);
      }
      if (location.country != null) {
        await prefs.setString(_keyCountry, location.country!);
      }
      await prefs.setString(_keyLastUpdate, location.timestamp.toIso8601String());
      print('💾 Location cached: ${location.displayName}');
    } catch (e) {
      print('❌ Error caching location: $e');
    }
  }

  // ✅ UPDATED: Clear cache (all keys)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLatitude);
      await prefs.remove(_keyLongitude);
      await prefs.remove(_keyLocationName);
      await prefs.remove(_keyCity);
      await prefs.remove(_keyAddress);
      await prefs.remove(_keyCountry);
      await prefs.remove(_keyLastUpdate);
      print('🗑️ Location cache cleared');
    } catch (e) {
      print('❌ Error clearing location cache: $e');
    }
  }

  // ✅ UPDATED: Fallback location with proper address
  LocationData _getFallbackLocation() {
    return LocationData(
      latitude: -6.2088,
      longitude: 106.8456,
      locationName: 'Jakarta',
      city: 'Jakarta',
      address: 'Jakarta, DKI Jakarta, Indonesia',
      country: 'Indonesia',
      timestamp: DateTime.now(),
    );
  }

  // Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }
}

// ✅ UPDATED: LocationData class with new fields
class LocationData {
  final double latitude;
  final double longitude;
  final String locationName;
  final String? city; // ✅ NEW
  final String? address; // ✅ NEW
  final String? country; // ✅ NEW
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.city,
    this.address,
    this.country,
    required this.timestamp,
  });

  bool get isFallback => latitude == -6.2088 && longitude == 106.8456;

  // ✅ NEW: Smart display name with priority
  String get displayName {
    // Priority: city > locationName > address
    if (city != null && city!.isNotEmpty) {
      return city!;
    }
    if (locationName.isNotEmpty && 
        locationName != 'Unknown Location' && 
        !locationName.startsWith('Lat:')) {
      return locationName;
    }
    if (address != null && address!.isNotEmpty) {
      // Take first part of address (usually city/area)
      final parts = address!.split(',');
      if (parts.isNotEmpty) {
        return parts[0].trim();
      }
    }
    return 'Lokasi Tidak Diketahui';
  }

  // ✅ NEW: Full address for detailed display
  String get fullAddress {
    if (address != null && address!.isNotEmpty) {
      return address!;
    }
    return '$locationName (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
  }

  // ✅ NEW: Short display for headers
  String get shortDisplay {
    if (city != null && city!.isNotEmpty) {
      return city!;
    }
    return displayName;
  }
}