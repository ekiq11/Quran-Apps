// lib/util/navigator_key.dart
// Shared GlobalKey for navigator — digunakan oleh main.dart dan NotificationManager
// PENTING: Hanya ada SATU instance agar notifikasi dapat membuka dialog dengan benar.
import 'package:flutter/material.dart';

/// Key yang di-register ke MaterialApp.navigatorKey.
/// Import file ini dari mana saja yang perlu mengakses Navigator dari luar widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
