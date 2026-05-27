// lib/utils/battery_optimization_helper.dart
// ✅ Helper untuk battery optimization via native Android

import 'dart:io';
import 'package:flutter/services.dart';

class BatteryOptimizationHelper {
  static const MethodChannel _channel = MethodChannel('com.bekalsunnah.doa_harian/battery');
  
  /// Check if battery optimization is disabled
  static Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool result = await _channel.invokeMethod('isBatteryOptimizationDisabled');
      print('🔋 Battery optimization disabled: $result');
      return result;
    } catch (e) {
      print('❌ Error checking battery optimization: $e');
      return false;
    }
  }
  
  /// Request battery optimization exemption
  static Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return true;
    
    try {
      print('⚡ Requesting battery optimization exemption...');
      final bool result = await _channel.invokeMethod('requestBatteryOptimizationExemption');
      print(result ? '✅ Request sent' : '❌ Request failed');
      return result;
    } catch (e) {
      print('❌ Error requesting exemption: $e');
      return false;
    }
  }
  
  /// Open battery optimization settings
  static Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    
    try {
      print('🔧 Opening battery optimization settings...');
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      print('❌ Error opening settings: $e');
    }
  }
}