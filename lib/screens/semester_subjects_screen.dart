import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'subject_workspace_screen.dart';
import 'recorder_screen.dart';
import 'settings_screen.dart';

class SemesterSubjectsScreen extends StatefulWidget {
  final SemesterData? semester;

  const SemesterSubjectsScreen({
    super.key,
    this.semester,
  });

  @override
  State<SemesterSubjectsScreen> createState() => _SemesterSubjectsScreenState();
}

class _SemesterSubjectsScreenState extends State<SemesterSubjectsScreen> {
  List<SubjectData> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final list = await StorageService.instance.getSubjects(
      semesterId: widget.semester?.id,
    );
    if (mounted) {
      setState(() {
        _subjects = list;
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
          builder: (context) => RecorderScreen(
            subject: _subjects.isNotEmpty ? _subjects.first : null,
          ),
        ),
      ).then((_) => _loadSubjects());
    } else if (index == 2) {
      if (_subjects.isNotEmpty) {
        _navigateToWorkspace(_subjects.first);
      }
    } else if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      ).then((_) => _loadSubjects());
    }
  }

  Future<void> _navigateToWorkspace(SubjectData subject) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubjectWorkspaceScreen(subject: subject),
      ),
    );
    _loadSubjects();
  }

  void _showAddSubjectDialog() {
    final codeController = TextEditingController(text: 'CS${_subjects.length + 1}01');
    final nameController = TextEditingController();
    final profController = TextEditingController();
    final scheduleController = TextEditingController(text: 'Mon / Wed 10:00 AM');

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
                  'Add New Course',
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
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Course Code',
                hintText: 'e.g. CS202, MATH101',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                hintText: 'e.g. Data Structures & Algorithms',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: profController,
              decoration: const InputDecoration(
                labelText: 'Professor / Instructor',
                hintText: 'e.g. Dr. Vance Evans',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scheduleController,
              decoration: const InputDecoration(
                labelText: 'Class Schedule',
                hintText: 'e.g. Tue / Thu 10:00 AM • Hall 402',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final code = codeController.text.trim().isEmpty
                      ? 'CS${_subjects.length + 1}01'
                      : codeController.text.trim().toUpperCase();
                  final name = nameController.text.trim().isEmpty
                      ? 'Course $code'
                      : nameController.text.trim();
                  final prof = profController.text.trim().isEmpty
                      ? 'Faculty Professor'
                      : profController.text.trim();
                  final schedule = scheduleController.text.trim();

                  final newSub = SubjectData(
                    code: code,
                    name: name,
                    professor: prof,
                    schedule: schedule,
                    pdfCount: 0,
                    aiNotesCount: 0,
                    recentStatus: 'Course workspace ready',
                    recentStatusIcon: Icons.layers_outlined,
                    icon: Icons.school,
                    iconBg: AppColors.primaryFixed,
                    iconColor: AppColors.royalBlue,
                    category: 'active',
                    semesterId: widget.semester?.id ?? 'sem-default',
                  );

                  await StorageService.instance.addSubject(newSub);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadSubjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name ($code) added!'),
                        backgroundColor: AppColors.royalBlue,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Save Course'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubjectDialog(SubjectData sub) {
    final codeController = TextEditingController(text: sub.code);
    final nameController = TextEditingController(text: sub.name);
    final profController = TextEditingController(text: sub.professor);
    final scheduleController = TextEditingController(text: sub.schedule);

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
                  'Edit Course',
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
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Course Code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Course Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: profController,
              decoration: const InputDecoration(labelText: 'Professor / Instructor'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scheduleController,
              decoration: const InputDecoration(labelText: 'Class Schedule'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updated = sub.copyWith(
                    code: codeController.text.trim().isEmpty ? sub.code : codeController.text.trim().toUpperCase(),
                    name: nameController.text.trim().isEmpty ? sub.name : nameController.text.trim(),
                    professor: profController.text.trim().isEmpty ? sub.professor : profController.text.trim(),
                    schedule: scheduleController.text.trim(),
                  );
                  await StorageService.instance.updateSubject(updated);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadSubjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${updated.code} updated!'),
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
    );
  }

  void _showDeleteSubjectConfirm(SubjectData sub) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${sub.code}?'),
        content: Text(
          'This will permanently delete ${sub.name} and all its PDFs and audio recordings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.instance.deleteSubject(sub.code);
              _loadSubjects();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${sub.code} deleted.'),
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

  @override
  Widget build(BuildContext context) {
    final semTitle = widget.semester?.title ?? 'Semester';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'UniNotes',
        subtitle: semTitle,
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              // Header Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        semTitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        '${_subjects.length} enrolled ${_subjects.length == 1 ? "course" : "courses"}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _showAddSubjectDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Course'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.royalBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Subjects List or Empty State
              if (_subjects.isEmpty)
                _buildEmptySubjectsState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildSubjectCard(_subjects[index]);
                  },
                ),
            ],
          ),

          // Floating Action Button (+ Add Course)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _showAddSubjectDialog,
              backgroundColor: AppColors.royalBlue,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Course',
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

  Widget _buildEmptySubjectsState() {
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
              Icons.menu_book_outlined,
              size: 32,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Courses Added Yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add courses (e.g. Data Structures, Physics) to start uploading PDFs and recording lectures.',
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
            onPressed: _showAddSubjectDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Course'),
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

  Widget _buildSubjectCard(SubjectData sub) {
    return InkWell(
      onTap: () => _navigateToWorkspace(sub),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      sub.code.length > 4 ? sub.code.substring(0, 4) : sub.code,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.royalBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        sub.professor,
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
                      _showEditSubjectDialog(sub);
                    } else if (value == 'delete') {
                      _showDeleteSubjectConfirm(sub);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: AppColors.royalBlue, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Course'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          SizedBox(width: 8),
                          Text('Delete Course', style: TextStyle(color: AppColors.error)),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.graphic_eq, size: 13, color: AppColors.royalBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${sub.aiNotesCount} Audio Lectures',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_outlined, size: 13, color: AppColors.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${sub.pdfCount} PDFs',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.royalBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
