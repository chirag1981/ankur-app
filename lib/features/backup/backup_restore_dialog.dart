import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../providers.dart';

class BackupRestoreDialog extends ConsumerStatefulWidget {
  const BackupRestoreDialog({super.key});

  @override
  ConsumerState<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends ConsumerState<BackupRestoreDialog> {
  bool _isLoading = true;
  bool _isActionInProgress = false;
  String? _actionMessage;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await DatabaseHelper.instance.getDatabaseStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // EXPORT & SHARE TO GOOGLE DRIVE / WHATSAPP
  Future<void> _exportAndShare() async {
    setState(() {
      _isActionInProgress = true;
      _actionMessage = 'Generating database backup...';
    });

    try {
      final backupFile = await DatabaseHelper.instance.createBackupFile();
      setState(() => _isActionInProgress = false);

      final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text: 'Invisible Grills Database Backup - $dateStr',
        subject: 'Invisible Grills Database Backup',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // SAVE TO DOWNLOADS FOLDER
  Future<void> _saveToDownloads() async {
    setState(() {
      _isActionInProgress = true;
      _actionMessage = 'Saving backup to Downloads...';
    });

    try {
      final savedPath = await DatabaseHelper.instance.saveBackupToDownloads();
      setState(() => _isActionInProgress = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Saved to: $savedPath')),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to Downloads: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // IMPORT & RESTORE
  Future<void> _importAndRestore() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      final selectedPath = result.files.single.path!;
      final fileName = result.files.single.name;

      if (!mounted) return;

      // Confirmation Dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
              SizedBox(width: 8),
              Text('Restore Database?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You are about to restore from:'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This will replace your current customers, room measurements, and material rates with the backup content.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes, Restore'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() {
        _isActionInProgress = true;
        _actionMessage = 'Validating and restoring database...';
      });

      final restoreResult = await DatabaseHelper.instance.restoreFromBackup(selectedPath);

      // Refresh all Riverpod state caches
      ref.read(customerControllerProvider).refreshAllData();

      await _loadStats();

      setState(() => _isActionInProgress = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                SizedBox(width: 8),
                Text('Restore Successful!'),
              ],
            ),
            content: Text(
              'Database successfully restored!\n\n'
              '• Customers Restored: ${restoreResult['customers'] ?? 0}\n'
              '• Master Materials: ${restoreResult['materials'] ?? 0}\n\n'
              'Your app now reflects all restored records.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Close backup dialog
                },
                child: const Text('Great!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: AppColors.error, size: 28),
                SizedBox(width: 8),
                Text('Restore Failed'),
              ],
            ),
            content: Text(
              'Could not restore database:\n$e\n\nPlease ensure you selected a valid SQLite backup file.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Backup & Restore',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              Text(
                                'Export to Google Drive / WhatsApp or Restore',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Database Stats Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: _isLoading
                          ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'CURRENT DATABASE STATS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      _formatBytes(_stats['fileSize'] ?? 0),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatPill('Customers', '${_stats['customers'] ?? 0}', Icons.people_alt_outlined),
                                    _buildStatPill('Rooms', '${_stats['rooms'] ?? 0}', Icons.meeting_room_outlined),
                                    _buildStatPill('Windows', '${_stats['windows'] ?? 0}', Icons.window_outlined),
                                    _buildStatPill('Materials', '${_stats['materials'] ?? 0}', Icons.inventory_2_outlined),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),

                    // Section 1: EXPORT / BACKUP
                    const Text(
                      'EXPORT BACKUP',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create a safe copy of your database. Send it to yourself on WhatsApp, save to Google Drive, or keep in Downloads.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                    ),
                    const SizedBox(height: 10),

                    // Button 1: Share to Drive / WhatsApp
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Export & Share (Google Drive / WhatsApp)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isActionInProgress ? null : _exportAndShare,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Button 2: Save to Downloads
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Save Backup to Downloads Folder'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isActionInProgress ? null : _saveToDownloads,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: IMPORT / RESTORE
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    const Text(
                      'RESTORE FROM BACKUP',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pick a previously exported backup file (.db) from Google Drive, WhatsApp, or Downloads to restore on this phone.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                    ),
                    const SizedBox(height: 10),

                    // Restore Warning Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Restoring will overwrite current customer records with the backup file.',
                              style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Button: Pick and Restore
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.restore_page_rounded, size: 18),
                        label: const Text('Select Backup File & Restore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isActionInProgress ? null : _importAndRestore,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading / In-Progress Overlay
            if (_isActionInProgress)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        _actionMessage ?? 'Processing...',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
      ],
    );
  }
}
