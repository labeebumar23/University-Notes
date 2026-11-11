import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/models.dart';
import '../services/drive_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'recorder_screen.dart';
import 'settings_screen.dart';

class SubjectWorkspaceScreen extends StatefulWidget {
  final SubjectData? subject;

  const SubjectWorkspaceScreen({
    super.key,
    this.subject,
  });

  @override
  State<SubjectWorkspaceScreen> createState() => _SubjectWorkspaceScreenState();
}

class _SubjectWorkspaceScreenState extends State<SubjectWorkspaceScreen> {
  int _activeTabIndex = 0; // 0: Audio Lectures, 1: PDF Notes, 2: Quick Notes
  List<PdfItemData> _pdfs = [];
  bool _isLoadingPdfs = true;
  List<LectureItemData> _lectures = [];
  bool _isLoadingLectures = true;

  // Quick Notes & Code Snippets
  final TextEditingController _quickNotesController = TextEditingController();
  bool _isPreviewMarkdown = false;
  bool _isSavingNotes = false;

  // In-App Audio Player
  late final AudioPlayer _audioPlayer;
  String? _currentlyPlayingId;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  SubjectData? _currentSubject;

  @override
  void initState() {
    super.initState();
    _currentSubject = widget.subject;
    _audioPlayer = AudioPlayer();
    _initAudioPlayerListeners();
    _loadAllWorkspaceData();
  }

  void _initAudioPlayerListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() {
          _totalDuration = dur;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> _loadAllWorkspaceData() async {
    if (_currentSubject == null) {
      final subjects = await StorageService.instance.getSubjects();
      if (subjects.isNotEmpty) {
        _currentSubject = subjects.first;
      }
    }

    final code = _currentSubject?.code ?? 'General';
    await _loadPdfs(code);
    await _loadLectures(code);
    await _loadQuickNotes(code);
  }

  Future<void> _loadQuickNotes(String subjectCode) async {
    final notes = await StorageService.instance.getQuickNotes(subjectCode);
    if (mounted) {
      _quickNotesController.text = notes;
    }
  }

  Future<void> _saveQuickNotes(String subjectCode) async {
    setState(() => _isSavingNotes = true);
    await StorageService.instance.saveQuickNotes(subjectCode, _quickNotesController.text);
    if (mounted) {
      setState(() => _isSavingNotes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick Notes saved locally!'),
          backgroundColor: AppColors.royalBlue,
          duration: Duration(seconds: 1),
        ),
      );
    }
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
    final list = await StorageService.instance.getLecturesForSubject(subjectCode);
    if (mounted) {
      setState(() {
        _lectures = list;
        _isLoadingLectures = false;
      });
    }
  }

  @override
  void dispose() {
    _quickNotesController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _togglePlayPause(LectureItemData lecture) async {
    if (_currentlyPlayingId == lecture.id) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } else {
      if (lecture.audioFilePath != null && File(lecture.audioFilePath!).existsSync()) {
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(lecture.audioFilePath!));
        if (mounted) {
          setState(() {
            _currentlyPlayingId = lecture.id;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio file not found on local storage.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _seekAudio(double value) async {
    final targetSeconds = (value * _totalDuration.inSeconds).toInt();
    await _audioPlayer.seek(Duration(seconds: targetSeconds));
  }

  Future<void> _skipAudio(int seconds) async {
    final newPos = _currentPosition + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > _totalDuration ? _totalDuration : newPos);
    await _audioPlayer.seek(clamped);
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 1) {
      _navigateToRecorder();
    } else if (index == 2) {
      // Already on workspace
      return;
    } else if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
    }
  }

  Future<void> _navigateToRecorder() async {
    final sub = _currentSubject;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecorderScreen(subject: sub),
      ),
    );
    final subCode = sub?.code ?? 'General';
    await _loadLectures(subCode);
    await _loadPdfs(subCode);
  }

