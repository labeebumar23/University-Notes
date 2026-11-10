import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import 'gemini_explanation_screen.dart';

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
  int _seconds = 6141; // 01:42:21 starting time or 0
  bool _isPaused = false;
  bool _isMuted = false;
  int _bookmarkCount = 4;
  int _whiteboardCount = 2;
  Timer? _timer;
  Timer? _transcriptTimer;

  // Real audio recording
  late final AudioRecorder _audioRecorder;
  String? _recordedFilePath;
  bool _isRecordingRealAudio = false;
  bool _isAnalyzingWithGemini = false;

  int _transcriptIndex = 0;
  final List<String> _transcripts = [
    '"...and when the balance factor of a tree node becomes strictly greater than one, we execute a right-rotation on the left child before recomputing tree height..."',
    '"...notice how the height of the left subtree is reduced by exactly one unit, maintaining BST invariants..."',
    '"...for the upcoming Midterm 2, remember that double rotations occur when signs of balance factors differ..."',
    '"...let\'s trace through an insertion of key 42 into this unbalanced AVL tree on the blackboard..."',
  ];

  late AnimationController _waveAnimController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _startTimer();
    _initAndStartAudioRecording();

    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  Future<void> _initAndStartAudioRecording() async {
    try {
      var hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        final status = await Permission.microphone.request();
        hasPermission = status.isGranted;
      }

      if (hasPermission) {
        final dir = await getApplicationDocumentsDirectory();
        final subCode = widget.subject?.code ?? 'CS202';
        final fileName =
            'lecture_${subCode}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordedFilePath = '${dir.path}/$fileName';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordedFilePath!,
        );

        if (mounted) {
          setState(() {
            _isRecordingRealAudio = true;
          });
        }
      }
    } catch (e) {
      // Graceful fallback to simulated recording if microphone is unavailable
      debugPrint('Audio recording note: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _seconds++;
        });
      }
    });

    _transcriptTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isPaused) {
        setState(() {
          _transcriptIndex = (_transcriptIndex + 1) % _transcripts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _transcriptTimer?.cancel();
    _waveAnimController.dispose();
    if (_isRecordingRealAudio) {
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
      if (_isRecordingRealAudio) {
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

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMuted ? 'Microphone muted' : 'Microphone active'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addBookmark() {
    setState(() {
      _bookmarkCount++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Timestamp ${_formatTime(_seconds)} bookmarked for Gemini summary!'),
        backgroundColor: AppColors.tertiaryContainer,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _takeWhiteboardPhoto() {
    setState(() {
      _whiteboardCount++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Whiteboard snapshot captured! OCR will anchor to current timestamp.'),
        backgroundColor: AppColors.royalBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _finishAndExplain() async {
    setState(() {
      _isAnalyzingWithGemini = true;
    });

    String? finalPath = _recordedFilePath;
    try {
      if (_isRecordingRealAudio) {
        finalPath = await _audioRecorder.stop();
      }
    } catch (_) {}

    final currentSub = widget.subject ?? MockData.subjects[3]; // CS202 by default
    final existingLectures =
        await StorageService.instance.getLecturesForSubject(currentSub.code);
    final lectureNumber = 'Lecture ${existingLectures.length + 1}';
    final lectureTitle =
        '$lectureNumber: ${currentSub.name} Synthesis & Formulas';

    // Call Gemini Service for structured explanation
    final explanation = await GeminiService.generateLectureExplanation(
      subjectName: currentSub.name,
      lectureTitle: lectureTitle,
      audioFilePath: finalPath,
    );

    // Create the persistent Lecture object
    final newLecture = LectureItemData(
      id: 'lec-${DateTime.now().millisecondsSinceEpoch}',
      lectureNumber: lectureNumber,
      title: lectureTitle,
      duration: _formatTime(_seconds),
      date: 'Today, 10:15 AM',
      summary: explanation.summary,
      keyTakeaway: explanation.summary,
      isBookmarked: true,
      flashcardsCount: '4 Practice Flashcards ready',
      audioFilePath: finalPath,
      geminiResponseJson: jsonEncode(explanation.toJson()),
    );

    // Save permanently under this subject
    await StorageService.instance.addLectureToSubject(currentSub.code, newLecture);

    if (mounted) {
      setState(() {
        _isAnalyzingWithGemini = false;
      });

      // Navigate to Gemini AI Explanation Screen with real results & audio
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GeminiExplanationScreen(
            subject: currentSub,
            lecture: newLecture,
            explanationResult: explanation,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subject ?? MockData.subjects[3];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Live Lecture Recorder',
        subtitle: null,
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Top Session Context Bar
                _buildSessionContextBar(sub),
                const SizedBox(height: 14),

                // Studio Live Recording Hub Card
                _buildRecordingHubCard(),
                const SizedBox(height: 14),

                // In-Lecture Studio Tools (Bookmark & Whiteboard)
                _buildStudioTools(),
                const SizedBox(height: 14),

                // Whiteboard Slides & Topic Tags Strip
                _buildIndexedTopicsStrip(),
                const SizedBox(height: 18),

                // Bottom Control Deck & Primary Gemini Action
                _buildControlDeck(),
              ],
            ),
          ),

          // Gemini Processing Loading Overlay
          if (_isAnalyzingWithGemini) _buildAnalyzingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Container(
      color: AppColors.onSurface.withOpacity(0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.tertiaryContainer,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gemini 1.5 Pro Analyzing...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Synthesizing 2-hour lecture audio, extracting mathematical invariants, and generating exam prep Q&A.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.royalBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionContextBar(SubjectData sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.keyboard_arrow_down,
              size: 22,
              color: AppColors.onSurface,
            ),
          ),
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                '${sub.code}: ${sub.name}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSecondaryFixed,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Lecture Hall B3',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.royalBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isMuted ? Icons.mic_off : Icons.mic,
                  size: 13,
                  color: _isMuted ? AppColors.error : AppColors.tertiary,
                ),
                const SizedBox(width: 3),
                Text(
                  _isMuted ? 'Muted' : 'Mic Active',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isMuted ? AppColors.error : AppColors.tertiary,
                  ),
                ),
              ],
            ),
          ],
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

  Widget _buildRecordingHubCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E293B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Golden Halo Ambient Glow in Top-Right
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiaryFixed.withOpacity(0.4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Battery & System Resource Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _isPaused ? AppColors.outline : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isPaused ? 'PAUSED' : 'REC LIVE',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _isPaused ? AppColors.outline : AppColors.onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.sd_card_outlined,
                            size: 14, color: AppColors.onSurfaceVariant),
                        SizedBox(width: 4),
                        Text(
                          '48MB / 12GB Free',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.battery_5_bar,
                            size: 15, color: AppColors.onSurfaceVariant),
                        SizedBox(width: 3),
                        Text(
                          '84%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Large High-Visibility Timer Display
                Text(
                  _formatTime(_seconds),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.royalBlue,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Max Duration ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Text(
                      '/ 02:00:00',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        '17m left',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Animated Audio Waveform Visualizer
                _buildAnimatedWaveform(),
                const SizedBox(height: 16),

                // Live Speech Transcript Ticker
                _buildLiveTranscriptBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedWaveform() {
    final baseHeights = [
      14.0, 22.0, 38.0, 26.0, 48.0, 56.0, 32.0, 16.0,
      40.0, 62.0, 44.0, 52.0, 28.0, 18.0, 46.0, 58.0,
      30.0, 42.0, 24.0, 54.0, 36.0, 18.0, 32.0, 16.0,
    ];

    return AnimatedBuilder(
      animation: _waveAnimController,
      builder: (context, child) {
        return SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(baseHeights.length, (i) {
              final isGold = i % 2 == 1;
              final factor = _isPaused
                  ? 0.3
                  : (0.4 +
                      0.6 *
                          ((i.isEven
                                  ? _waveAnimController.value
                                  : (1.0 - _waveAnimController.value)) *
                              0.8 +
                              0.2));
              final h = baseHeights[i] * factor;

              return Container(
                width: 5,
                height: h.clamp(6.0, 64.0),
                margin: const EdgeInsets.symmetric(horizontal: 2.2),
                decoration: BoxDecoration(
                  color: isGold
                      ? AppColors.tertiary
                      : AppColors.royalBlue,
                  borderRadius: BorderRadius.circular(9999),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLiveTranscriptBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome,
                        size: 12, color: AppColors.tertiaryContainer),
                    SizedBox(width: 4),
                    Text(
                      'Gemini Live Indexing',
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
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.royalBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Prof. Vance',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _transcripts[_transcriptIndex],
              key: ValueKey<int>(_transcriptIndex),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.onSurface,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioTools() {
    return Row(
      children: [
        // Bookmark Key Moment
        Expanded(
          child: InkWell(
            onTap: _addBookmark,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bookmark_add,
                          color: AppColors.tertiaryContainer,
                          size: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixedDim,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          '$_bookmarkCount Saved',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onTertiaryFixed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bookmark',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Flags: 14m, 38m, 1h02m...',
                    style: TextStyle(
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
          ),
        ),
        const SizedBox(width: 12),
        // Whiteboard Snapshot
        Expanded(
          child: InkWell(
            onTap: _takeWhiteboardPhoto,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryFixed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.photo_camera,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          '$_whiteboardCount Shots',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Whiteboard',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Snap slide or diagram',
                    style: TextStyle(
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
          ),
        ),
      ],
    );
  }

  Widget _buildIndexedTopicsStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_stories, size: 15, color: AppColors.royalBlue),
                  SizedBox(width: 6),
                  Text(
                    'Indexed Lecture Topics',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const Text(
                'Real-time sync',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildTopicTag('🌲 AVL Self-Balancing'),
                const SizedBox(width: 8),
                _buildTopicTag('🔄 Left/Right Rotations'),
                const SizedBox(width: 8),
                _buildTopicTag('⏱️ O(log n) Proof'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
    );
  }

  Widget _buildControlDeck() {
    return Column(
      children: [
        // Primary CTA Button: Finish & Explain with Gemini
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _finishAndExplain,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.royalBlue.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.auto_awesome,
                    size: 20, color: AppColors.tertiaryFixed),
                SizedBox(width: 8),
                Text(
                  'Finish & Explain with Gemini',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Secondary Control Row (Pause REC & Mute Mic)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _togglePause,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isPaused
                        ? AppColors.secondaryFixed
                        : AppColors.surfaceHigh,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause_circle_outline,
                    size: 18,
                    color: _isPaused
                        ? AppColors.royalBlue
                        : AppColors.onSurface,
                  ),
                  label: Text(
                    _isPaused ? 'Resume REC' : 'Pause REC',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isPaused
                          ? AppColors.royalBlue
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _toggleMute,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isMuted
                        ? AppColors.errorContainer
                        : AppColors.surfaceHigh,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _isMuted ? Icons.mic : Icons.mic_off,
                    size: 18,
                    color: _isMuted ? AppColors.error : AppColors.onSurface,
                  ),
                  label: Text(
                    _isMuted ? 'Unmute Mic' : 'Mute Mic',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isMuted ? AppColors.error : AppColors.onSurface,
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
