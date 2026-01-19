// screens/settings/notification_settings_page.dart - UPDATED
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myquran/notification/notification_manager.dart';
import 'package:myquran/services/prayer_time_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationManager _notificationManager = NotificationManager();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  
  // Prayer notifications
  bool _enableSubuh = true;
  bool _enableDzuhur = true;
  bool _enableAshar = true;
  bool _enableMaghrib = true;
  bool _enableIsya = true;
  
  // Dzikir notifications (auto-calculated from prayer times)
  bool _enableDzikirPagi = true;  // 30 min after Subuh
  bool _enableDzikirPetang = true; // 30 min after Ashar
  
  // Tilawah notifications with custom times
  bool _enableTilawahPagi = true;
  bool _enableTilawahSiang = false;
  bool _enableTilawahMalam = true;
  
  TimeOfDay _tilawahPagiTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _tilawahSiangTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _tilawahMalamTime = const TimeOfDay(hour: 20, minute: 0);
  
  // Settings
  bool _silentMode = false;
  bool _showInCenter = true;
  
  bool _isLoading = true;
  int _pendingCount = 0;
  String _lastUpdate = 'Belum pernah';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPendingCount();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Prayer notifications
      _enableSubuh = prefs.getBool('notif_enable_subuh') ?? true;
      _enableDzuhur = prefs.getBool('notif_enable_dzuhur') ?? true;
      _enableAshar = prefs.getBool('notif_enable_ashar') ?? true;
      _enableMaghrib = prefs.getBool('notif_enable_maghrib') ?? true;
      _enableIsya = prefs.getBool('notif_enable_isya') ?? true;
      
      // Dzikir notifications
      _enableDzikirPagi = prefs.getBool('notif_enable_dzikir_pagi') ?? true;
      _enableDzikirPetang = prefs.getBool('notif_enable_dzikir_petang') ?? true;
      
      // Tilawah notifications
      _enableTilawahPagi = prefs.getBool('notif_enable_tilawah_pagi') ?? true;
      _enableTilawahSiang = prefs.getBool('notif_enable_tilawah_siang') ?? false;
      _enableTilawahMalam = prefs.getBool('notif_enable_tilawah_malam') ?? true;
      
      // Load custom tilawah times
      _tilawahPagiTime = _loadTimeFromPrefs(prefs, 'tilawah_time_pagi', const TimeOfDay(hour: 6, minute: 0));
      _tilawahSiangTime = _loadTimeFromPrefs(prefs, 'tilawah_time_siang', const TimeOfDay(hour: 13, minute: 0));
      _tilawahMalamTime = _loadTimeFromPrefs(prefs, 'tilawah_time_malam', const TimeOfDay(hour: 20, minute: 0));
      
      // Settings
      _silentMode = prefs.getBool('notification_silent_mode') ?? false;
      _showInCenter = prefs.getBool('notif_show_in_center') ?? true;
      
      // Last update
      final lastUpdateStr = prefs.getString('last_notification_update');
      if (lastUpdateStr != null) {
        final date = DateTime.parse(lastUpdateStr);
        _lastUpdate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      
      _isLoading = false;
    });
  }

  TimeOfDay _loadTimeFromPrefs(SharedPreferences prefs, String key, TimeOfDay defaultTime) {
    final saved = prefs.getString(key);
    if (saved == null) return defaultTime;
    
    final parts = saved.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<void> _loadPendingCount() async {
    final pending = await _notificationManager.getPendingNotifications();
    setState(() => _pendingCount = pending.length);
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    TimeOfDay initialTime;
    
    switch (type) {
      case 'pagi':
        initialTime = _tilawahPagiTime;
        break;
      case 'siang':
        initialTime = _tilawahSiangTime;
        break;
      case 'malam':
        initialTime = _tilawahMalamTime;
        break;
      default:
        return;
    }
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() {
        switch (type) {
          case 'pagi':
            _tilawahPagiTime = pickedTime;
            break;
          case 'siang':
            _tilawahSiangTime = pickedTime;
            break;
          case 'malam':
            _tilawahMalamTime = pickedTime;
            break;
        }
      });
    }
  }

  Future<void> _saveAndReschedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save all prayer settings
      await prefs.setBool('notif_enable_subuh', _enableSubuh);
      await prefs.setBool('notif_enable_dzuhur', _enableDzuhur);
      await prefs.setBool('notif_enable_ashar', _enableAshar);
      await prefs.setBool('notif_enable_maghrib', _enableMaghrib);
      await prefs.setBool('notif_enable_isya', _enableIsya);
      
      // Save dzikir settings
      await prefs.setBool('notif_enable_dzikir_pagi', _enableDzikirPagi);
      await prefs.setBool('notif_enable_dzikir_petang', _enableDzikirPetang);
      
      // Save tilawah settings
      await prefs.setBool('notif_enable_tilawah_pagi', _enableTilawahPagi);
      await prefs.setBool('notif_enable_tilawah_siang', _enableTilawahSiang);
      await prefs.setBool('notif_enable_tilawah_malam', _enableTilawahMalam);
      
      // Save tilawah times
      await prefs.setString('tilawah_time_pagi', '${_tilawahPagiTime.hour}:${_tilawahPagiTime.minute}');
      await prefs.setString('tilawah_time_siang', '${_tilawahSiangTime.hour}:${_tilawahSiangTime.minute}');
      await prefs.setString('tilawah_time_malam', '${_tilawahMalamTime.hour}:${_tilawahMalamTime.minute}');
      
      // Save general settings
      await prefs.setBool('notification_silent_mode', _silentMode);
      await prefs.setBool('notif_show_in_center', _showInCenter);
      
      // Get prayer times
      final prayerTimes = await _prayerTimeService.calculatePrayerTimes();
      
      // Reschedule notifications
      await _notificationManager.scheduleAllNotifications(
        prayerTimes: prayerTimes.times,
        enabledPrayers: {
          'Subuh': _enableSubuh,
          'Dzuhur': _enableDzuhur,
          'Ashar': _enableAshar,
          'Maghrib': _enableMaghrib,
          'Isya': _enableIsya,
        },
        tilawahTimes: {
          'Pagi': _tilawahPagiTime,
          'Siang': _tilawahSiangTime,
          'Malam': _tilawahMalamTime,
        },
      );
      
      // Save update time
      await prefs.setString('last_notification_update', DateTime.now().toIso8601String());
      
      await _loadPendingCount();
      await _loadSettings();
      
      _showSnackBar('✅ Pengaturan berhasil disimpan', Colors.green);
      
    } catch (e) {
      _showSnackBar('❌ Gagal menyimpan: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _saveAndReschedule,
            tooltip: 'Terapkan & Perbarui',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildPrayerSection(),
                const SizedBox(height: 16),
                _buildDzikirSection(),
                const SizedBox(height: 16),
                _buildTilawahSection(),
                const SizedBox(height: 16),
                _buildSettingsSection(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF059669).withOpacity(0.1),
            const Color(0xFF047857).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_pendingCount notifikasi terjadwal',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Terakhir diperbarui: $_lastUpdate',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerSection() {
    return _buildSection(
      'Waktu Sholat',
      Icons.mosque,
      const Color(0xFF059669),
      [
        _buildSwitchTile('Subuh', _enableSubuh, (v) => setState(() => _enableSubuh = v)),
        _buildSwitchTile('Dzuhur', _enableDzuhur, (v) => setState(() => _enableDzuhur = v)),
        _buildSwitchTile('Ashar', _enableAshar, (v) => setState(() => _enableAshar = v)),
        _buildSwitchTile('Maghrib', _enableMaghrib, (v) => setState(() => _enableMaghrib = v)),
        _buildSwitchTile('Isya', _enableIsya, (v) => setState(() => _enableIsya = v)),
      ],
    );
  }

  Widget _buildDzikirSection() {
    return _buildSection(
      'Dzikir Pagi & Petang',
      Icons.auto_stories,
      const Color(0xFF06B6D4),
      [
        _buildSwitchTile(
          '🌅 Dzikir Pagi', 
          _enableDzikirPagi, 
          (v) => setState(() => _enableDzikirPagi = v),
          subtitle: '30 menit setelah waktu Subuh',
        ),
        _buildSwitchTile(
          '🌆 Dzikir Petang', 
          _enableDzikirPetang, 
          (v) => setState(() => _enableDzikirPetang = v),
          subtitle: '30 menit setelah waktu Ashar',
        ),
      ],
    );
  }

  Widget _buildTilawahSection() {
    return _buildSection(
      'Tilawah Al-Quran',
      Icons.menu_book,
      const Color(0xFF10B981),
      [
        _buildTimeTile(
          '📖 Tilawah Pagi',
          _enableTilawahPagi,
          _tilawahPagiTime,
          (v) => setState(() => _enableTilawahPagi = v),
          () => _selectTime(context, 'pagi'),
        ),
        _buildTimeTile(
          '☀️ Tilawah Siang',
          _enableTilawahSiang,
          _tilawahSiangTime,
          (v) => setState(() => _enableTilawahSiang = v),
          () => _selectTime(context, 'siang'),
        ),
        _buildTimeTile(
          '🌙 Tilawah Malam',
          _enableTilawahMalam,
          _tilawahMalamTime,
          (v) => setState(() => _enableTilawahMalam = v),
          () => _selectTime(context, 'malam'),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return _buildSection(
      'Pengaturan Umum',
      Icons.settings,
      const Color(0xFF6B7280),
      [
        _buildSwitchTile(
          'Mode Senyap', 
          _silentMode, 
          (v) => setState(() => _silentMode = v),
          subtitle: 'Notifikasi tanpa suara dan getar',
        ),
        _buildSwitchTile(
          'Tampilkan di Pusat Notifikasi', 
          _showInCenter, 
          (v) => setState(() => _showInCenter = v),
          subtitle: 'Simpan riwayat notifikasi',
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged, {String? subtitle}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF059669),
      ),
    );
  }

  Widget _buildTimeTile(
    String title,
    bool enabled,
    TimeOfDay time,
    Function(bool) onChanged,
    VoidCallback onTimeTap,
  ) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _formatTime(time),
        style: TextStyle(
          fontSize: 12,
          color: enabled ? const Color(0xFF059669) : const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.access_time, size: 20),
            onPressed: enabled ? onTimeTap : null,
            color: const Color(0xFF059669),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveAndReschedule,
            icon: const Icon(Icons.save),
            label: const Text('Simpan & Terapkan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await _notificationManager.testNotification();
              _showSnackBar('🧪 Assalamualaikum!', Colors.blue);
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Ahlan Wa Sahlan!'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF059669)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
      ],
    );
  }
}