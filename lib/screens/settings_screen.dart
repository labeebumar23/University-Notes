import 'package:flutter/material.dart';
import '../services/drive_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'onboarding_screen.dart';
import 'recorder_screen.dart';
import 'subject_workspace_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'Student';
  String _userMajor = 'Computer Science B.S.';
  bool _isLoading = true;

  int _pdfBytes = 0;
  int _lectureBytes = 0;
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final name = await StorageService.instance.getUserName() ?? 'Student';
    final major = await StorageService.instance.getUserMajor() ?? 'Computer Science B.S.';
    final usage = await StorageService.instance.getStorageUsageBytes();

    if (mounted) {
      setState(() {
        _userName = name;
        _userMajor = major;
        _pdfBytes = usage['pdfs'] ?? 0;
        _lectureBytes = usage['lectures'] ?? 0;
        _totalBytes = usage['total'] ?? 0;
        _isLoading = false;
      });
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RecorderScreen(),
        ),
      ).then((_) => _loadSettings());
    } else if (index == 2) {
      _navigateToFirstWorkspace();
    } else if (index == 3) {
      // Already on settings
      return;
    }
  }

  Future<void> _navigateToFirstWorkspace() async {
    final subjects = await StorageService.instance.getSubjects();
    if (subjects.isNotEmpty) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SubjectWorkspaceScreen(subject: subjects.first),
        ),
      ).then((_) => _loadSettings());
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a semester and subject first to open Workspace!'),
          backgroundColor: AppColors.royalBlue,
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final majorCtrl = TextEditingController(text: _userMajor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Edit Student Profile',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g. Labeeb Umar',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: majorCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Major / Degree',
                hintText: 'e.g. Computer Science B.S.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await StorageService.instance.setUserName(nameCtrl.text.trim());
                await StorageService.instance.setUserMajor(majorCtrl.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _loadSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: AppColors.royalBlue,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Factory Reset App?'),
          ],
        ),
        content: const Text(
          'This will permanently delete:\n'
          '• All created Semesters and Courses\n'
          '• All local PDF course notes\n'
          '• All class audio recordings (.m4a)\n'
          '• Student profile name\n\n'
          'The app will return to the initial onboarding screen. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.instance.clearAllData();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'UniNotes',
        subtitle: 'Settings',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.royalBlue),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 1. Student Profile Card
                _buildProfileCard(),
                const SizedBox(height: 18),

                // 2. Storage Usage Card
                _buildStorageCard(),
                const SizedBox(height: 18),

                // 3. Cloud & Offline Info
                _buildOfflineInfoCard(),
                const SizedBox(height: 18),

                // 4. Danger Zone (Factory Reset)
                _buildDangerZoneCard(),
                const SizedBox(height: 24),

                // App Version info
                const Center(
                  child: Text(
                    'UniNotes Study Suite v1.0.0 (Production Release)\n100% Offline • Material 3 Academic Precision',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: UniBottomNavBar(
        currentIndex: 3,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061E293B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STUDENT PROFILE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.royalBlue,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton.icon(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.royalBlue,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.royalBlue,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userMajor,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061E293B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STORAGE USAGE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.royalBlue,
                  letterSpacing: 0.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _loadSettings,
                tooltip: 'Refresh Storage Usage',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatBytes(_totalBytes),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'total on-device storage used',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _totalBytes > 0 ? (_pdfBytes / _totalBytes).clamp(0.05, 0.95) : 0.0,
              minHeight: 8,
              backgroundColor: AppColors.tertiaryFixed,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.royalBlue),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.royalBlue, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                'PDF Notes: ${_formatBytes(_pdfBytes)}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurface),
              ),
              const Spacer(),
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.tertiaryFixed, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                'Audio Lectures: ${_formatBytes(_lectureBytes)}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OFFLINE & CLOUD CAPABILITIES',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.royalBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.offline_pin_outlined, color: AppColors.success),
            title: Text('100% Offline Capable'),
            subtitle: Text('All PDFs and recorded .m4a lectures are copied and kept permanently inside the app\'s internal documents directory.'),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              DriveService.instance.isSignedIn ? Icons.cloud_done : Icons.cloud_outlined,
              color: DriveService.instance.isSignedIn ? AppColors.success : AppColors.royalBlue,
            ),
            title: const Text('Google Drive Backup'),
            subtitle: Text(
              DriveService.instance.isSignedIn
                  ? 'Connected as ${DriveService.instance.userDisplayName}'
                  : 'Optional: Connect your account to back up copies to cloud',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESET & STORAGE CLEAR',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clear all stored data and reset the app. This deletes all PDFs and audio files from local device storage.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _confirmClearAllData,
            icon: const Icon(Icons.delete_forever, size: 18, color: AppColors.error),
            label: const Text('Clear All Data (Factory Reset)', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

