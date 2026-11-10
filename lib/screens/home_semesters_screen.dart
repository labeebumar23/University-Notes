import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/drive_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'semester_subjects_screen.dart';
import 'recorder_screen.dart';
import 'gemini_explanation_screen.dart';

class HomeSemestersScreen extends StatefulWidget {
  const HomeSemestersScreen({super.key});

  @override
  State<HomeSemestersScreen> createState() => _HomeSemestersScreenState();
}

class _HomeSemestersScreenState extends State<HomeSemestersScreen> {
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();
  List<SemesterData> _semesters = [];
  bool _isLoading = true;
  int _totalPdfs = 128;
  int _totalSubjects = 8;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await StorageService.instance.getSemesters();
    final subjects = await StorageService.instance.getSubjects();
    int pdfCountSum = 0;
    for (final s in subjects) {
      pdfCountSum += s.pdfCount;
    }
    if (pdfCountSum == 0) pdfCountSum = 128;

    if (mounted) {
      setState(() {
        _semesters = list;
        _totalSubjects = subjects.isNotEmpty ? subjects.length : 8;
        _totalPdfs = pdfCountSum;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      // Already on semesters
      return;
    } else if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RecorderScreen(),
        ),
      );
    } else if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const GeminiExplanationScreen(),
        ),
      );
    } else if (index == 3) {
      _showSettingsSheet();
    }
  }

  Future<void> _navigateToSemester(SemesterData semester) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SemesterSubjectsScreen(semester: semester),
      ),
    );
    _loadData();
  }

  void _showAddSemesterDialog() {
    final titleController = TextEditingController(text: 'Semester ${_semesters.length + 1}');
    final termController = TextEditingController(text: 'Fall 2025 - Spring 2026');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Semester',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Semester Title',
                hintText: 'e.g. Semester 5',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: termController,
              decoration: const InputDecoration(
                labelText: 'Academic Term',
                hintText: 'e.g. Fall 2025 - Spring 2026',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim().isEmpty
                      ? 'Semester ${_semesters.length + 1}'
                      : titleController.text.trim();
                  final term = termController.text.trim().isEmpty
                      ? 'Upcoming'
                      : termController.text.trim();

                  final newSem = SemesterData(
                    id: 'sem-${_semesters.length + 1}',
                    title: title,
                    status: 'Upcoming',
                    term: term,
                    subjectsPreview: ['CS 490 Project', 'CS 495 Seminar'],
                    subjectCount: 2,
                    fileCount: 0,
                    fileLabel: 'Files',
                    icon: Icons.upcoming,
                    isCurrent: false,
                    iconBgColor: AppColors.surfaceHigh,
                    iconColor: AppColors.onSurfaceVariant,
                  );

                  await StorageService.instance.addSemester(newSem);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title added & saved permanently!'),
                        backgroundColor: AppColors.royalBlue,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Semester'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UniNotes AI Settings',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.psychology, color: AppColors.tertiary),
              title: const Text('Gemini 1.5 Pro AI Engine'),
              subtitle: const Text('Active • 2-Hour Audio Context Window'),
              trailing: const Icon(Icons.check_circle, color: AppColors.success),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync, color: AppColors.royalBlue),
              title: const Text('Live Sync & Local Storage'),
              subtitle: const Text('SharedPreferences Persistence Active'),
              trailing: const Icon(Icons.toggle_on, color: AppColors.royalBlue, size: 36),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined, color: AppColors.onSurfaceVariant),
              title: const Text('Appearance'),
              subtitle: const Text('Academic Precision (Warm Parchment)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriveAuthSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isConnected = DriveService.instance.isSignedIn;
          final userEmail = DriveService.instance.userEmail;
          final userName = DriveService.instance.userDisplayName;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryFixed,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_sync,
                          color: AppColors.royalBlue,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Google Drive Cloud Backup',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isConnected
                                ? 'Connected • Folder: /UniNotes Backup'
                                : 'Sign in to sync your PDFs and Lectures',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (isConnected) ...[
                  // User info container
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.royalBlue,
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Backup target info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.folder_special_outlined,
                            size: 20, color: AppColors.tertiary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Files are backed up to Google Drive > "UniNotes Backup" folder.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Sign Out Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      await DriveService.instance.signOut();
                      setSheetState(() {});
                      setState(() {});
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Disconnected from Google Drive.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Disconnect Google Drive'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ] else ...[
                  // Not connected explanation
                  const Text(
                    'Connect your Google Account to automatically upload your course PDFs and recorded .m4a class audio lectures to your personal Google Drive in the "UniNotes Backup" folder.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Primary Sign in Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Initiating Google Sign-In for Drive...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      final success = await DriveService.instance.signIn();
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Connected to Google Drive! (${DriveService.instance.userEmail})'
                                : 'Google Sign-In canceled or required OAuth credentials. Try Demo Account for preview.'),
                            backgroundColor: success
                                ? AppColors.royalBlue
                                : AppColors.error,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.account_circle, color: Colors.white),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Demo Account button for frictionless preview
                  OutlinedButton.icon(
                    onPressed: () {
                      DriveService.instance.signInWithDemoAccount();
                      setSheetState(() {});
                      setState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Connected with Demo Google Account (Alex Morgan) for Drive preview!'),
                          backgroundColor: AppColors.royalBlue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.cloud_outlined, size: 18),
                    label: const Text('Test with Demo Google Account'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displaySemesters = _semesters.isNotEmpty ? _semesters : MockData.semesters;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'UniNotes AI',
        subtitle: 'Semesters',
        showDriveBackup: true,
        isDriveConnected: DriveService.instance.isSignedIn,
        onDriveBackup: _showDriveAuthSheet,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              // Greeting Section
              _buildGreetingSection(),
              const SizedBox(height: 16),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 16),

              // Quick Scholastic Stats
              _buildQuickStats(),
              const SizedBox(height: 20),

              // "Your Semesters" Header Row
              _buildSectionHeader(),
              const SizedBox(height: 14),

              // Semesters List / Grid
              if (_isGridView)
                _buildSemestersGrid(displaySemesters)
              else
                _buildSemestersList(displaySemesters),
              const SizedBox(height: 18),

              // Study Motivation Card
              _buildMotivationCard(),
              const SizedBox(height: 20),
            ],
          ),

          // Floating Action Button (+ Add Semester)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _showAddSemesterDialog,
              backgroundColor: AppColors.royalBlue,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Semester',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: UniBottomNavBar(
        currentIndex: 0,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Welcome back, Alex!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Spring 2025 • Computer Science B.S.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Editorial Photo Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Image.network(
              'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=150&q=80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_stories,
                color: AppColors.royalBlue,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081E293B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: 'Search PDFs, subjects, or AI lectures...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.outline,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 19, color: AppColors.royalBlue),
            splashRadius: 18,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter options: All, In Progress, Archived'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            count: '$_totalSubjects',
            label: 'Active Subjects',
            icon: Icons.menu_book,
            iconBg: AppColors.lightBlue.withOpacity(0.35),
            iconColor: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            count: '42',
            label: 'AI Lectures',
            icon: Icons.graphic_eq,
            iconBg: AppColors.tertiaryFixed,
            iconColor: AppColors.tertiaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            count: '$_totalPdfs',
            label: 'PDFs Saved',
            icon: Icons.description_outlined,
            iconBg: AppColors.primaryFixed,
            iconColor: AppColors.royalBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061E293B),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your Semesters',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Academic progression timeline',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        // Grid / List View Toggle Pill
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _isGridView = false),
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: !_isGridView ? AppColors.surfaceLowest : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: !_isGridView
                        ? const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.view_agenda_outlined,
                    size: 17,
                    color: !_isGridView ? AppColors.royalBlue : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isGridView = true),
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isGridView ? AppColors.surfaceLowest : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: _isGridView
                        ? const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.grid_view,
                    size: 17,
                    color: _isGridView ? AppColors.royalBlue : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSemestersList(List<SemesterData> list) {
    return Column(
      children: list.map((sem) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildSemesterCard(sem),
        );
      }).toList(),
    );
  }

  Widget _buildSemestersGrid(List<SemesterData> list) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final sem = list[index];
        return _buildSemesterGridCard(sem);
      },
    );
  }

  Widget _buildSemesterCard(SemesterData sem) {
    return InkWell(
      onTap: () => _navigateToSemester(sem),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sem.isCurrent ? AppColors.lightBlue : AppColors.outlineVariant,
            width: sem.isCurrent ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: sem.isCurrent
                  ? AppColors.royalBlue.withOpacity(0.08)
                  : const Color(0x061E293B),
              blurRadius: sem.isCurrent ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ambient Top-Right Radial Glow for Active Semester
            if (sem.isCurrent)
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightBlue.withOpacity(0.35),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Icon + Title + Status Badge + Arrow
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: sem.iconBgColor ?? AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: sem.isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.royalBlue.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          sem.icon,
                          color: sem.iconColor ?? AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  sem.title,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(sem),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sem.term,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: sem.isCurrent
                              ? AppColors.lightBlue.withOpacity(0.3)
                              : AppColors.surfaceLow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: sem.isCurrent
                              ? AppColors.royalBlue
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  // Subject Pills
                  if (sem.subjectsPreview.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: sem.subjectsPreview.map((sub) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sub,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Progress Bar for In-Progress Semester
                  if (sem.syllabusCompletion != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Syllabus Completion',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(sem.syllabusCompletion! * 100).toInt()}%',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: sem.syllabusCompletion,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceContainer,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.royalBlue),
                      ),
                    ),
                  ],

                  // Meta Footer Row
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories,
                            size: 15,
                            color: sem.isCurrent
                                ? AppColors.royalBlue
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${sem.subjectCount} Subjects',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            sem.fileLabel.contains('Archived')
                                ? Icons.inventory_2_outlined
                                : sem.fileLabel.contains('Syllabi')
                                    ? Icons.picture_as_pdf
                                    : Icons.mic_none,
                            size: 15,
                            color: sem.isCurrent
                                ? AppColors.tertiary
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${sem.fileCount} ${sem.fileLabel}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (sem.isLiveSynced)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryFixed.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.bolt,
                                size: 12,
                                color: AppColors.tertiaryContainer,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Live Synced',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tertiaryContainer,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (sem.gpa != null)
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        )
                      else if (sem.status == 'Upcoming')
                        const Text(
                          'Early Prep',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterGridCard(SemesterData sem) {
    return InkWell(
      onTap: () => _navigateToSemester(sem),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sem.isCurrent ? AppColors.royalBlue : AppColors.outlineVariant,
            width: sem.isCurrent ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x061E293B),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: sem.iconBgColor ?? AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    sem.icon,
                    color: sem.iconColor ?? AppColors.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                _buildStatusBadge(sem),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sem.title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              sem.term,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.auto_stories, size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${sem.subjectCount} Subjects',
                  style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SemesterData sem) {
    if (sem.status == 'In Progress') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'In Progress',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.onSecondaryFixed,
          ),
        ),
      );
    } else if (sem.status == 'Upcoming') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Upcoming',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    } else if (sem.gpa != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.secondaryFixed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          sem.gpa!,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.onSecondaryFixed,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
              ),
              child: Image.network(
                'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=150&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.tertiaryFixed,
                  child: const Icon(
                    Icons.tips_and_updates,
                    color: AppColors.tertiaryContainer,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.tips_and_updates,
                      size: 14,
                      color: AppColors.tertiaryContainer,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'GEMINI STUDY TIP',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tertiaryContainer,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '3 recordings from this week are ready for lecture flashcard conversion.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
