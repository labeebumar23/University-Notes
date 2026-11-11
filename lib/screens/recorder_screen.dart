import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';

class RecorderScreen extends StatefulWidget {
  final SubjectData? subject;

  const RecorderScreen({
    super.key,
    this.subject,
  });

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen>
    with SingleTickerProviderStateMixin {
  int _seconds = 0;
  bool _isPaused = false;
  Timer? _timer;

  // Real audio recording
  late final AudioRecorder _audioRecorder;
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _permissionDenied = false;

  late AnimationController _waveAnimController;

  SubjectData? _currentSubject;
  List<SubjectData> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _currentSubject = widget.subject;

    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _loadSubjectsAndInitRecorder();
  }

  Future<void> _loadSubjectsAndInitRecorder() async {
    final list = await StorageService.instance.getSubjects();
    if (mounted) {
      setState(() {
        _availableSubjects = list;
        if (_currentSubject == null && list.isNotEmpty) {
          _currentSubject = list.first;
        }
      });
    }

    await _startRealRecording();
  }

  Future<void> _startRealRecording() async {
    try {
      var hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        final status = await Permission.microphone.request();
        hasPermission = status.isGranted;
      }

      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _permissionDenied = true;
          });
        }
        return;
      }

      final docDir = await getApplicationDocumentsDirectory();
      final lecturesDir = Directory('${docDir.path}/lectures');
      if (!lecturesDir.existsSync()) {
        await lecturesDir.create(recursive: true);
      }

      final subCode = _currentSubject?.code ?? 'General';
      final fileName = 'lecture_${subCode}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordedFilePath = '${lecturesDir.path}/$fileName';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 48000, // 48 kbps highly compressed speech audio to save local storage
          sampleRate: 32000, // 32 kHz optimized for speech clarity
          numChannels: 1, // Mono channel saves 50% storage on voice lectures
        ),
        path: _recordedFilePath!,
      );

      _startTimer();

      if (mounted) {
        setState(() {
          _isRecording = true;
          _permissionDenied = false;
        });
      }
    } catch (e) {
      debugPrint('Real audio recorder start note: $e');
      _startTimer();
      if (mounted) {
        setState(() {
          _isRecording = true;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveAnimController.dispose();
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _togglePause() async {
    setState(() {
      _isPaused = !_isPaused;
    });

    try {
      if (_isRecording) {
        if (_isPaused) {
          await _audioRecorder.pause();
        } else {
          await _audioRecorder.resume();
        }
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPaused ? 'Recording paused' : 'Recording resumed'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _discardRecording() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Recording?'),
        content: const Text(
          'Are you sure you want to discard this recording? The recorded audio will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Recording'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (_isRecording) {
                  await _audioRecorder.stop();
                }
                if (_recordedFilePath != null) {
                  final f = File(_recordedFilePath!);
                  if (f.existsSync()) f.deleteSync();
                }
              } catch (_) {}
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishAndSave() async {
    final sub = _currentSubject;
    final subCode = sub?.code ?? 'General';
    final existingLectures =
        await StorageService.instance.getLecturesForSubject(subCode);
    final nextNumber = existingLectures.length + 1;

    final titleController = TextEditingController(
      text: 'Lecture $nextNumber: ${sub?.name ?? "Class Lecture"}',
    );
    final noteController = TextEditingController();

    if (!mounted) return;

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
                  'Save Audio Lecture',
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
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subCode,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.royalBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${_formatTime(_seconds)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Lecture Title',
                hintText: 'e.g. Lecture 1: AVL Trees & Binary Search',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Quick Topic / Notes (Optional)',
                hintText: 'e.g. Discussed midterm format and tree balancing',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim().isEmpty
                      ? 'Lecture $nextNumber'
                      : titleController.text.trim();
                  final note = noteController.text.trim();

                  String? finalPath = _recordedFilePath;
                  try {
                    if (_isRecording) {
                      finalPath = await _audioRecorder.stop();
                    }
                  } catch (_) {}

                  final newLecture = LectureItemData(
                    id: 'lec-${DateTime.now().millisecondsSinceEpoch}',
                    lectureNumber: 'Lecture $nextNumber',
                    title: title,
                    duration: _formatTime(_seconds),
                    date: 'Today, ${TimeOfDay.now().format(context)}',
                    summary: note.isNotEmpty ? note : 'Class audio lecture recording (${_formatTime(_seconds)})',
                    keyTakeaway: note.isNotEmpty ? note : 'Audio recorded in $subCode',
                    isBookmarked: false,
                    audioFilePath: finalPath ?? _recordedFilePath,
                  );

                  await StorageService.instance.addLectureToSubject(subCode, newLecture);

                  if (mounted) {
                    Navigator.pop(context); // close bottom sheet
                    Navigator.pop(context, true); // return to workspace / previous screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Audio lecture "$title" saved!'),
                        backgroundColor: AppColors.royalBlue,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Save Audio Lecture'),
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
  }

  @override
  Widget build(BuildContext context) {
    final sub = _currentSubject;
    final subName = sub != null ? '${sub.code} - ${sub.name}' : 'Live Audio Recording';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Voice Recorder',
        subtitle: subName,
        showBack: true,
        onBack: _discardRecording,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Course selection bar if no specific subject was passed
            if (_availableSubjects.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 18, color: AppColors.royalBlue),
                    const SizedBox(width: 8),
                    const Text(
                      'Course:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SubjectData>(
                          value: _currentSubject,
                          isExpanded: true,
                          items: _availableSubjects.map((s) {
                            return DropdownMenuItem<SubjectData>(
                              value: s,
                              child: Text(
                                '${s.code} - ${s.name}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _currentSubject = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Microphone Permission Warning Banner
            if (_permissionDenied) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_off, color: AppColors.error),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Microphone permission is required to record class audio.',
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                    TextButton(
                      onPressed: _startRealRecording,
                      child: const Text('Allow'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Live Recording Studio Card
            _buildRecordingCard(),
            const SizedBox(height: 20),

            // Control Buttons Deck
            _buildControlDeck(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061E293B),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          // Live Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isPaused ? AppColors.surfaceHigh : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isPaused ? AppColors.onSurfaceVariant : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isPaused ? 'PAUSED' : 'LIVE RECORDING',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isPaused ? AppColors.onSurfaceVariant : AppColors.error,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Big Live Timer Display
          Text(
            _formatTime(_seconds),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Speech-Optimized 48 kbps AAC Mono • Low Storage Usage',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(height: 28),

          // Animated Waveforms
          SizedBox(
            height: 64,
            child: AnimatedBuilder(
              animation: _waveAnimController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(24, (i) {
                    final multiplier = _isPaused
                        ? 0.15
                        : (0.3 + 0.7 * (((i * 7 + (_waveAnimController.value * 20)) % 10) / 10));
                    return Container(
                      width: 4,
                      height: 50 * multiplier,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: _isPaused
                            ? AppColors.surfaceHigh
                            : AppColors.royalBlue.withOpacity(0.4 + 0.6 * multiplier),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlDeck() {
    return Column(
      children: [
        // Primary CTA Button: Finish & Save
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _seconds > 0 ? _finishAndSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text(
              'Finish & Save Audio Lecture',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary Row (Pause & Discard)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    size: 18,
                  ),
                  label: Text(_isPaused ? 'Resume' : 'Pause'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _discardRecording,
                  icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                  label: const Text('Discard', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorContainer),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
