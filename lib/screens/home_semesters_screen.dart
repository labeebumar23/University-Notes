import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/drive_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'onboarding_screen.dart';
import 'semester_subjects_screen.dart';
import 'subject_workspace_screen.dart';
import 'recorder_screen.dart';
import 'settings_screen.dart';

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
  String _userName = 'Student';
  String _userMajor = 'Computer Science B.S.';
  int _totalSubjects = 0;
  int _totalPdfs = 0;
  int _totalAudioLectures = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await StorageService.instance.getUserName() ?? 'Student';
    final major = await StorageService.instance.getUserMajor() ?? 'Computer Science B.S.';
    final list = await StorageService.instance.getSemesters();
    final subjects = await StorageService.instance.getSubjects();

    int pdfCountSum = 0;
    int lectureCountSum = 0;
    for (final s in subjects) {
      pdfCountSum += s.pdfCount;
      lectureCountSum += s.aiNotesCount;
    }

    if (mounted) {
      setState(() {
        _userName = name;
        _userMajor = major;
        _semesters = list;
        _totalSubjects = subjects.length;
        _totalPdfs = pdfCountSum;
        _totalAudioLectures = lectureCountSum;
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
      return;
    } else if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RecorderScreen(),
        ),
      ).then((_) => _loadData());
    } else if (index == 2) {
      _navigateToFirstWorkspace();
    } else if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      ).then((_) => _loadData());
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
      ).then((_) => _loadData());
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
    final termController = TextEditingController(text: 'Spring 2026');

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
                hintText: 'e.g. Semester 1, Fall 2025',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: termController,
              decoration: const InputDecoration(
                labelText: 'Academic Term / Year',
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
                      ? 'In Progress'
                      : termController.text.trim();

                  final newSem = SemesterData(
                    id: 'sem-${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    status: 'Active',
                    term: term,
                    subjectsPreview: [],
                    subjectCount: 0,
                    fileCount: 0,
                    fileLabel: 'Files',
                    icon: Icons.school,
                    isCurrent: _semesters.isEmpty,
                    iconBgColor: AppColors.royalBlue,
                    iconColor: Colors.white,
                  );

                  await StorageService.instance.addSemester(newSem);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title created! Tap to add subjects.'),
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

  void _showEditSemesterDialog(SemesterData semester) {
    final titleController = TextEditingController(text: semester.title);
    final termController = TextEditingController(text: semester.term);
    String currentStatus = semester.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                    'Edit Semester',
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
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: termController,
                decoration: const InputDecoration(
                  labelText: 'Academic Term / Year',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: ['Active', 'In Progress', 'Completed', 'Upcoming'].contains(currentStatus)
                    ? currentStatus
                    : 'Active',
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Active', 'In Progress', 'Completed', 'Upcoming']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setSheetState(() => currentStatus = val);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final updated = semester.copyWith(
                      title: titleController.text.trim().isEmpty
                          ? semester.title
                          : titleController.text.trim(),
                      term: termController.text.trim().isEmpty
                          ? semester.term
                          : termController.text.trim(),
                      status: currentStatus,
                    );
                    await StorageService.instance.updateSemester(updated);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${updated.title} updated!'),
                          backgroundColor: AppColors.royalBlue,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteSemesterConfirm(SemesterData semester) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${semester.title}?'),
        content: const Text(
          'This will permanently delete this semester and all its subjects, PDFs, and audio recordings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.instance.deleteSemester(semester.id);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${semester.title} deleted.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showSgpaCalculator(SemesterData semester) async {
    final allSubjects = await StorageService.instance.getSubjects();
    final semesterSubjects = allSubjects.where((s) => s.semesterId == semester.id).toList();

    if (semesterSubjects.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Courses Found'),
          content: Text('Please add courses to ${semester.title} before calculating SGPA.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final Map<String, int> creditMap = {
      for (final s in semesterSubjects) s.code: s.creditHours > 0 ? s.creditHours : 3
    };
    final Map<String, String> gradeMap = {
      for (final s in semesterSubjects) s.code: s.grade ?? 'A'
    };

    final gradeScale = {
      'A': 4.0,
      'A-': 3.7,
      'B+': 3.3,
      'B': 3.0,
      'B-': 2.7,
      'C+': 2.3,
      'C': 2.0,
      'C-': 1.7,
      'D': 1.0,
      'F': 0.0,
    };

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          double totalPoints = 0;
          int totalCredits = 0;
          for (final s in semesterSubjects) {
            final cr = creditMap[s.code] ?? 3;
            final gr = gradeMap[s.code] ?? 'A';
            final pts = gradeScale[gr] ?? 4.0;
            totalPoints += (cr * pts);
            totalCredits += cr;
          }
          final currentSgpa = totalCredits > 0 ? (totalPoints / totalCredits) : 0.0;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SGPA Calculator',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.royalBlue,
                            ),
                          ),
                          Text(
                            semester.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00357F), Color(0xFF004AAD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.royalBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CALCULATED SGPA',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD9E2FF),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currentSgpa.toStringAsFixed(2)} / 4.00',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalCredits Credits',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Course Grades & Credit Hours',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...semesterSubjects.map((sub) {
                    final credits = creditMap[sub.code] ?? 3;
                    final grade = gradeMap[sub.code] ?? 'A';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF272730)
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.code,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                                Text(
                                  sub.name,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          DropdownButton<int>(
                            value: credits,
                            underline: const SizedBox(),
                            items: [1, 2, 3, 4, 5]
                                .map((c) => DropdownMenuItem(value: c, child: Text('$c Cr')))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => creditMap[sub.code] = val);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: grade,
                            underline: const SizedBox(),
                            items: gradeScale.keys
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => gradeMap[sub.code] = val);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        for (final s in semesterSubjects) {
                          final updatedSub = s.copyWith(
                            creditHours: creditMap[s.code] ?? 3,
                            grade: gradeMap[s.code] ?? 'A',
                          );
                          await StorageService.instance.updateSubject(updatedSub);
                        }
                        await StorageService.instance.saveSemesterSgpa(semester.id, currentSgpa);

                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${semester.title} SGPA: ${currentSgpa.toStringAsFixed(2)} saved!',
                              ),
                              backgroundColor: AppColors.royalBlue,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save SGPA to Semester'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final majorCtrl = TextEditingController(text: _userMajor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: majorCtrl,
              decoration: const InputDecoration(labelText: 'Major / Degree'),
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
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Save'),
          ),
        ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'UniNotes Settings',
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
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.royalBlue),
              title: Text(_userName),
              subtitle: Text(_userMajor),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditProfileDialog();
                },
                child: const Text('Edit'),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mic, color: AppColors.royalBlue),
              title: const Text('Audio Recording Engine'),
              subtitle: const Text('AAC-LC High Fidelity • Local Documents Storage'),
              trailing: const Icon(Icons.check_circle, color: AppColors.success),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync, color: AppColors.royalBlue),
              title: const Text('Google Drive Backup'),
              subtitle: Text(DriveService.instance.isSignedIn ? 'Connected' : 'Not Connected'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showDriveAuthSheet();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Reset All App Data', style: TextStyle(color: AppColors.error)),
              subtitle: const Text('Wipes local storage and restarts onboarding'),
              onTap: () {
                Navigator.pop(context);
                _confirmResetData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your semesters, subjects, PDFs, and audio recordings. This action cannot be undone.',
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
            child: const Text('Reset All', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          final userName = DriveService.instance.userDisplayName;
          final userEmail = DriveService.instance.userEmail;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Google Drive Cloud Backup',
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
                if (isConnected) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.royalBlue,
                      child: Icon(Icons.cloud_done, color: Colors.white),
                    ),
                    title: Text(userName),
                    subtitle: Text(userEmail),
                    trailing: const Chip(
                      label: Text('Active', style: TextStyle(color: AppColors.success, fontSize: 11)),
                      backgroundColor: AppColors.successContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await DriveService.instance.signOut();
                      setSheetState(() {});
                      setState(() {});
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Disconnect Google Drive'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Connect your Google Account to back up course PDFs and class audio lectures to Google Drive in the "UniNotes Backup" folder.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await DriveService.instance.signIn();
                      setSheetState(() {});
                      setState(() {});
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Connected to Google Drive!'
                                  : 'Could not connect. You can also test with demo account.',
                            ),
                            backgroundColor: success ? AppColors.royalBlue : AppColors.error,
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
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displaySemesters = _semesters;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'UniNotes',
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

              // Quick Scholastic Stats
              _buildQuickStats(),
              const SizedBox(height: 20),

              // "Your Semesters" Header Row
              _buildSectionHeader(),
              const SizedBox(height: 14),

              // Semesters List / Grid / Empty State
              if (displaySemesters.isEmpty)
                _buildEmptySemestersState()
              else if (_isGridView)
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
                children: [
                  Flexible(
                    child: Text(
                      'Welcome, $_userName!',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 20)),
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
                  Flexible(
                    child: Text(
                      _userMajor,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Student Monogram Avatar (Tappable to Settings)
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ).then((_) => _loadData());
          },
          borderRadius: BorderRadius.circular(24),
          child: Tooltip(
            message: 'Open Settings',
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.royalBlue,
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            count: '$_totalSubjects',
            label: 'Courses',
            icon: Icons.menu_book,
            iconBg: AppColors.lightBlue.withOpacity(0.35),
            iconColor: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            count: '$_totalAudioLectures',
            label: 'Audio Lectures',
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
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage your academic semesters and subjects',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_outlined,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptySemestersState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 32,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Semesters Created Yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first academic semester to start adding courses, uploading PDFs, and recording class audio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddSemesterDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Semester'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemestersList(List<SemesterData> semesters) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: semesters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildSemesterCard(semesters[index]);
      },
    );
  }

  Widget _buildSemestersGrid(List<SemesterData> semesters) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: semesters.length,
      itemBuilder: (context, index) {
        return _buildSemesterCard(semesters[index]);
      },
    );
  }

  Widget _buildSemesterCard(SemesterData sem) {
    return InkWell(
      onTap: () => _navigateToSemester(sem),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sem.isCurrent ? AppColors.lightBlue : AppColors.border(context),
            width: sem.isCurrent ? 1.5 : 1.0,
          ),
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
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: AppColors.royalBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditSemesterDialog(sem);
                    } else if (value == 'delete') {
                      _showDeleteSemesterConfirm(sem);
                    } else if (value == 'sgpa') {
                      _showSgpaCalculator(sem);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'sgpa',
                      child: Row(
                        children: [
                          Icon(Icons.calculate_outlined, color: AppColors.warmGold, size: 18),
                          SizedBox(width: 8),
                          Text('Calculate SGPA'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: AppColors.royalBlue, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Semester'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          SizedBox(width: 8),
                          Text('Delete Semester', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text('${sem.subjectCount} Courses', style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.surfaceContainer,
                  visualDensity: VisualDensity.compact,
                ),
                if (sem.sgpa != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warmGold.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warmGold.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 13, color: AppColors.warmGold),
                        const SizedBox(width: 4),
                        Text(
                          'SGPA: ${sem.sgpa!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warmGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.royalBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.royalBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACADEMIC STUDY TIP',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Record class audio and attach course syllabus PDFs for instant access throughout the semester.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
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
