// lib/services/update.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateInfo {
  final String version;
  final bool mandatory;
  final String? description;
  final int availableVersionCode;

  UpdateInfo({
    required this.version,
    required this.mandatory,
    this.description,
    required this.availableVersionCode,
  });
}

class UpdateService {
  /// Cek update dari Play Store — hanya Android
  Future<UpdateInfo?> checkForUpdate() async {
    // ✅ FIX: in_app_update hanya support Android
    if (!Platform.isAndroid) {
      debugPrint('ℹ️ In-app update only available on Android, skipping...');
      return null;
    }

    try {
      debugPrint('🔍 Checking for Play Store updates...');

      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('✅ Update available!');
        debugPrint('   Available version code: ${updateInfo.availableVersionCode}');

        return UpdateInfo(
          version: updateInfo.availableVersionCode?.toString() ?? 'Unknown',
          mandatory: updateInfo.immediateUpdateAllowed,
          description: 'Versi baru tersedia di Play Store',
          availableVersionCode: updateInfo.availableVersionCode ?? 0,
        );
      } else {
        debugPrint('✅ App is up to date');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      return null;
    }
  }

  /// Perform immediate update (mandatory)
  Future<AppUpdateResult> performImmediateUpdate() async {
    try {
      debugPrint('🔄 Starting immediate update...');
      final result = await InAppUpdate.performImmediateUpdate();
      debugPrint('✅ Immediate update result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Immediate update failed: $e');
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  /// Start flexible update (optional)
  Future<AppUpdateResult> startFlexibleUpdate() async {
    try {
      debugPrint('🔄 Starting flexible update...');
      final result = await InAppUpdate.startFlexibleUpdate();
      debugPrint('✅ Flexible update started: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Flexible update failed: $e');
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  /// Complete flexible update
  Future<void> completeFlexibleUpdate() async {
    try {
      debugPrint('🔄 Completing flexible update...');
      await InAppUpdate.completeFlexibleUpdate();
      debugPrint('✅ Flexible update completed');
    } catch (e) {
      debugPrint('❌ Complete flexible update failed: $e');
      rethrow;
    }
  }
}