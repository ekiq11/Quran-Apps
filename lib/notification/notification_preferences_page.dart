// notification/notification_preferences_page.dart — Full UI rebuild
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myquran/notification/notification_manager.dart';
import 'package:myquran/screens/util/constants.dart';
import 'package:myquran/provider/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({Key? key}) : super(key: key);
  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage>
    with SingleTickerProviderStateMixin {

  final NotificationManager _notificationManager = NotificationManager();

  // Prayer
  bool _enableSubuh = true;
  bool _enableDzuhur = true;
  bool _enableAshar = true;
  bool _enableMaghrib = true;
  bool _enableIsya = true;

  // Extra
  bool _enableTahajud = false;
  bool _enableDuha = false;

  // Dzikir
  bool _enableDzikirPagi = true;
  bool _enableDzikirPetang = true;

  // Tilawah
  bool _enableTilawahPagi = true;
  bool _enableTilawahMalam = true;
  TimeOfDay _tilawahPagiTime  = const TimeOfDay(hour: 6,  minute: 0);
  TimeOfDay _tilawahSiangTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _tilawahMalamTime = const TimeOfDay(hour: 20, minute: 0);

  bool _showInNotificationCenter = true;
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadPreferences();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final p = await SharedPreferences.getInstance();
      setState(() {
        _enableSubuh        = p.getBool('notif_enable_subuh')         ?? true;
        _enableDzuhur       = p.getBool('notif_enable_dzuhur')        ?? true;
        _enableAshar        = p.getBool('notif_enable_ashar')         ?? true;
        _enableMaghrib      = p.getBool('notif_enable_maghrib')       ?? true;
        _enableIsya         = p.getBool('notif_enable_isya')          ?? true;
        _enableTahajud      = p.getBool('notif_enable_tahajud')       ?? false;
        _enableDuha         = p.getBool('notif_enable_duha')          ?? false;
        _enableDzikirPagi   = p.getBool('notif_enable_dzikir_pagi')   ?? true;
        _enableDzikirPetang = p.getBool('notif_enable_dzikir_petang') ?? true;
        _enableTilawahPagi  = p.getBool('notif_enable_tilawah_pagi')  ?? true;
        _enableTilawahMalam = p.getBool('notif_enable_tilawah_malam') ?? true;
        _tilawahPagiTime  = _parseTime(p.getString('tilawah_time_pagi')  ?? '6:0');
        _tilawahSiangTime = _parseTime(p.getString('tilawah_time_siang') ?? '13:0');
        _tilawahMalamTime = _parseTime(p.getString('tilawah_time_malam') ?? '20:0');
        _showInNotificationCenter = p.getBool('notif_show_in_center') ?? true;
        _isLoading = false;
      });
      _animController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  void _mark() => setState(() => _hasChanges = true);

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('notif_enable_subuh',         _enableSubuh);
      await p.setBool('notif_enable_dzuhur',        _enableDzuhur);
      await p.setBool('notif_enable_ashar',         _enableAshar);
      await p.setBool('notif_enable_maghrib',       _enableMaghrib);
      await p.setBool('notif_enable_isya',          _enableIsya);
      await p.setBool('notif_enable_tahajud',       _enableTahajud);
      await p.setBool('notif_enable_duha',          _enableDuha);
      await p.setBool('notif_enable_dzikir_pagi',   _enableDzikirPagi);
      await p.setBool('notif_enable_dzikir_petang', _enableDzikirPetang);
      await p.setBool('notif_enable_tilawah_pagi',  _enableTilawahPagi);
      await p.setBool('notif_enable_tilawah_malam', _enableTilawahMalam);
      await p.setString('tilawah_time_pagi',  '${_tilawahPagiTime.hour}:${_tilawahPagiTime.minute}');
      await p.setString('tilawah_time_siang', '${_tilawahSiangTime.hour}:${_tilawahSiangTime.minute}');
      await p.setString('tilawah_time_malam', '${_tilawahMalamTime.hour}:${_tilawahMalamTime.minute}');
      await p.setBool('notif_show_in_center', _showInNotificationCenter);

      // Re-schedule
      final dash = Provider.of<DashboardProvider>(context, listen: false);
      final times = dash.prayerTimeModel?.times ?? _defaultTimes();
      await _notificationManager.scheduleAllNotifications(
        prayerTimes: times,
        enabledPrayers: {
          'Subuh': _enableSubuh, 'Dzuhur': _enableDzuhur,
          'Ashar': _enableAshar, 'Maghrib': _enableMaghrib, 'Isya': _enableIsya,
        },
        tilawahTimes: {
          'Pagi': _tilawahPagiTime,
          'Siang': _tilawahSiangTime,
          'Malam': _tilawahMalamTime,
        },
      );

      if (!mounted) return;
      setState(() { _hasChanges = false; _isSaving = false; });
      _showSnack('Pengaturan berhasil disimpan', isError: false);
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Gagal menyimpan: $e', isError: true);
    }
  }

  Map<String, TimeOfDay> _defaultTimes() => {
    'Subuh': const TimeOfDay(hour: 4, minute: 30),
    'Dzuhur': const TimeOfDay(hour: 12, minute: 0),
    'Ashar': const TimeOfDay(hour: 15, minute: 15),
    'Maghrib': const TimeOfDay(hour: 18, minute: 0),
    'Isya': const TimeOfDay(hour: 19, minute: 15),
  };

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: AppTextStyles.body(color: Colors.white))),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _pickTime(TimeOfDay current, ValueChanged<TimeOfDay> onPick) async {
    final result = await showTimePicker(context: context, initialTime: current);
    if (result != null) { onPick(result); _mark(); }
  }

  int get _enabledCount {
    int c = 0;
    for (final v in [_enableSubuh, _enableDzuhur, _enableAshar, _enableMaghrib,
        _enableIsya, _enableTahajud, _enableDuha, _enableDzikirPagi,
        _enableDzikirPetang, _enableTilawahPagi, _enableTilawahMalam]) {
      if (v) c++;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final res = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Simpan Perubahan?', style: AppTextStyles.heading()),
            content: Text('Ada perubahan yang belum disimpan.', style: AppTextStyles.body(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Buang', style: AppTextStyles.button(color: AppColors.error))),
              TextButton(onPressed: () => Navigator.pop(context, null),  child: Text('Batal',  style: AppTextStyles.button(color: AppColors.textSecondary))),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text('Simpan', style: AppTextStyles.button()),
              ),
            ],
          ),
        );
        if (res == true) { await _savePreferences(); }
        if (mounted && (res == true || res == false)) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Preferensi Notifikasi', style: AppTextStyles.appBarTitle()),
          centerTitle: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
            : FadeTransition(
                opacity: _fadeAnim,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryBanner(),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.mosque_rounded,
                      color: AppColors.primary,
                      title: 'Waktu Sholat Wajib',
                      subtitle: 'Pengingat 5 waktu sholat',
                      trailing: _allToggle(
                        value: _enableSubuh && _enableDzuhur && _enableAshar && _enableMaghrib && _enableIsya,
                        onChanged: (v) { setState(() { _enableSubuh = _enableDzuhur = _enableAshar = _enableMaghrib = _enableIsya = v; _hasChanges = true; }); },
                      ),
                      children: [
                        _buildToggle(emoji: '🌅', label: 'Subuh',   sub: 'Fajar hingga terbit matahari',   value: _enableSubuh,   onChanged: (v) { setState(() { _enableSubuh = v; _mark(); }); }),
                        _buildToggle(emoji: '☀️', label: 'Dzuhur',  sub: 'Tengah hari',                    value: _enableDzuhur,  onChanged: (v) { setState(() { _enableDzuhur = v; _mark(); }); }),
                        _buildToggle(emoji: '🌤️', label: 'Ashar',   sub: 'Sore hari',                      value: _enableAshar,   onChanged: (v) { setState(() { _enableAshar = v; _mark(); }); }),
                        _buildToggle(emoji: '🌆', label: 'Maghrib', sub: 'Saat matahari terbenam',         value: _enableMaghrib, onChanged: (v) { setState(() { _enableMaghrib = v; _mark(); }); }),
                        _buildToggle(emoji: '🌙', label: 'Isya',    sub: 'Malam hari',                     value: _enableIsya,    onChanged: (v) { setState(() { _enableIsya = v; _mark(); }); }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      icon: Icons.bedtime_rounded,
                      color: const Color(0xFF7C3AED),
                      title: 'Sholat Sunnah',
                      subtitle: 'Tahajud & Duha',
                      children: [
                        _buildToggle(emoji: '🌃', label: 'Tahajud', sub: 'Pukul 03:00 dini hari', value: _enableTahajud, onChanged: (v) { setState(() { _enableTahajud = v; _mark(); }); }),
                        _buildToggle(emoji: '🌄', label: 'Duha',    sub: 'Pukul 07:00 pagi',      value: _enableDuha,    onChanged: (v) { setState(() { _enableDuha = v; _mark(); }); }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      icon: Icons.volunteer_activism_rounded,
                      color: AppColors.secondary,
                      title: 'Dzikir Harian',
                      subtitle: 'Dzikir pagi dan petang',
                      trailing: _allToggle(
                        value: _enableDzikirPagi && _enableDzikirPetang,
                        onChanged: (v) { setState(() { _enableDzikirPagi = _enableDzikirPetang = v; _hasChanges = true; }); },
                      ),
                      children: [
                        _buildToggle(emoji: '🌞', label: 'Dzikir Pagi',   sub: 'Setelah Subuh',   value: _enableDzikirPagi,   onChanged: (v) { setState(() { _enableDzikirPagi = v; _mark(); }); }),
                        _buildToggle(emoji: '🌇', label: 'Dzikir Petang', sub: 'Setelah Ashar',   value: _enableDzikirPetang, onChanged: (v) { setState(() { _enableDzikirPetang = v; _mark(); }); }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      icon: Icons.menu_book_rounded,
                      color: AppColors.gold,
                      title: 'Tilawah Al-Qur\'an',
                      subtitle: 'Pengingat membaca Al-Qur\'an',
                      trailing: _allToggle(
                        value: _enableTilawahPagi && _enableTilawahMalam,
                        onChanged: (v) { setState(() { _enableTilawahPagi = _enableTilawahMalam = v; _hasChanges = true; }); },
                      ),
                      children: [
                        _buildToggleWithTime(
                          emoji: '📖', label: 'Tilawah Pagi',  value: _enableTilawahPagi,
                          time: _tilawahPagiTime,
                          onChanged: (v) { setState(() { _enableTilawahPagi = v; _mark(); }); },
                          onTimeTap: () => _pickTime(_tilawahPagiTime,  (t) => setState(() => _tilawahPagiTime  = t)),
                        ),
                        _buildToggleWithTime(
                          emoji: '🌙', label: 'Tilawah Malam', value: _enableTilawahMalam,
                          time: _tilawahMalamTime,
                          onChanged: (v) { setState(() { _enableTilawahMalam = v; _mark(); }); },
                          onTimeTap: () => _pickTime(_tilawahMalamTime, (t) => setState(() => _tilawahMalamTime = t)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      icon: Icons.tune_rounded,
                      color: AppColors.info,
                      title: 'Tampilan',
                      subtitle: 'Pengaturan tampilan notifikasi',
                      children: [
                        _buildToggle(
                          emoji: '🔔', label: 'Pusat Notifikasi',
                          sub: 'Tampilkan riwayat di dalam aplikasi',
                          value: _showInNotificationCenter,
                          onChanged: (v) { setState(() { _showInNotificationCenter = v; _mark(); }); },
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
        bottomNavigationBar: AnimatedSlide(
          offset: _hasChanges ? Offset.zero : const Offset(0, 1),
          duration: AppAnimations.medium,
          curve: AppAnimations.enterCurve,
          child: AnimatedOpacity(
            opacity: _hasChanges ? 1.0 : 0.0,
            duration: AppAnimations.short,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loadPreferences,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Reset', style: AppTextStyles.button(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.save_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text('Simpan', style: AppTextStyles.button()),
                            ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Summary banner ──────────────────────────────────────────
  Widget _buildSummaryBanner() {
    final count = _enabledCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0.04)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count dari 11 Notifikasi Aktif', style: AppTextStyles.heading()),
          const SizedBox(height: 3),
          Text('Perubahan berlaku setelah disimpan', style: AppTextStyles.caption()),
        ])),
      ]),
    );
  }

  // ── Section card ─────────────────────────────────────────────
  Widget _buildSection({
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required List<Widget> children, Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.subheading()),
              Text(subtitle, style: AppTextStyles.caption()),
            ])),
            if (trailing != null) trailing,
          ]),
        ),
        Divider(height: 1, color: AppColors.borderLight),
        // Items
        ...children,
      ]),
    );
  }

  // ── Toggle row ────────────────────────────────────────────────
  Widget _buildToggle({
    required String emoji, required String label, required String sub,
    required bool value, required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.body(weight: FontWeight.w600)),
          Text(sub,   style: AppTextStyles.caption()),
        ])),
        Switch.adaptive(
          value: value, onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ]),
    );
  }

  // ── Toggle + time picker ──────────────────────────────────────
  Widget _buildToggleWithTime({
    required String emoji, required String label,
    required bool value, required TimeOfDay time,
    required ValueChanged<bool> onChanged, required VoidCallback onTimeTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.body(weight: FontWeight.w600)),
          GestureDetector(
            onTap: value ? onTimeTap : null,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: value ? AppColors.primary.withValues(alpha: 0.1) : AppColors.borderLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.access_time_rounded, size: 13,
                    color: value ? AppColors.primary : AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(_formatTime(time), style: AppTextStyles.caption(
                    color: value ? AppColors.primary : AppColors.textTertiary,
                    weight: FontWeight.w600)),
              ]),
            ),
          ),
        ])),
        Switch.adaptive(
          value: value, onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ]),
    );
  }

  // ── All-toggle chip ───────────────────────────────────────────
  Widget _allToggle({required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withValues(alpha: 0.12) : AppColors.borderLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(value ? 'Semua ON' : 'Semua OFF',
            style: AppTextStyles.caption(
                color: value ? AppColors.primary : AppColors.textTertiary,
                weight: FontWeight.w600)),
      ),
    );
  }
}