  Future<void> _backupPdf(String subjectCode, PdfItemData pdf) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Uploading "${pdf.title}" to Google Drive...'),
        backgroundColor: AppColors.royalBlue,
        duration: const Duration(seconds: 1),
      ),
    );

    final result = await DriveService.instance.uploadPdf(pdf);

    if (result.success) {
      final updated = pdf.copyWith(
        isBackedUp: true,
        driveFileId: result.fileId,
      );
      await StorageService.instance.updatePdfInSubject(subjectCode, updated);
      await _loadPdfs(subjectCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Uploaded to Google Drive!'),
            backgroundColor: AppColors.royalBlue,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Drive upload failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _backupLecture(String subjectCode, LectureItemData lecture) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Uploading "${lecture.title}" to Google Drive...'),
        backgroundColor: AppColors.royalBlue,
        duration: const Duration(seconds: 1),
      ),
    );

    final result = await DriveService.instance.uploadLectureAudio(lecture);

    if (result.success) {
      final updated = lecture.copyWith(
        isBackedUp: true,
        driveFileId: result.fileId,
      );
      await StorageService.instance.updateLectureInSubject(subjectCode, updated);
      await _loadLectures(subjectCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Lecture audio backed up!'),
            backgroundColor: AppColors.royalBlue,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Upload failed.'),
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
        final appDocDir = await getApplicationDocumentsDirectory();
        final pdfsDir = Directory('${appDocDir.path}/pdfs');
        if (!pdfsDir.existsSync()) {
          await pdfsDir.create(recursive: true);
        }

        for (final file in files) {
          final fileName = file.name;
          final sourcePath = file.path;
          final safeName = '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(RegExp(r'[^\w\s\.-]'), '_')}';
          final internalDestinationPath = '${pdfsDir.path}/$safeName';

          // Permanently copy PDF into the app's internal documents directory for 100% offline access
          if (sourcePath != null && File(sourcePath).existsSync()) {
            await File(sourcePath).copy(internalDestinationPath);
          }

          final localFile = File(internalDestinationPath);
          final fileSizeInBytes = localFile.existsSync()
              ? localFile.lengthSync()
              : (sourcePath != null && File(sourcePath).existsSync()
                  ? File(sourcePath).lengthSync()
                  : 0);
          final sizeString = _formatFileSize(fileSizeInBytes);

          final newPdf = PdfItemData(
            title: fileName,
            size: sizeString,
            addedDate: 'Added today',
            tag: 'Offline PDF',
            tagColor: AppColors.royalBlue,
            icon: Icons.picture_as_pdf,
            iconBg: AppColors.errorContainer,
            iconColor: AppColors.error,
            filePath: internalDestinationPath,
          );

          await StorageService.instance.addPdfToSubject(subjectCode, newPdf);
          addedCount++;
        }

        await _loadPdfs(subjectCode);

        setState(() {
          _activeTabIndex = 1;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                addedCount == 1
                    ? 'Saved "${files.first.name}" offline!'
                    : 'Saved $addedCount PDFs offline!',
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
            content: Text('File picker note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeletePdfConfirm(PdfItemData pdf) {
    final subCode = _currentSubject?.code ?? 'General';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${pdf.title}"?'),
        content: const Text(
          'This will permanently delete this PDF file from your device storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.instance.deletePdfFromSubject(subCode, pdf.title);
              await _loadPdfs(subCode);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${pdf.title}" from storage'),
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

  void _showDeleteLectureConfirm(LectureItemData lecture) {
    final subCode = _currentSubject?.code ?? 'General';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${lecture.title}"?'),
        content: const Text(
          'This will permanently delete this audio recording (.m4a) from your device storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentlyPlayingId == lecture.id) {
                await _audioPlayer.stop();
                setState(() => _currentlyPlayingId = null);
              }
              await StorageService.instance.deleteLectureFromSubject(subCode, lecture.id);
              await _loadLectures(subCode);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${lecture.title}" from storage'),
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

  void _showDeleteSubjectConfirm() {
    final sub = _currentSubject;
    if (sub == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${sub.code}?'),
        content: Text(
          'This will permanently delete ${sub.name} and all its ${_pdfs.length} PDFs and ${_lectures.length} audio recordings from device storage.',
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
              if (mounted) {
                Navigator.pop(context); // Return to subjects screen
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

  void _showEditSubjectDialog() {
    final sub = _currentSubject;
    if (sub == null) return;
    final nameCtrl = TextEditingController(text: sub.name);
    final profCtrl = TextEditingController(text: sub.professor);
    final scheduleCtrl = TextEditingController(text: sub.schedule);

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
                Text(
                  'Edit ${sub.code}',
                  style: const TextStyle(
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
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Course Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: profCtrl,
              decoration: const InputDecoration(labelText: 'Professor / Instructor'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scheduleCtrl,
              decoration: const InputDecoration(labelText: 'Class Schedule'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updated = sub.copyWith(
                    name: nameCtrl.text.trim().isEmpty ? sub.name : nameCtrl.text.trim(),
                    professor: profCtrl.text.trim().isEmpty ? sub.professor : profCtrl.text.trim(),
                    schedule: scheduleCtrl.text.trim(),
                  );
                  await StorageService.instance.updateSubject(updated);
                  if (mounted) {
                    setState(() {
                      _currentSubject = updated;
                    });
                    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final sub = _currentSubject;
    final subCode = sub?.code ?? 'General';

    LectureItemData? activePlayingLecture;
    if (_currentlyPlayingId != null) {
      try {
        activePlayingLecture = _lectures.firstWhere((l) => l.id == _currentlyPlayingId);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'UniNotes',
        subtitle: sub != null ? '${sub.code} Workspace' : 'Workspace',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, activePlayingLecture != null ? 180 : 96),
            children: [
              // Course Snapshot Hero Card
              _buildCourseHeroCard(sub),
              const SizedBox(height: 16),

              // Segmented Dual Tab Controls
              _buildSegmentedTabControls(_lectures.length, _pdfs.length),
              const SizedBox(height: 16),

              // Action Launch Banner
              if (_activeTabIndex != 2) ...[
                _buildActionLaunchBanner(subCode),
                const SizedBox(height: 18),
              ],

              // Active Tab Content
              if (_activeTabIndex == 0)
                _buildAudioLecturesSection(subCode, _lectures)
              else if (_activeTabIndex == 1)
                _buildPdfNotesSection(subCode, _pdfs)
              else
                _buildQuickNotesSection(subCode),
            ],
          ),

          // In-App Mini Audio Player (Floating Bottom Bar)
          if (activePlayingLecture != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 80,
              child: _buildMiniAudioPlayer(activePlayingLecture),
            ),
        ],
      ),
      bottomNavigationBar: UniBottomNavBar(
        currentIndex: 2,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildCourseHeroCard(SubjectData? sub) {
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                sub?.code.length != null && sub!.code.length > 4
                    ? sub.code.substring(0, 4)
                    : (sub?.code ?? 'CRS'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.royalBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub?.name ?? 'Course Workspace',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub?.professor.isNotEmpty == true
                      ? sub!.professor
                      : 'Course Instructor',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${_lectures.length} Audio Lectures • ${_pdfs.length} PDFs',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.royalBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.onSurfaceVariant),
            tooltip: 'Course options',
            onSelected: (value) {
              if (value == 'edit') {
                _showEditSubjectDialog();
              } else if (value == 'delete') {
                _showDeleteSubjectConfirm();
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
          // Audio Lectures Tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTabIndex = 0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                      size: 16,
                      color: _activeTabIndex == 0
                          ? AppColors.royalBlue
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Audio',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: _activeTabIndex == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _activeTabIndex == 0
                            ? AppColors.royalBlue
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
          const SizedBox(width: 3),

          // PDF Notes Tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTabIndex = 1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                      size: 16,
                      color: _activeTabIndex == 1
                          ? AppColors.royalBlue
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PDFs',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: _activeTabIndex == 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _activeTabIndex == 1
                            ? AppColors.royalBlue
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _activeTabIndex == 1
                            ? AppColors.primaryFixed
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
          const SizedBox(width: 3),

          // Quick Notes & Code Tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTabIndex = 2),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTabIndex == 2
                      ? AppColors.surfaceLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTabIndex == 2
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
                      Icons.code_outlined,
                      size: 16,
                      color: _activeTabIndex == 2
                          ? AppColors.royalBlue
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: _activeTabIndex == 2
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _activeTabIndex == 2
                            ? AppColors.royalBlue
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _activeTabIndex == 2
                            ? const Color(0xFFFEF3C7)
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'MD',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _activeTabIndex == 2
                              ? const Color(0xFFB45309)
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

  void _insertMarkdownSnippet(String prefix, [String suffix = '']) {
    final text = _quickNotesController.text;
    final selection = _quickNotesController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final selectedText = text.substring(start, end);
    final replacement = '$prefix$selectedText$suffix';
    final newText = text.replaceRange(start, end, replacement);
    _quickNotesController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + prefix.length + selectedText.length + suffix.length,
      ),
    );
  }

  Widget _buildSnippetButton(String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNotesSection(String subjectCode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note_alt_outlined, size: 18, color: AppColors.royalBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Notes & Code ($subjectCode)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _isPreviewMarkdown = !_isPreviewMarkdown),
                        icon: Icon(
                          _isPreviewMarkdown ? Icons.edit_outlined : Icons.visibility_outlined,
                          size: 16,
                          color: AppColors.royalBlue,
                        ),
                        label: Text(
                          _isPreviewMarkdown ? 'Edit' : 'Preview',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.royalBlue),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: _isSavingNotes ? null : () => _saveQuickNotes(subjectCode),
                        icon: _isSavingNotes
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined, size: 16),
                        label: Text(_isSavingNotes ? 'Saving...' : 'Save', style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!_isPreviewMarkdown) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSnippetButton('H1', () => _insertMarkdownSnippet('# ')),
                      _buildSnippetButton('H2', () => _insertMarkdownSnippet('## ')),
                      _buildSnippetButton('Bold', () => _insertMarkdownSnippet('**', '**')),
                      _buildSnippetButton('Italic', () => _insertMarkdownSnippet('*', '*')),
                      _buildSnippetButton('Code', () => _insertMarkdownSnippet('`', '`')),
                      _buildSnippetButton('Code Block', () => _insertMarkdownSnippet('```dart\n// Your code here\n', '\n```\n')),
                      _buildSnippetButton('List', () => _insertMarkdownSnippet('- ')),
                      _buildSnippetButton('Quote', () => _insertMarkdownSnippet('> ')),
                      _buildSnippetButton('Formula', () => _insertMarkdownSnippet(r'$$ ', r' $$')),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Editor or Markdown Preview
        if (_isPreviewMarkdown)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 280),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: _quickNotesController.text.trim().isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No notes written yet.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Edit" to type Markdown notes or code snippets.',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : MarkdownBody(
                    data: _quickNotesController.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        height: 1.5,
                      ),
                      code: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                    ),
                  ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _quickNotesController,
              maxLines: null,
              minLines: 12,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                height: 1.45,
              ),
              decoration: InputDecoration(
                hintText: '# $subjectCode Lecture Notes\n\n- Key Concept 1\n- Formula: V = I * R\n\n```python\ndef calculate_resistance(voltage, current):\n    return voltage / current\n```',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),

        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 4),
                Text(
                  '100% Offline Local Storage',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            Text(
              '${_quickNotesController.text.length} chars',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
  }

  Widget _buildActionLaunchBanner(String subjectCode) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _navigateToRecorder,
            icon: const Icon(Icons.mic, size: 18),
            label: const Text('Record Lecture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickAndUploadPdf(subjectCode),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.royalBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioLecturesSection(String subjectCode, List<LectureItemData> lectures) {
    if (lectures.isEmpty) {
      return _buildEmptyLecturesState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lectures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lec = lectures[index];
        final isCurrentlyPlaying = _currentlyPlayingId == lec.id && _isPlaying;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentlyPlaying ? AppColors.royalBlue : AppColors.outlineVariant,
              width: isCurrentlyPlaying ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x061E293B),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Play / Pause Circle Button
                  IconButton.filled(
                    onPressed: () => _togglePlayPause(lec),
                    icon: Icon(
                      isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isCurrentlyPlaying
                          ? AppColors.tertiary
                          : AppColors.royalBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lec.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              lec.date,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lec.duration,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.royalBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Drive Backup Button
                  IconButton(
                    icon: Icon(
                      lec.isBackedUp ? Icons.cloud_done : Icons.cloud_upload_outlined,
                      size: 20,
                      color: lec.isBackedUp ? AppColors.success : AppColors.onSurfaceVariant,
                    ),
                    tooltip: lec.isBackedUp ? 'Backed up to Google Drive' : 'Backup to Drive',
                    onPressed: () => _backupLecture(subjectCode, lec),
                  ),

                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    tooltip: 'Delete recording',
                    onPressed: () => _showDeleteLectureConfirm(lec),
                  ),
                ],
              ),
              if (lec.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  lec.summary,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyLecturesState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic_none_outlined,
              size: 28,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Audio Lectures Recorded Yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Record live professor lectures in class. All recordings are saved directly on your device storage with instant in-app playback.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _navigateToRecorder,
            icon: const Icon(Icons.mic, size: 18),
            label: const Text('Record First Lecture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfNotesSection(String subjectCode, List<PdfItemData> pdfs) {
    if (pdfs.isEmpty) {
      return _buildEmptyPdfsState(subjectCode);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pdfs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        return InkWell(
          onTap: () {
            if (pdf.filePath != null && File(pdf.filePath!).existsSync()) {
              OpenFilex.open(pdf.filePath!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File not found on local storage.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.error,
                    size: 20,
                  ),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
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
                          const SizedBox(width: 8),
                          Text(
                            pdf.addedDate,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    pdf.isBackedUp ? Icons.cloud_done : Icons.cloud_upload_outlined,
                    size: 20,
                    color: pdf.isBackedUp ? AppColors.success : AppColors.onSurfaceVariant,
                  ),
                  tooltip: pdf.isBackedUp ? 'Backed up' : 'Backup to Drive',
                  onPressed: () => _backupPdf(subjectCode, pdf),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  tooltip: 'Delete PDF',
                  onPressed: () => _showDeletePdfConfirm(pdf),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyPdfsState(String subjectCode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 28,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Course PDFs Uploaded Yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select and upload course syllabi, slides, past papers, or textbook chapters from your device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _pickAndUploadPdf(subjectCode),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload PDF Notes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAudioPlayer(LectureItemData lecture) {
    final progress = _totalDuration.inSeconds > 0
        ? (_currentPosition.inSeconds / _totalDuration.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.royalBlue.withOpacity(0.3), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: AppColors.royalBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lecture.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () async {
                  await _audioPlayer.stop();
                  setState(() => _currentlyPlayingId = null);
                },
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: AppColors.royalBlue,
              inactiveTrackColor: AppColors.surfaceContainer,
              thumbColor: AppColors.royalBlue,
            ),
            child: Slider(
              value: progress,
              onChanged: _seekAudio,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, size: 22, color: AppColors.royalBlue),
                    onPressed: () => _skipAudio(-10),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      size: 36,
                      color: AppColors.royalBlue,
                    ),
                    onPressed: () => _togglePlayPause(lecture),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, size: 22, color: AppColors.royalBlue),
                    onPressed: () => _skipAudio(10),
                  ),
                ],
              ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
