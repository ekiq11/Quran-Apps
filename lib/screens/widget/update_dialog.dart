// lib/screens/widget/update_dialog.dart
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:myquran/services/update.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({
    Key? key,
    required this.updateInfo,
  }) : super(key: key);

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final UpdateService _updateService = UpdateService();
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.updateInfo.mandatory,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.system_update,
                color: Color(0xFF059669),
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.updateInfo.mandatory 
                      ? 'Update Diperlukan' 
                      : 'Update Tersedia',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Versi ${widget.updateInfo.version}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.updateInfo.description != null) ...[
              Text(
                widget.updateInfo.description!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            
            if (widget.updateInfo.mandatory)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Update ini wajib untuk melanjutkan menggunakan aplikasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_isUpdating) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Memulai update...',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!widget.updateInfo.mandatory && !_isUpdating)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti'),
            ),
          
          if (!_isUpdating)
            ElevatedButton(
              onPressed: _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Update Sekarang'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _isUpdating = true);

    try {
      if (widget.updateInfo.mandatory) {
        // Immediate update (mandatory)
        await _updateService.performImmediateUpdate();
      } else {
        // Flexible update (optional)
        final result = await _updateService.startFlexibleUpdate();
        
        if (result == AppUpdateResult.success) {
          // Update downloaded, show snackbar to install
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Update berhasil diunduh'),
                action: SnackBarAction(
                  label: 'Install',
                  onPressed: () {
                    _updateService.completeFlexibleUpdate();
                  },
                ),
                duration: const Duration(seconds: 10),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}