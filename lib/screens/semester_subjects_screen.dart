import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'subject_workspace_screen.dart';
import 'recorder_screen.dart';
import 'gemini_explanation_screen.dart';

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
  String _activeFilter = 'all';
  List<SubjectData> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final list = await StorageService.instance.getSubjects(
      semesterId: widget.semester?.id ?? 'sem-3',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject Workspace Settings'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _navigateToWorkspace(SubjectData subject) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubjectWorkspaceScreen(subject: subject),
      ),
    );
    // Reload subjects so updated PDF counts immediately reflect
    _loadSubjects();
  }

  void _showAddSubjectDialog() {
    final codeController = TextEditingController(text: 'CS204');
    final nameController = TextEditingController();
    final profController = TextEditingController();

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
                  'Add New Subject',
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
                hintText: 'e.g. CS204',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                hintText: 'e.g. Computer Architecture',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: profController,
              decoration: const InputDecoration(
                labelText: 'Instructor & Timetable',
                hintText: 'e.g. Dr. Vance • Tue/Thu 10:00 AM',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final code = codeController.text.trim().isEmpty
                      ? 'CS204'
                      : codeController.text.trim();
                  final name = nameController.text.trim().isEmpty
                      ? 'New Academic Course'
                      : nameController.text.trim();
                  final prof = profController.text.trim().isEmpty
                      ? 'Faculty Dept. • TBA'
                      : profController.text.trim();

                  final newSub = SubjectData(
                    code: code,
                    name: name,
                    professor: prof,
                    schedule: 'Mon/Wed 10:00 AM',
                    pdfCount: 0,
                    aiNotesCount: 0,
                    recentStatus: 'Workspace ready for recordings and PDFs',
                    recentStatusIcon: Icons.layers_outlined,
                    icon: Icons.school,
                    iconBg: AppColors.primaryFixed,
                    iconColor: AppColors.royalBlue,
                    category: 'active',
                    semesterId: widget.semester?.id ?? 'sem-3',
                  );

                  await StorageService.instance.addSubject(newSub);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadSubjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name ($code) saved permanently!'),
                        backgroundColor: AppColors.royalBlue,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Subject'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SubjectData> get _filteredSubjects {
    final list = _subjects.isNotEmpty ? _subjects : MockData.subjects;

    if (_activeFilter == 'active') {
      return list
          .where((s) => s.category == 'active' || s.code == 'CS101' || s.code == 'EE204')
          .toList();
    } else if (_activeFilter == 'ai') {
      return list
          .where((s) => s.category == 'ai' || s.code == 'CS202' || s.code == 'MATH201')
          .toList();
    }
    return list;
  }

  int get _totalPdfsInSemester {
    final list = _subjects.isNotEmpty ? _subjects : MockData.subjects;
    int count = 0;
    for (final s in list) {
      count += s.pdfCount;
    }
    return count > 0 ? count : 48;
  }

  @override
  Widget build(BuildContext context) {
    final semTitle = widget.semester?.title ?? 'Semester 3';
    final currentSubjects = _filteredSubjects;
    final totalSubjectsCount = (_subjects.isNotEmpty ? _subjects.length : 6);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'UniNotes AI',
        subtitle: 'Semesters',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              // Sub-Header with Back & Semester Context
              _buildSubHeader(semTitle, totalSubjectsCount),
              const SizedBox(height: 12),

              // Term Summary Pill Ribbon
              _buildSummaryRibbon(),
              const SizedBox(height: 14),

              // Filter Chips
              _buildFilterChips(totalSubjectsCount),
              const SizedBox(height: 16),

              // Subject Cards List
              ...currentSubjects.map((sub) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildSubjectCard(sub),
                );
              }),

              const SizedBox(height: 6),

              // Exam Preparation Tip Card
              _buildExamTipCard(),
              const SizedBox(height: 20),
            ],
          ),

          // Floating Action Button (+ Add Subject)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _showAddSubjectDialog,
              backgroundColor: AppColors.royalBlue,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              icon: const Icon(Icons.auto_awesome, size: 18, color: AppColors.tertiaryFixed),
              label: const Text(
                'Add Subject',
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

  Widget _buildSubHeader(String semTitle, int count) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: AppColors.royalBlue,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                semTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.royalBlue,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'B.S. Software Engineering • $count Subjects',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRibbon() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildRibbonPill(
            icon: Icons.school,
            iconColor: AppColors.secondary,
            label: '18 Credit Hours',
            bgColor: AppColors.surfaceHigh,
            textColor: AppColors.onSurface,
          ),
          const SizedBox(width: 8),
          _buildRibbonPill(
            icon: Icons.description_outlined,
            iconColor: AppColors.royalBlue,
            label: '$_totalPdfsInSemester Total PDFs',
            bgColor: AppColors.secondaryFixed,
            textColor: AppColors.onSecondaryFixed,
          ),
          const SizedBox(width: 8),
          _buildRibbonPill(
            icon: Icons.mic_none,
            iconColor: AppColors.tertiary,
            label: '26 AI Lectures',
            bgColor: AppColors.tertiaryFixed,
            textColor: AppColors.onTertiaryFixed,
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(int totalCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            id: 'all',
            label: 'All Subjects ($totalCount)',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            id: 'active',
            label: 'Active This Week',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            id: 'ai',
            label: 'Has New AI Notes',
            leadingIcon: Icons.auto_awesome,
            iconColor: AppColors.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    IconData? leadingIcon,
    Color? iconColor,
  }) {
    final isActive = _activeFilter == id;

    return InkWell(
      onTap: () => setState(() => _activeFilter = id),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.lightBlue : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x0F004AAD),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 14, color: iconColor ?? AppColors.royalBlue),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.royalBlue : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ambient subtle corner gradient
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                  ),
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.0,
                    colors: [
                      (sub.code == 'CS202'
                              ? AppColors.lightBlue
                              : sub.code == 'MATH201'
                                  ? AppColors.tertiaryFixed
                                  : AppColors.secondaryFixed)
                          .withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + Code + Title + Options Menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: sub.iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(sub.icon, color: sub.iconColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    sub.code,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: sub.iconColor,
                                    ),
                                  ),
                                ),
                                if (sub.hasPulse) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.royalBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                if (sub.badge != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: sub.badge == 'Core'
                                          ? AppColors.royalBlue
                                          : AppColors.tertiaryFixed,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (sub.badge == 'Exam Prep') ...[
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 10,
                                            color: AppColors.tertiaryContainer,
                                          ),
                                          const SizedBox(width: 3),
                                        ],
                                        Text(
                                          sub.badge!,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: sub.badge == 'Core'
                                                ? Colors.white
                                                : AppColors.tertiaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sub.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.outline,
                        ),
                        splashRadius: 18,
                        onPressed: () {},
                      ),
                    ],
                  ),

                  // Professor & Timetable Metadata
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 15,
                        color: AppColors.outline,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sub.professor,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Badges Row (PDF count + AI Notes count)
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              size: 14,
                              color: AppColors.onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${sub.pdfCount} PDFs',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixed,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 13,
                              color: AppColors.tertiaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${sub.aiNotesCount} AI Notes ✨',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Status Pill
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sub.recentStatusIcon,
                          size: 15,
                          color: sub.code == 'MATH201' || sub.code == 'CS202'
                              ? AppColors.tertiary
                              : AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.recentStatus,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: sub.code == 'MATH201' || sub.code == 'CS202'
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: sub.code == 'MATH201'
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.royalBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.tertiaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.psychology,
                color: AppColors.tertiaryContainer,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Exam Preparation Tip',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gemini generated 4 quiz packs from your last 3 lecture recordings.',
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
