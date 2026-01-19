// lib/services/update_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  // URL untuk mengecek versi terbaru (ganti dengan API Anda)
  static const String _updateCheckUrl = 'https://your-api.com/app/version.json';
  
  static const String _keyLastCheckTime = 'last_update_check';
  static const String _keySkippedVersion = 'skipped_version';
  
  // Check interval: 24 jam
  static const Duration _checkInterval = Duration(hours: 24);

  ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);
  ValueNotifier<bool> isDownloading = ValueNotifier<bool>(false);

  // Check for updates
  Future<UpdateInfo?> checkForUpdate({bool force = false}) async {
    try {
      // Check if we should check for updates
      if (!force && !await _shouldCheckForUpdate()) {
        print('Skipping update check (recently checked)');
        return null;
      }

      // Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      print('Current version: $currentVersion ($currentVersionCode)');

      // Fetch latest version info
      final response = await http.get(
        Uri.parse(_updateCheckUrl),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('Failed to check for updates: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final latestVersion = data['version'] as String;
      final latestVersionCode = data['versionCode'] as int;
      final downloadUrl = data['downloadUrl'] as String;
      final releaseNotes = data['releaseNotes'] as String? ?? '';
      final mandatory = data['mandatory'] as bool? ?? false;

      print('Latest version: $latestVersion ($latestVersionCode)');

      // Update last check time
      await _saveLastCheckTime();

      // Check if update is available
      if (latestVersionCode > currentVersionCode) {
        // Check if this version was skipped
        if (!mandatory && await _isVersionSkipped(latestVersion)) {
          print('Version $latestVersion was skipped by user');
          return null;
        }

        return UpdateInfo(
          version: latestVersion,
          versionCode: latestVersionCode,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          mandatory: mandatory,
          currentVersion: currentVersion,
          currentVersionCode: currentVersionCode,
        );
      }

      print('App is up to date');
      return null;
    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    }
  }

  // Download and install update
  Future<bool> downloadAndInstallUpdate(UpdateInfo updateInfo) async {
    try {
      if (Platform.isAndroid) {
        return await _downloadAndInstallAndroid(updateInfo);
      } else if (Platform.isIOS) {
        return await _openAppStore(updateInfo.downloadUrl);
      }
      return false;
    } catch (e) {
      print('Error downloading update: $e');
      isDownloading.value = false;
      return false;
    }
  }

  // Download and install for Android
  Future<bool> _downloadAndInstallAndroid(UpdateInfo updateInfo) async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          print('Storage permission denied');
          return false;
        }
      }

      isDownloading.value = true;
      downloadProgress.value = 0.0;

      // Get download directory
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        print('External storage not available');
        return false;
      }

      final filePath = '${dir.path}/myquran_${updateInfo.version}.apk';
      final file = File(filePath);

      // Delete old file if exists
      if (await file.exists()) {
        await file.delete();
      }

      print('Downloading APK to: $filePath');

      // Download file with progress
      final request = http.Request('GET', Uri.parse(updateInfo.downloadUrl));
      final response = await request.send();

      if (response.statusCode != 200) {
        print('Download failed: ${response.statusCode}');
        isDownloading.value = false;
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;

      final sink = file.openWrite();
      
      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        if (contentLength > 0) {
          downloadProgress.value = downloadedBytes / contentLength;
          print('Download progress: ${(downloadProgress.value * 100).toStringAsFixed(1)}%');
        }
      }

      await sink.close();
      isDownloading.value = false;
      downloadProgress.value = 1.0;

      print('Download completed: $filePath');

      // Install APK
      return await _installApk(filePath);
    } catch (e) {
      print('Error in _downloadAndInstallAndroid: $e');
      isDownloading.value = false;
      return false;
    }
  }

  // Install APK (Android)
  Future<bool> _installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          status = await Permission.requestInstallPackages.request();
          if (!status.isGranted) {
            print('Install packages permission denied');
            return false;
          }
        }
      }

      final uri = Uri.parse('file://$filePath');
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        print('Cannot launch APK installer');
        return false;
      }
    } catch (e) {
      print('Error installing APK: $e');
      return false;
    }
  }

  // Open App Store (iOS)
  Future<bool> _openAppStore(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening App Store: $e');
      return false;
    }
  }

  // Check if we should check for updates
  Future<bool> _shouldCheckForUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString(_keyLastCheckTime);
      
      if (lastCheckStr == null) return true;
      
      final lastCheck = DateTime.parse(lastCheckStr);
      final now = DateTime.now();
      
      return now.difference(lastCheck) >= _checkInterval;
    } catch (e) {
      print('Error checking last update time: $e');
      return true;
    }
  }

  // Save last check time
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastCheckTime, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving last check time: $e');
    }
  }

  // Skip this version
  Future<void> skipVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySkippedVersion, version);
      print('Version $version skipped');
    } catch (e) {
      print('Error skipping version: $e');
    }
  }

  // Check if version was skipped
  Future<bool> _isVersionSkipped(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skippedVersion = prefs.getString(_keySkippedVersion);
      return skippedVersion == version;
    } catch (e) {
      print('Error checking skipped version: $e');
      return false;
    }
  }

  // Clear skipped version
  Future<void> clearSkippedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySkippedVersion);
    } catch (e) {
      print('Error clearing skipped version: $e');
    }
  }
}

class UpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;
  final bool mandatory;
  final String currentVersion;
  final int currentVersionCode;

  UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.mandatory,
    required this.currentVersion,
    required this.currentVersionCode,
  });

  String get updateSize {
    return 'Unknown';
  }
}