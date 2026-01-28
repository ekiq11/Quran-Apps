// lib/widgets/notification_debug_panel.dart
// ✅ Widget untuk testing notifikasi - HANYA UNTUK DEVELOPMENT!
// Tambahkan di settings page untuk test

import 'package:flutter/material.dart';
import 'package:myquran/notification/notification_manager.dart';
import 'package:myquran/services/baterai_optimizer_helper.dart';
import 'package:myquran/services/prayer_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationDebugPanel extends StatefulWidget {
  const NotificationDebugPanel({Key? key}) : super(key: key);

  @override
  State<NotificationDebugPanel> createState() => _NotificationDebugPanelState();
}

class _NotificationDebugPanelState extends State<NotificationDebugPanel> {
  String _statusText = 'Ready';
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Notification Debug Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildButton(
                  'Check Permissions',
                  Icons.security,
                  Colors.blue,
                  _checkPermissions,
                ),
                _buildButton(
                  'Check Battery',
                  Icons.battery_charging_full,
                  Colors.green,
                  _checkBattery,
                ),
                _buildButton(
                  'Show Pending',
                  Icons.pending_actions,
                  Colors.orange,
                  _showPending,
                ),
                _buildButton(
                  'Force Schedule',
                  Icons.schedule_send,
                  Colors.purple,
                  _forceSchedule,
                ),
                _buildButton(
                  'Test Prayer Times',
                  Icons.mosque,
                  Colors.teal,
                  _testPrayerTimes,
                ),
                _buildButton(
                  'Cancel All',
                  Icons.cancel,
                  Colors.red,
                  _cancelAll,
                ),
              ],
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
  
  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Checking permissions...';
    });
    
    try {
      final notifManager = NotificationManager();
      final hasPerms = await notifManager.hasRequiredPermissions();
      
      if (hasPerms) {
        setState(() {
          _statusText = '✅ All permissions granted!';
        });
      } else {
        setState(() {
          _statusText = '❌ Missing permissions!\nPlease grant all permissions in settings.';
        });
      }
    } catch (e) {
      setState(() {
        _statusText = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _checkBattery() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Checking battery optimization...';
    });
    
    try {
      final isDisabled = await BatteryOptimizationHelper.isBatteryOptimizationDisabled();
      
      if (isDisabled) {
        setState(() {
          _statusText = '✅ Battery optimization is DISABLED\nNotifications will work in background!';
        });
      } else {
        setState(() {
          _statusText = '⚠️ Battery optimization is ENABLED\nThis may prevent background notifications.\n\nTap button below to disable:';
        });
        
        // Show option to request
        if (mounted) {
          final request = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Battery Optimization'),
              content: const Text('Battery optimization is enabled. This may prevent notifications from working when the app is closed.\n\nWould you like to disable it now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Disable Now'),
                ),
              ],
            ),
          );
          
          if (request == true) {
            await BatteryOptimizationHelper.requestBatteryOptimizationExemption();
          }
        }
      }
    } catch (e) {
      setState(() {
        _statusText = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _showPending() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Loading pending notifications...';
    });
    
    try {
      final notifManager = NotificationManager();
      final pending = await notifManager.getPendingNotifications();
      
      if (pending.isEmpty) {
        setState(() {
          _statusText = '⚠️ NO pending notifications!\nNotifications may not be scheduled properly.';
        });
      } else {
        final list = pending.map((p) => '${p.id}: ${p.title}').join('\n');
        setState(() {
          _statusText = '✅ ${pending.length} pending notifications:\n\n$list';
        });
      }
    } catch (e) {
      setState(() {
        _statusText = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _forceSchedule() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Force scheduling notifications...';
    });
    
    try {
      final prayerService = PrayerTimeService();
      
      // Try to load saved prayer times
      var prayerTimes = await prayerService.loadSavedPrayerTimes();
      
      if (prayerTimes.isEmpty) {
        setState(() {
          _statusText = 'No saved prayer times found.\nCalculating new times...';
        });
        
        await Future.delayed(const Duration(seconds: 1));
        
        // Calculate new times
        final model = await prayerService.calculatePrayerTimes(
          forceRefresh: true,
          autoSchedule: true,
        );
        
        prayerTimes = model.times;
      } else {
        // Schedule with saved times
        final notifManager = NotificationManager();
        final prefs = await SharedPreferences.getInstance();
        
        final tilawahTimes = {
          'Pagi': TimeOfDay(
            hour: prefs.getInt('tilawah_pagi_hour') ?? 6,
            minute: prefs.getInt('tilawah_pagi_minute') ?? 0,
          ),
          'Siang': TimeOfDay(
            hour: prefs.getInt('tilawah_siang_hour') ?? 13,
            minute: prefs.getInt('tilawah_siang_minute') ?? 0,
          ),
          'Malam': TimeOfDay(
            hour: prefs.getInt('tilawah_malam_hour') ?? 20,
            minute: prefs.getInt('tilawah_malam_minute') ?? 0,
          ),
        };
        
        await notifManager.scheduleAllNotifications(
          prayerTimes: prayerTimes,
          tilawahTimes: tilawahTimes,
        );
      }
      
      // Show success
      final pending = await NotificationManager().getPendingNotifications();
      setState(() {
        _statusText = '✅ Success!\n${pending.length} notifications scheduled.';
      });
      
    } catch (e) {
      setState(() {
        _statusText = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _testPrayerTimes() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Loading prayer times...';
    });
    
    try {
      final prayerService = PrayerTimeService();
      final savedTimes = await prayerService.loadSavedPrayerTimes();
      
      if (savedTimes.isEmpty) {
        setState(() {
          _statusText = '⚠️ No prayer times saved!\nCalculating...';
        });
        
        await Future.delayed(const Duration(seconds: 1));
        
        final model = await prayerService.calculatePrayerTimes(
          forceRefresh: true,
          autoSchedule: false,
        );
        
        final times = model.times.entries
            .map((e) => '${e.key}: ${e.value.hour.toString().padLeft(2, '0')}:${e.value.minute.toString().padLeft(2, '0')}')
            .join('\n');
        
        setState(() {
          _statusText = '✅ Prayer times calculated:\n\n$times';
        });
      } else {
        final times = savedTimes.entries
            .map((e) => '${e.key}: ${e.value.hour.toString().padLeft(2, '0')}:${e.value.minute.toString().padLeft(2, '0')}')
            .join('\n');
        
        setState(() {
          _statusText = '✅ Saved prayer times:\n\n$times';
        });
      }
    } catch (e) {
      setState(() {
        _statusText = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _cancelAll() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Cancelling all notifications...';
    });
    
    try {
      final notifManager = NotificationManager();
      await notifManager.cancelAllNotifications();
      
      setState(() {
        _statusText = '✅ All notifications cancelled!';
      });
    } catch (e) {
      setState(() {
        _statusText = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}