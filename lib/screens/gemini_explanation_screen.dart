import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/gemini_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';

class GeminiExplanationScreen extends StatefulWidget {
  final SubjectData? subject;
  final LectureItemData? lecture;
  final GeminiExplanationResult? explanationResult;

  const GeminiExplanationScreen({
    super.key,
    this.subject,
    this.lecture,
    this.explanationResult,
  });

  @override
  State<GeminiExplanationScreen> createState() =>
      _GeminiExplanationScreenState();
}

class _GeminiExplanationScreenState extends State<GeminiExplanationScreen> {
  // Real Audio Player
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _hasAudioFile = false;
  Duration _duration = const Duration(hours: 1, minutes: 54, seconds: 10);
  Duration _position = const Duration(hours: 1, minutes: 14, seconds: 20);

  String _selectedSpeed = '1.5x';
  String _currentTime = '01:14:20';
  String _totalTime = '01:54:10';
  double _scrubberProgress = 0.65;
  bool _isBookmarked = false;
  bool _isSavedToSubject = true;
  bool _isExporting = false;
  String _exportButtonText = 'Export as PDF';

  late GeminiExplanationResult _data;
  final List<bool> _expandedQuestions = [true, false, false];

  @override
  void initState() {
    super.initState();
    _initExplanationData();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  void _initExplanationData() {
    if (widget.explanationResult != null) {
      _data = widget.explanationResult!;
    } else if (widget.lecture?.geminiResponseJson != null) {
      try {
        final decoded = jsonDecode(widget.lecture!.geminiResponseJson!)
            as Map<String, dynamic>;
        _data = GeminiExplanationResult.fromJson(decoded);
      } catch (_) {
        _data = GeminiService.generateDefaultAcademicExplanation();
      }
    } else {
      _data = GeminiService.generateDefaultAcademicExplanation();
    }
  }

  Future<void> _initAudioPlayer() async {
    final filePath = widget.lecture?.audioFilePath;
    if (filePath != null && filePath.isNotEmpty && File(filePath).existsSync()) {
      _hasAudioFile = true;
      try {
        await _audioPlayer.setSource(DeviceFileSource(filePath));
      } catch (e) {
        debugPrint('Audio source loading note: $e');
      }
    }

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _duration = d;
          _totalTime = _formatDuration(d);
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
          _currentTime = _formatDuration(p);
          if (_duration.inSeconds > 0) {
            _scrubberProgress =
                (_position.inSeconds / _duration.inSeconds).clamp(0.0, 1.0);
          }
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = (state == PlayerState.playing);
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Duration _parseTimestamp(String timestamp) {
    try {
      final parts = timestamp.split(':').map((e) => int.parse(e)).toList();
      if (parts.length == 3) {
        return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
      } else if (parts.length == 2) {
        return Duration(minutes: parts[0], seconds: parts[1]);
      }
    } catch (_) {}
    return const Duration(minutes: 42, seconds: 15);
  }

  Future<void> _togglePlayPause() async {
    if (_hasAudioFile) {
      try {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.resume();
        }
      } catch (_) {}
    } else {
      // Demo simulated playback toggle
      setState(() => _isPlaying = !_isPlaying);
    }
  }

  Future<void> _seekToDuration(Duration target) async {
    if (_hasAudioFile) {
      try {
        await _audioPlayer.seek(target);
      } catch (_) {}
    } else {
      setState(() {
        _position = target;
        _currentTime = _formatDuration(target);
        if (_duration.inSeconds > 0) {
          _scrubberProgress =
              (_position.inSeconds / _duration.inSeconds).clamp(0.0, 1.0);
        }
        _isPlaying = true;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio jumped to ${_formatDuration(target)}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _setSpeed(String speed) async {
    setState(() => _selectedSpeed = speed);
    double rate = 1.0;
    if (speed == '1.25x') rate = 1.25;
    if (speed == '1.5x') rate = 1.5;
    if (speed == '2x') rate = 2.0;

    if (_hasAudioFile) {
      try {
        await _audioPlayer.setPlaybackRate(rate);
      } catch (_) {}
    }
  }

  void _exportPdf() {
    setState(() {
      _isExporting = true;
      _exportButtonText = 'Compiling...';
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportButtonText = 'Downloaded!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Saved "${widget.lecture?.title ?? "Lecture 14"} - Gemini Notes.pdf" to Downloads!'),
            backgroundColor: AppColors.royalBlue,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _exportButtonText = 'Export as PDF';
            });
          }
        });
      }
    });
  }

  void _showAskGeminiSheet() {
    final askController = TextEditingController();

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
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.tertiaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome,
                        size: 18, color: AppColors.tertiaryContainer),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Ask Gemini 1.5 Pro',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ask anything about ${widget.lecture?.title ?? "this lecture"} or request custom code walk-throughs:',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: askController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g. Can you explain why double rotation (LR) requires two pivots instead of one?',
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Gemini: "In LR rotation, the inner grandchild C is rotated up first before parent A..."'),
                      backgroundColor: AppColors.royalBlue,
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Send Question to Gemini'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subject ?? MockData.subjects[3]; // CS202 by default
    final lecture = widget.lecture ?? MockData.lectures[0];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Note Detail View',
        subtitle: null,
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Top Navigation & Action Context Bar
              _buildTopContextBar(sub),
              const SizedBox(height: 12),

              // Lecture Title & Key Metadata
              _buildLectureTitleSection(lecture),
              const SizedBox(height: 16),

              // Mini Lecture Audio Player Bar
              _buildMiniAudioPlayer(),
              const SizedBox(height: 16),

              // Section 1: Quick Summary Card (Gemini 1.5 Pro)
              _buildQuickSummaryCard(),
              const SizedBox(height: 16),

              // Captured Blackboard Slide Diagram Card
              _buildBlackboardSlideCard(),
              const SizedBox(height: 16),

              // Section 2: Step-by-Step Easy Explanation Card
              _buildStepByStepCard(),
              const SizedBox(height: 16),

              // Section 3: Exam Prep Q&A (Collapsible study cards)
              _buildExamQaSection(),
              const SizedBox(height: 16),

              // Additional Interactive Tool: AI Ask Assistant
              _buildAiAssistantCard(),
              const SizedBox(height: 20),
            ],
          ),

          // Bottom Fixed Academic Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(sub),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContextBar(SubjectData sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.school, size: 16, color: AppColors.tertiary),
            const SizedBox(width: 6),
            Text(
              '${sub.code}: ${sub.name}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sharing lecture link with classmates...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_outlined,
                    size: 18, color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() => _isBookmarked = !_isBookmarked);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isBookmarked
                        ? 'Lecture saved to Bookmarks'
                        : 'Bookmark removed'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: 18,
                  color: _isBookmarked
                      ? AppColors.royalBlue
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLectureTitleSection(LectureItemData lecture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.royalBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                lecture.lectureNumber.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lecture.title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildMetaBadge(Icons.person_outline, 'Prof. Vance'),
            _buildMetaBadge(Icons.calendar_today_outlined, lecture.date),
            _buildMetaBadge(
              Icons.mic,
              '${lecture.duration} Audio',
              iconColor: AppColors.tertiary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaBadge(IconData icon, String text, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081E293B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Playback Scrubber Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentTime,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.royalBlue,
                ),
              ),
              Text(
                _totalTime,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scrubber Bar
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final width = box.size.width - 64;
                final progress =
                    (details.localPosition.dx / width).clamp(0.0, 1.0);
                final targetSeconds = (_duration.inSeconds * progress).toInt();
                _seekToDuration(Duration(seconds: targetSeconds));
              }
            },
            child: Container(
              height: 18,
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _scrubberProgress,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(-1.0 + (_scrubberProgress * 2.0), 0),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.royalBlue, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Controls & Speed Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      final newSecs =
                          (_position.inSeconds - 10).clamp(0, _duration.inSeconds);
                      _seekToDuration(Duration(seconds: newSecs));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.replay_10,
                          size: 18, color: AppColors.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _togglePlayPause,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.royalBlue.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final newSecs =
                          (_position.inSeconds + 10).clamp(0, _duration.inSeconds);
                      _seekToDuration(Duration(seconds: newSecs));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forward_10,
                          size: 18, color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
              // Playback Speed Chips
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  children: ['1x', '1.25x', '1.5x', '2x'].map((speed) {
                    final isSelected = _selectedSpeed == speed;
                    return InkWell(
                      onTap: () => _setSpeed(speed),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.lightBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          speed,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.royalBlue
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06004AAD),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Warm Gold Corner Glow
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiaryFixed.withOpacity(0.4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                            'Gemini 1.5 Pro Summary',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.bolt,
                            size: 13, color: AppColors.tertiaryContainer),
                        SizedBox(width: 2),
                        Text(
                          'Instant Recall',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Quick 3-Sentence Takeaway',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSecondaryFixed,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _data.summary,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.onSecondaryFixedVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 15, color: AppColors.tertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'High Exam Probability: '),
                            TextSpan(
                              text: _data.highExamProbability,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.onSecondaryFixed,
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

  Widget _buildBlackboardSlideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(18),
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
              const Text(
                'CAPTURED BLACKBOARD SLIDE (00:44:12)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.outline,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search,
                        size: 11, color: AppColors.tertiaryContainer),
                    SizedBox(width: 3),
                    Text(
                      'OCR Synced',
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
            ],
          ),
          const SizedBox(height: 12),
          // Blackboard Illustration Container
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Container(
                  height: 170,
                  width: double.infinity,
                  color: const Color(0xFF1E2822),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _data.blackboardSlideText ??
                                'AVL Tree: Transforming Unbalanced BST',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE2E8F0),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildChalkNode('A (BF=+2)', Colors.amberAccent),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward,
                                  color: Colors.white70, size: 16),
                            ),
                            _buildChalkNode(
                                'C (BF=0)', Colors.lightGreenAccent),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Left-Right Rotation: Left on B, Right on A',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.timer_outlined,
                            size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Slide timestamp: 44m 12s',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChalkNode(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStepByStepCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(18),
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
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Step-by-Step Breakdown',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '${_data.milestones.length} Core Milestones',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ..._data.milestones.map((milestone) {
            final isFirst = milestone == _data.milestones.first;
            final isSecond = _data.milestones.length > 1 &&
                milestone == _data.milestones[1];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMilestoneContainer(
                title: milestone.title,
                badge: milestone.badge,
                badgeBg: isFirst
                    ? AppColors.tertiaryFixedDim
                    : isSecond
                        ? AppColors.secondaryFixed
                        : AppColors.tertiaryFixed,
                badgeColor: isSecond
                    ? AppColors.onSecondaryFixed
                    : AppColors.onTertiaryFixed,
                description: milestone.description,
                codeBlock: milestone.codeBlock,
                formulaBlock: milestone.formulaBlock,
                bottomNote: milestone.bottomNote,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMilestoneContainer({
    required String title,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required String description,
    String? codeBlock,
    String? formulaBlock,
    String? bottomNote,
  }) {
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (codeBlock != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                codeBlock,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.onSurface,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (formulaBlock != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  formulaBlock,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ),
          ],
          if (bottomNote != null) ...[
            const SizedBox(height: 6),
            Text(
              bottomNote,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExamQaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(18),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Exam Prep Q&A',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Frequently tested concepts highlighted by Gemini',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  size: 18,
                  color: AppColors.tertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...List.generate(_data.qa.length, (index) {
            final qa = _data.qa[index];
            final isExpanded = index < _expandedQuestions.length
                ? _expandedQuestions[index]
                : false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (index < _expandedQuestions.length) {
                            _expandedQuestions[index] =
                                !_expandedQuestions[index];
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                qa.question,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                              color: AppColors.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              qa.answer,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    qa.solutionOrTakeaway,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.tertiaryContainer,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    final d = _parseTimestamp(qa.replayTimestamp);
                                    _seekToDuration(d);
                                  },
                                  borderRadius: BorderRadius.circular(9999),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryFixed,
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.play_circle_outline,
                                            size: 13,
                                            color: AppColors.onSecondaryFixed),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Replay at ${qa.replayTimestamp}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSecondaryFixed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.tertiaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.psychology,
                  color: AppColors.tertiaryContainer, size: 22),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Still confused about a specific rotation?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gemini can generate custom dry-run walk-throughs for any arbitrary tree input.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showAskGeminiSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceLowest,
              foregroundColor: AppColors.royalBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline,
                size: 16, color: AppColors.tertiary),
            label: const Text(
              'Ask Gemini follow-up question',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(SubjectData sub) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: Color(0x0A000000),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Save to Subject Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isSavedToSubject = !_isSavedToSubject);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isSavedToSubject
                            ? 'Saved to ${sub.code}'
                            : 'Removed from ${sub.code}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceHigh,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _isSavedToSubject ? Icons.check : Icons.add,
                    size: 18,
                    color: AppColors.royalBlue,
                  ),
                  label: Text(
                    _isSavedToSubject ? 'Saved to ${sub.code}' : 'Save to Subject',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Export as PDF Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download,
                          size: 18, color: Colors.white),
                  label: Text(
                    _exportButtonText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
