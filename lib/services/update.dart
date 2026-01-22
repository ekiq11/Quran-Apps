// lib/services/update.dart
import 'package:flutter/material.dart';
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
  /// Cek update dari Play Store
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      print('🔍 Checking for Play Store updates...');
      
      // Cek apakah ada update tersedia
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        print('✅ Update available!');
        print('   Available version code: ${updateInfo.availableVersionCode}');
        print('   Immediate update allowed: ${updateInfo.immediateUpdateAllowed}');
        print('   Flexible update allowed: ${updateInfo.flexibleUpdateAllowed}');
        
        return UpdateInfo(
          version: updateInfo.availableVersionCode?.toString() ?? 'Unknown',
          mandatory: updateInfo.immediateUpdateAllowed,
          description: 'Versi baru tersedia di Play Store',
          availableVersionCode: updateInfo.availableVersionCode ?? 0,
        );
      } else {
        print('✅ App is up to date');
        return null;
      }
      
    } catch (e) {
      print('❌ Error checking for updates: $e');
      return null;
    }
  }

  /// Perform immediate update (mandatory)
  Future<AppUpdateResult> performImmediateUpdate() async {
    try {
      print('🔄 Starting immediate update...');
      final result = await InAppUpdate.performImmediateUpdate();
      print('✅ Immediate update result: $result');
      return result;
    } catch (e) {
      print('❌ Immediate update failed: $e');
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  /// Start flexible update (optional)
  Future<AppUpdateResult> startFlexibleUpdate() async {
    try {
      print('🔄 Starting flexible update...');
      final result = await InAppUpdate.startFlexibleUpdate();
      print('✅ Flexible update started: $result');
      return result;
    } catch (e) {
      print('❌ Flexible update failed: $e');
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  /// Complete flexible update
  Future<void> completeFlexibleUpdate() async {
    try {
      print('🔄 Completing flexible update...');
      await InAppUpdate.completeFlexibleUpdate();
      print('✅ Flexible update completed');
    } catch (e) {
      print('❌ Complete flexible update failed: $e');
      rethrow;
    }
  }
}