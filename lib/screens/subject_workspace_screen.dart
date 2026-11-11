import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/drive_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'recorder_screen.dart';
import 'gemini_explanation_screen.dart';

class SubjectWorkspaceScreen extends StatefulWidget {
  final SubjectData? subject;

  const SubjectWorkspaceScreen({
    super.key,
    this.subject,
  });

  @override
  State<SubjectWorkspaceScreen> createState() => _SubjectWorkspaceScreenState();
}

class _SubjectWorkspaceScreenState extends State<SubjectWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;
  List<PdfItemData> _pdfs = [];
  bool _isLoadingPdfs = true;
  List<LectureItemData> _lectures = [];
  bool _isLoadingLectures = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _activeTabIndex = _tabController.index;
      });
    });
    final subCode = widget.subject?.code ?? 'CS202';
    _loadPdfs(subCode);
    _loadLectures(subCode);
  }

  Future<void> _loadPdfs(String subjectCode) async {
    final list = await StorageService.instance.getPdfsForSubject(subjectCode);
    if (mounted) {
      setState(() {
        _pdfs = list;
        _isLoadingPdfs = false;
      });
    }
  }

  Future<void> _loadLectures(String subjectCode) async {
    final list =
        await StorageService.instance.getLecturesForSubject(subjectCode);
    if (mounted) {
      setState(() {
        _lectures = list;
        _isLoadingLectures = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 1) {
      _navigateToRecorder();
    } else if (index == 2) {
      _navigateToGeminiExplanation();
    } else if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workspace Settings'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _navigateToRecorder() async {
    final sub = widget.subject ?? MockData.subjects[3];
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecorderScreen(subject: sub),
      ),
    );
    final subCode = sub.code;
    await _loadLectures(subCode);
    await _loadPdfs(subCode);
  }

  void _navigateToGeminiExplanation([LectureItemData? lecture]) {
    final sub = widget.subject ?? MockData.subjects[3];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GeminiExplanationScreen(
          subject: sub,
          lecture: lecture,
        ),
      ),
    );
  }

  Future<void> _backupPdf(String subjectCode, PdfItemData pdf) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Backing up "${pdf.title}" to Google Drive...'),
            ),
          ],
        ),
        backgroundColor: AppColors.royalBlue,
        duration: const Duration(seconds: 2),
      ),
    );

    final result = await DriveService.instance.uploadPdf(pdf);

    if (result.success) {
      final updatedPdf = pdf.copyWith(
        isBackedUp: true,
        driveFileId: result.fileId,
      );
      await StorageService.instance.updatePdfInSubject(subjectCode, updatedPdf);
      await _loadPdfs(subjectCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ??
                'Successfully backed up "${pdf.title}" to Google Drive!'),
            backgroundColor: AppColors.royalBlue,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Drive backup failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _backupLecture(
      String subjectCode, LectureItemData lecture) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Backing up "${lecture.title}" (.m4a) to Google Drive...'),
            ),
          ],
        ),
        backgroundColor: AppColors.royalBlue,
        duration: const Duration(seconds: 2),
      ),
    );

    final result = await DriveService.instance.uploadLectureAudio(lecture);

    if (result.success) {
      final updatedLecture = lecture.copyWith(
        isBackedUp: true,
        driveFileId: result.fileId,
      );
      await StorageService.instance
          .updateLectureInSubject(subjectCode, updatedLecture);
      await _loadLectures(subjectCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ??
                'Successfully backed up "${lecture.title}" to Google Drive!'),
            backgroundColor: AppColors.royalBlue,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Drive backup failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndUploadPdf(String subjectCode) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isNotEmpty) {
        int addedCount = 0;
        for (final file in files) {
          final fileName = file.name;
          final filePath = file.path;
          int fileSizeInBytes = file.lengthSync() ?? (await file.length()) ?? 0;
          if (fileSizeInBytes <= 0 && filePath != null) {
            try {
              final ioFile = File(filePath);
              if (ioFile.existsSync()) {
                fileSizeInBytes = ioFile.lengthSync();
              }
            } catch (_) {}
          }
          final sizeString = _formatFileSize(fileSizeInBytes);

          final newPdf = PdfItemData(
            title: fileName,
            size: sizeString,
            addedDate: 'Added today',
            tag: 'Uploaded',
            tagColor: AppColors.royalBlue,
            icon: Icons.picture_as_pdf,
            iconBg: AppColors.errorContainer,
            iconColor: AppColors.error,
            filePath: filePath,
          );

          await StorageService.instance.addPdfToSubject(subjectCode, newPdf);
          addedCount++;
        }

        await _loadPdfs(subjectCode);

        // Switch to PDF tab so user immediately sees their uploaded PDF
        setState(() {
          _activeTabIndex = 1;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                addedCount == 1
                    ? 'Uploaded "${files.first.name}" to $subjectCode!'
                    : 'Successfully uploaded $addedCount PDFs to $subjectCode!',
              ),
              backgroundColor: AppColors.royalBlue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selection note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showUploadPdfSheet(String subjectCode) {
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
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.secondaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file,
                color: AppColors.royalBlue,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Upload Course Material',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select PDFs from your device storage. Files are saved permanently under this subject.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadPdf(subjectCode);
              },
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Choose PDF from Device'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subject ?? MockData.subjects[3]; // CS202 by default
    final pdfList = _pdfs.isNotEmpty ? _pdfs : MockData.pdfs;
    final lectureList = _lectures.isNotEmpty ? _lectures : MockData.lectures;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'UniNotes AI',
        subtitle: 'Ai Notes',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Subject Header Bar
          _buildSubjectHeaderBar(sub),
          const SizedBox(height: 12),

          // Hero Subject Snapshot Card
          _buildHeroCard(),
          const SizedBox(height: 14),

          // Segmented Dual Tab Controls
          _buildSegmentedTabControls(lectureList.length, pdfList.length),
          const SizedBox(height: 16),

          // Action Launch Banner (Record Lecture + Upload PDF)
          _buildActionLaunchBanner(sub.code),
          const SizedBox(height: 18),

          // Tab Content (AI Lectures or PDF Notes)
          if (_activeTabIndex == 0) ...[
            _buildAiLecturesSection(sub, lectureList),
            const SizedBox(height: 20),
            _buildCoursePdfsSection(sub.code, pdfList),
          ] else ...[
            _buildCoursePdfsSection(sub.code, pdfList),
            const SizedBox(height: 20),
            _buildAiLecturesSection(sub, lectureList),
          ],

          const SizedBox(height: 16),

          // Smart Quick Study Widget: Gemini Knowledge Graph
          _buildKnowledgeGraphWidget(),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: UniBottomNavBar(
        currentIndex: 2,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildSubjectHeaderBar(SubjectData sub) {
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
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: AppColors.onSurface,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.royalBlue,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${sub.code} • Semester 3',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            size: 20,
            color: AppColors.onSurfaceVariant,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              color: AppColors.primaryFixed,
              child: Stack(
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=200&q=80',
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.account_tree, color: AppColors.royalBlue),
                    ),
                  ),
                  Container(
                    color: AppColors.royalBlue.withOpacity(0.18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PROF. VANCE EVANS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Hall 402',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Upcoming: Midterm Review',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: const LinearProgressIndicator(
                          value: 0.72,
                          minHeight: 5,
                          backgroundColor: AppColors.surfaceContainer,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.royalBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '72% covered',
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
    );
  }

  Widget _buildSegmentedTabControls(int lectureCount, int pdfCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTabIndex = 0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTabIndex == 0
                      ? AppColors.surfaceLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTabIndex == 0
                      ? const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.graphic_eq,
                      size: 17,
                      color: _activeTabIndex == 0
                          ? AppColors.royalBlue
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI Lectures',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: _activeTabIndex == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _activeTabIndex == 0
                            ? AppColors.royalBlue
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _activeTabIndex == 0
                            ? AppColors.primaryFixed
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '$lectureCount',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _activeTabIndex == 0
                              ? AppColors.royalBlue
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTabIndex = 1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTabIndex == 1
                      ? AppColors.surfaceLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTabIndex == 1
                      ? const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 17,
                      color: _activeTabIndex == 1
                          ? AppColors.royalBlue
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PDF Notes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: _activeTabIndex == 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _activeTabIndex == 1
                            ? AppColors.royalBlue
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _activeTabIndex == 1
                            ? AppColors.secondaryFixed
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '$pdfCount',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _activeTabIndex == 1
                              ? AppColors.onSecondaryFixed
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionLaunchBanner(String subjectCode) {
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Primary: Record Class Lecture
          Expanded(
            flex: 6,
            child: InkWell(
              onTap: _navigateToRecorder,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mic,
                          color: AppColors.tertiaryFixed,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Record Class Lecture',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: const [
                              Text(
                                'Max 2h • ',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  color: AppColors.primaryFixed,
                                ),
                              ),
                              Icon(
                                Icons.auto_awesome,
                                size: 10,
                                color: AppColors.tertiaryFixed,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Gemini 1.5 Pro',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tertiaryFixed,
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
            ),
          ),
          const SizedBox(width: 10),
          // Secondary: Upload PDF
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () => _pickAndUploadPdf(subjectCode),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.upload_file,
                      size: 18,
                      color: AppColors.onSecondaryFixed,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Upload PDF',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSecondaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiLecturesSection(
      SubjectData sub, List<LectureItemData> lectures) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Text(
                  'Recent AI Recorded Lectures',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.tertiaryContainer,
                ),
              ],
            ),
            Text(
              'View All (${lectures.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.royalBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (lectures.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.graphic_eq, size: 36, color: AppColors.outline),
                  SizedBox(height: 8),
                  Text(
                    'No AI Lectures recorded yet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap "Record Class Lecture" to capture audio and generate Gemini notes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (int i = 0; i < lectures.length; i++) ...[
            if (i == 0)
              _buildProminentLectureCard(sub, lectures[0])
            else
              _buildSecondaryLectureCard(sub, lectures[i]),
            if (i < lectures.length - 1) const SizedBox(height: 14),
          ],
      ],
    );
  }

  Widget _buildProminentLectureCard(
      SubjectData sub, LectureItemData lecture) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient Accent Top Strip
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: AppColors.lectureAccentGradient,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges & Bookmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 11, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                lecture.duration,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryFixed,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.auto_awesome,
                                size: 11,
                                color: AppColors.tertiaryContainer,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Explained by Gemini ✨',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tertiaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _backupLecture(sub.code, lecture),
                          borderRadius: BorderRadius.circular(9999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: lecture.isBackedUp
                                  ? AppColors.successContainer
                                  : AppColors.secondaryFixed,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: lecture.isBackedUp
                                    ? AppColors.success.withOpacity(0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  lecture.isBackedUp
                                      ? Icons.cloud_done
                                      : Icons.cloud_upload_outlined,
                                  size: 11,
                                  color: lecture.isBackedUp
                                      ? AppColors.success
                                      : AppColors.royalBlue,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  lecture.isBackedUp
                                      ? 'Backed Up'
                                      : '☁️ Backup',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: lecture.isBackedUp
                                        ? AppColors.success
                                        : AppColors.royalBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        lecture.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        size: 16,
                        color: AppColors.royalBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  lecture.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),

                // Date & Hall
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      lecture.date,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mini Waveform & Takeaway
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Mini Waveform Bars
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildMiniWaveBar(12),
                          _buildMiniWaveBar(20),
                          _buildMiniWaveBar(8),
                          _buildMiniWaveBar(22),
                          _buildMiniWaveBar(16),
                          _buildMiniWaveBar(10),
                          _buildMiniWaveBar(18),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Key takeaway: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tertiary,
                                ),
                              ),
                              TextSpan(
                                text: lecture.keyTakeaway ?? lecture.summary,
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.onSurface,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Buttons: Listen Replay & View AI Notes
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToGeminiExplanation(lecture),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainer,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.play_circle_outline,
                            size: 16, color: AppColors.royalBlue),
                        label: const Text(
                          'Listen Replay',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToGeminiExplanation(lecture),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.auto_stories,
                            size: 16, color: Colors.white),
                        label: const Text(
                          'View AI Notes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniWaveBar(double height) {
    return Container(
      width: 3,
      height: height,
      margin: const EdgeInsets.only(right: 2.5),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
    );
  }

  Widget _buildSecondaryLectureCard(
      SubjectData sub, LectureItemData lecture) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 11, color: AppColors.onSurface),
                        const SizedBox(width: 3),
                        Text(
                          lecture.duration,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lecture.date,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Text(
                      'Explained by Gemini ✨',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _backupLecture(sub.code, lecture),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: lecture.isBackedUp
                            ? AppColors.successContainer
                            : AppColors.secondaryFixed,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: lecture.isBackedUp
                              ? AppColors.success.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            lecture.isBackedUp
                                ? Icons.cloud_done
                                : Icons.cloud_upload_outlined,
                            size: 10,
                            color: lecture.isBackedUp
                                ? AppColors.success
                                : AppColors.royalBlue,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            lecture.isBackedUp ? 'Backed Up' : '☁️ Backup',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: lecture.isBackedUp
                                  ? AppColors.success
                                  : AppColors.royalBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Icon(
                lecture.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                size: 18,
                color: lecture.isBookmarked
                    ? AppColors.royalBlue
                    : AppColors.outline,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lecture.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lecture.summary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.quiz_outlined,
                      size: 15, color: AppColors.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    lecture.flashcardsCount ?? '4 Practice Flashcards ready',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _navigateToGeminiExplanation(lecture),
                child: Row(
                  children: const [
                    Text(
                      'Open Lecture',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.royalBlue,
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

  Widget _buildCoursePdfsSection(String subjectCode, List<PdfItemData> pdfs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Course PDFs & Handouts',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '${pdfs.length} Files',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSecondaryFixed,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.sort, size: 18, color: AppColors.outline),
              splashRadius: 18,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (pdfs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined,
                      size: 36, color: AppColors.outline),
                  const SizedBox(height: 8),
                  const Text(
                    'No PDFs uploaded yet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap "+ Upload PDF" to pick slides or handouts from device.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...pdfs.map((pdf) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPdfCard(subjectCode, pdf),
              )),
      ],
    );
  }

  Widget _buildPdfCard(String subjectCode, PdfItemData pdf) {
    return InkWell(
      onTap: () async {
        if (pdf.filePath != null && pdf.filePath!.isNotEmpty) {
          try {
            final file = File(pdf.filePath!);
            if (await file.exists()) {
              await OpenFilex.open(pdf.filePath!);
              return;
            }
          } catch (_) {}
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                pdf.filePath != null
                    ? 'Viewing: ${pdf.title}\nPath: ${pdf.filePath}'
                    : 'Viewing: ${pdf.title}',
              ),
              backgroundColor: AppColors.royalBlue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: pdf.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(pdf.icon, size: 22, color: pdf.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        pdf.size,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pdf.addedDate,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pdf.tag,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pdf.tagColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _backupPdf(subjectCode, pdf),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: pdf.isBackedUp
                          ? AppColors.successContainer
                          : AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: pdf.isBackedUp
                            ? AppColors.success.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pdf.isBackedUp
                              ? Icons.cloud_done
                              : Icons.cloud_upload_outlined,
                          size: 13,
                          color: pdf.isBackedUp
                              ? AppColors.success
                              : AppColors.royalBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pdf.isBackedUp ? 'Backed Up' : '☁️ Backup',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: pdf.isBackedUp
                                ? AppColors.success
                                : AppColors.royalBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      size: 18, color: AppColors.onSurfaceVariant),
                  splashRadius: 18,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          pdf.filePath != null
                              ? 'Sharing "${pdf.title}" from ${pdf.filePath}'
                              : 'Sharing "${pdf.title}"',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined,
                      size: 18, color: AppColors.onSurfaceVariant),
                  splashRadius: 18,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          pdf.filePath != null
                              ? 'Local path verified: ${pdf.filePath}'
                              : 'Downloading "${pdf.title}"...',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeGraphWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiaryFixedDim.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.tertiary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'DSA Topic Mastery Progress',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'Gemini synchronized your 14 lectures with PDFs. Recommended next review: ',
                ),
                TextSpan(
                  text: 'Red-Black Tree vs AVL Worst-Case Comparison',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                TextSpan(text: '.'),
              ],
            ),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Topic badges stack
              Row(
                children: [
                  _buildTopicAvatar('T1', AppColors.royalBlue),
                  Transform.translate(
                    offset: const Offset(-6, 0),
                    child: _buildTopicAvatar('T2', AppColors.secondary),
                  ),
                  Transform.translate(
                    offset: const Offset(-12, 0),
                    child: _buildTopicAvatar('T3', AppColors.tertiary),
                  ),
                  Transform.translate(
                    offset: const Offset(-18, 0),
                    child: _buildTopicAvatar('+9', AppColors.surfaceHigh,
                        textColor: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening Topic Mastery Map...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      'Review Topics',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tertiaryContainer,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 15,
                      color: AppColors.tertiaryContainer,
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

  Widget _buildTopicAvatar(String text, Color color,
      {Color textColor = Colors.white}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
