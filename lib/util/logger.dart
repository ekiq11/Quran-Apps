// lib/util/logger.dart
// Centralized logger — hanya print di debug mode
import 'package:flutter/foundation.dart';

/// Log pesan hanya saat debug mode.
/// Di release build, semua output akan di-strip oleh tree shaker.
void appLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
