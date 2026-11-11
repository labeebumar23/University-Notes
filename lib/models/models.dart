import 'package:flutter/material.dart';

class SemesterData {
  final String id;
  final String title;
  final String status;
  final String term;
  final List<String> subjectsPreview;
  final double? syllabusCompletion;
  final int subjectCount;
  final int fileCount;
  final String fileLabel;
  final bool isLiveSynced;
  final String? gpa;
  final double? sgpa;
  final IconData icon;
  final bool isCurrent;
  final Color? iconBgColor;
  final Color? iconColor;

  const SemesterData({
    required this.id,
    required this.title,
    required this.status,
    required this.term,
    required this.subjectsPreview,
    this.syllabusCompletion,
    required this.subjectCount,
    required this.fileCount,
    required this.fileLabel,
    this.isLiveSynced = false,
    this.gpa,
    this.sgpa,
    required this.icon,
    this.isCurrent = false,
    this.iconBgColor,
    this.iconColor,
  });

  SemesterData copyWith({
    String? id,
    String? title,
    String? status,
    String? term,
    List<String>? subjectsPreview,
    double? syllabusCompletion,
    int? subjectCount,
    int? fileCount,
    String? fileLabel,
    bool? isLiveSynced,
    String? gpa,
    double? sgpa,
    IconData? icon,
    bool? isCurrent,
    Color? iconBgColor,
    Color? iconColor,
  }) {
    return SemesterData(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      term: term ?? this.term,
      subjectsPreview: subjectsPreview ?? this.subjectsPreview,
      syllabusCompletion: syllabusCompletion ?? this.syllabusCompletion,
      subjectCount: subjectCount ?? this.subjectCount,
      fileCount: fileCount ?? this.fileCount,
      fileLabel: fileLabel ?? this.fileLabel,
      isLiveSynced: isLiveSynced ?? this.isLiveSynced,
      gpa: gpa ?? this.gpa,
      sgpa: sgpa ?? this.sgpa,
      icon: icon ?? this.icon,
      isCurrent: isCurrent ?? this.isCurrent,
      iconBgColor: iconBgColor ?? this.iconBgColor,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'term': term,
      'subjectsPreview': subjectsPreview,
      'syllabusCompletion': syllabusCompletion,
      'subjectCount': subjectCount,
      'fileCount': fileCount,
      'fileLabel': fileLabel,
      'isLiveSynced': isLiveSynced,
      'gpa': gpa,
      'sgpa': sgpa,
      'iconCodePoint': icon.codePoint,
      'isCurrent': isCurrent,
      'iconBgColor': iconBgColor?.value,
      'iconColor': iconColor?.value,
    };
  }

  factory SemesterData.fromJson(Map<String, dynamic> json) {
    return SemesterData(
      id: json['id'] as String? ?? 'sem-3',
      title: json['title'] as String? ?? 'Semester',
      status: json['status'] as String? ?? 'In Progress',
      term: json['term'] as String? ?? '',
      subjectsPreview: (json['subjectsPreview'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      syllabusCompletion: (json['syllabusCompletion'] as num?)?.toDouble(),
      subjectCount: json['subjectCount'] as int? ?? 0,
      fileCount: json['fileCount'] as int? ?? 0,
      fileLabel: json['fileLabel'] as String? ?? 'Files',
      isLiveSynced: json['isLiveSynced'] as bool? ?? false,
      gpa: json['gpa'] as String?,
      sgpa: (json['sgpa'] as num?)?.toDouble() ??
          (json['gpa'] != null ? double.tryParse(json['gpa'].toString()) : null),
      icon: IconData(
        json['iconCodePoint'] as int? ?? Icons.school.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      isCurrent: json['isCurrent'] as bool? ?? false,
      iconBgColor: json['iconBgColor'] != null
          ? Color(json['iconBgColor'] as int)
          : null,
      iconColor: json['iconColor'] != null
          ? Color(json['iconColor'] as int)
          : null,
    );
  }
}

class SubjectData {
  final String code;
  final String name;
  final String professor;
  final String schedule;
  final int pdfCount;
  final int aiNotesCount;
  final String recentStatus;
  final IconData recentStatusIcon;
  final String? badge;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool hasPulse;
  final String category; // 'all', 'active', 'ai'
  final String semesterId;
  final int classesAttended;
  final int totalClasses;
  final String quickNotes;
  final int creditHours;
  final String? grade;

  const SubjectData({
    required this.code,
    required this.name,
    required this.professor,
    required this.schedule,
    required this.pdfCount,
    required this.aiNotesCount,
    required this.recentStatus,
    required this.recentStatusIcon,
    this.badge,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.hasPulse = false,
    this.category = 'all',
    this.semesterId = 'sem-3',
    this.classesAttended = 0,
    this.totalClasses = 0,
    this.quickNotes = '',
    this.creditHours = 3,
    this.grade,
  });

  SubjectData copyWith({
    String? code,
    String? name,
    String? professor,
    String? schedule,
    int? pdfCount,
    int? aiNotesCount,
    String? recentStatus,
    IconData? recentStatusIcon,
    String? badge,
    IconData? icon,
    Color? iconBg,
    Color? iconColor,
    bool? hasPulse,
    String? category,
    String? semesterId,
    int? classesAttended,
    int? totalClasses,
    String? quickNotes,
    int? creditHours,
    String? grade,
  }) {
    return SubjectData(
      code: code ?? this.code,
      name: name ?? this.name,
      professor: professor ?? this.professor,
      schedule: schedule ?? this.schedule,
      pdfCount: pdfCount ?? this.pdfCount,
      aiNotesCount: aiNotesCount ?? this.aiNotesCount,
      recentStatus: recentStatus ?? this.recentStatus,
      recentStatusIcon: recentStatusIcon ?? this.recentStatusIcon,
      badge: badge ?? this.badge,
      icon: icon ?? this.icon,
      iconBg: iconBg ?? this.iconBg,
      iconColor: iconColor ?? this.iconColor,
      hasPulse: hasPulse ?? this.hasPulse,
      category: category ?? this.category,
      semesterId: semesterId ?? this.semesterId,
      classesAttended: classesAttended ?? this.classesAttended,
      totalClasses: totalClasses ?? this.totalClasses,
      quickNotes: quickNotes ?? this.quickNotes,
      creditHours: creditHours ?? this.creditHours,
      grade: grade ?? this.grade,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'professor': professor,
      'schedule': schedule,
      'pdfCount': pdfCount,
      'aiNotesCount': aiNotesCount,
      'recentStatus': recentStatus,
      'recentStatusIconCodePoint': recentStatusIcon.codePoint,
      'badge': badge,
      'iconCodePoint': icon.codePoint,
      'iconBg': iconBg.value,
      'iconColor': iconColor.value,
      'hasPulse': hasPulse,
      'category': category,
      'semesterId': semesterId,
      'classesAttended': classesAttended,
      'totalClasses': totalClasses,
      'quickNotes': quickNotes,
      'creditHours': creditHours,
      'grade': grade,
    };
  }

  factory SubjectData.fromJson(Map<String, dynamic> json) {
    return SubjectData(
      code: json['code'] as String? ?? 'SUBJ',
      name: json['name'] as String? ?? 'Subject',
      professor: json['professor'] as String? ?? '',
      schedule: json['schedule'] as String? ?? '',
      pdfCount: json['pdfCount'] as int? ?? 0,
      aiNotesCount: json['aiNotesCount'] as int? ?? 0,
      recentStatus: json['recentStatus'] as String? ?? 'Ready',
      recentStatusIcon: IconData(
        json['recentStatusIconCodePoint'] as int? ?? Icons.history.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      badge: json['badge'] as String?,
      icon: IconData(
        json['iconCodePoint'] as int? ?? Icons.school.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      iconBg: Color(json['iconBg'] as int? ?? 0xFFD9E2FF),
      iconColor: Color(json['iconColor'] as int? ?? 0xFF004AAD),
      hasPulse: json['hasPulse'] as bool? ?? false,
      category: json['category'] as String? ?? 'all',
      semesterId: json['semesterId'] as String? ?? 'sem-3',
      classesAttended: json['classesAttended'] as int? ?? 0,
      totalClasses: json['totalClasses'] as int? ?? 0,
      quickNotes: json['quickNotes'] as String? ?? '',
      creditHours: json['creditHours'] as int? ?? 3,
      grade: json['grade'] as String?,
    );
  }
}

class LectureItemData {
  final String id;
  final String lectureNumber;
  final String title;
  final String duration;
  final String date;
  final String summary;
  final String? keyTakeaway;
  final bool isBookmarked;
  final String? flashcardsCount;
  final String? audioFilePath;
  final String? geminiResponseJson;
  final bool isBackedUp;
  final String? driveFileId;

  const LectureItemData({
    required this.id,
    required this.lectureNumber,
    required this.title,
    required this.duration,
    required this.date,
    required this.summary,
    this.keyTakeaway,
    this.isBookmarked = false,
    this.flashcardsCount,
    this.audioFilePath,
    this.geminiResponseJson,
    this.isBackedUp = false,
    this.driveFileId,
  });

  LectureItemData copyWith({
    String? id,
    String? lectureNumber,
    String? title,
    String? duration,
    String? date,
    String? summary,
    String? keyTakeaway,
    bool? isBookmarked,
    String? flashcardsCount,
    String? audioFilePath,
    String? geminiResponseJson,
    bool? isBackedUp,
    String? driveFileId,
  }) {
    return LectureItemData(
      id: id ?? this.id,
      lectureNumber: lectureNumber ?? this.lectureNumber,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      summary: summary ?? this.summary,
      keyTakeaway: keyTakeaway ?? this.keyTakeaway,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      flashcardsCount: flashcardsCount ?? this.flashcardsCount,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      geminiResponseJson: geminiResponseJson ?? this.geminiResponseJson,
      isBackedUp: isBackedUp ?? this.isBackedUp,
      driveFileId: driveFileId ?? this.driveFileId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lectureNumber': lectureNumber,
      'title': title,
      'duration': duration,
      'date': date,
      'summary': summary,
      'keyTakeaway': keyTakeaway,
      'isBookmarked': isBookmarked,
      'flashcardsCount': flashcardsCount,
      'audioFilePath': audioFilePath,
      'geminiResponseJson': geminiResponseJson,
      'isBackedUp': isBackedUp,
      'driveFileId': driveFileId,
    };
  }

  factory LectureItemData.fromJson(Map<String, dynamic> json) {
    return LectureItemData(
      id: json['id'] as String? ?? 'lec-0',
      lectureNumber: json['lectureNumber'] as String? ?? 'Lecture',
      title: json['title'] as String? ?? 'Class Lecture',
      duration: json['duration'] as String? ?? '01:00:00',
      date: json['date'] as String? ?? 'Today',
      summary: json['summary'] as String? ?? '',
      keyTakeaway: json['keyTakeaway'] as String?,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      flashcardsCount: json['flashcardsCount'] as String?,
      audioFilePath: json['audioFilePath'] as String?,
      geminiResponseJson: json['geminiResponseJson'] as String?,
      isBackedUp: json['isBackedUp'] as bool? ?? false,
      driveFileId: json['driveFileId'] as String?,
    );
  }
}

class PdfItemData {
  final String title;
  final String size;
  final String addedDate;
  final String tag;
  final Color tagColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String? filePath;
  final bool isBackedUp;
  final String? driveFileId;

  const PdfItemData({
    required this.title,
    required this.size,
    required this.addedDate,
    required this.tag,
    required this.tagColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.filePath,
    this.isBackedUp = false,
    this.driveFileId,
  });

  PdfItemData copyWith({
    String? title,
    String? size,
    String? addedDate,
    String? tag,
    Color? tagColor,
    IconData? icon,
    Color? iconBg,
    Color? iconColor,
    String? filePath,
    bool? isBackedUp,
    String? driveFileId,
  }) {
    return PdfItemData(
      title: title ?? this.title,
      size: size ?? this.size,
      addedDate: addedDate ?? this.addedDate,
      tag: tag ?? this.tag,
      tagColor: tagColor ?? this.tagColor,
      icon: icon ?? this.icon,
      iconBg: iconBg ?? this.iconBg,
      iconColor: iconColor ?? this.iconColor,
      filePath: filePath ?? this.filePath,
      isBackedUp: isBackedUp ?? this.isBackedUp,
      driveFileId: driveFileId ?? this.driveFileId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'size': size,
      'addedDate': addedDate,
      'tag': tag,
      'tagColor': tagColor.value,
      'iconCodePoint': icon.codePoint,
      'iconBg': iconBg.value,
      'iconColor': iconColor.value,
      'filePath': filePath,
      'isBackedUp': isBackedUp,
      'driveFileId': driveFileId,
    };
  }

  factory PdfItemData.fromJson(Map<String, dynamic> json) {
    return PdfItemData(
      title: json['title'] as String? ?? 'Document.pdf',
      size: json['size'] as String? ?? '1.0 MB',
      addedDate: json['addedDate'] as String? ?? 'Recently',
      tag: json['tag'] as String? ?? 'Uploaded',
      tagColor: Color(json['tagColor'] as int? ?? 0xFF004AAD),
      icon: IconData(
        json['iconCodePoint'] as int? ?? Icons.picture_as_pdf.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      iconBg: Color(json['iconBg'] as int? ?? 0xFFFFDAD6),
      iconColor: Color(json['iconColor'] as int? ?? 0xFFBA1A1A),
      filePath: json['filePath'] as String?,
      isBackedUp: json['isBackedUp'] as bool? ?? false,
      driveFileId: json['driveFileId'] as String?,
    );
  }
}

class ExamQuestionData {
  final String question;
  final String answer;
  final String solutionOrTakeaway;
  final String replayTimestamp;
  final bool isExpandedByDefault;

  const ExamQuestionData({
    required this.question,
    required this.answer,
    required this.solutionOrTakeaway,
    required this.replayTimestamp,
    this.isExpandedByDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'solutionOrTakeaway': solutionOrTakeaway,
      'replayTimestamp': replayTimestamp,
      'isExpandedByDefault': isExpandedByDefault,
    };
  }

  factory ExamQuestionData.fromJson(Map<String, dynamic> json) {
    return ExamQuestionData(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      solutionOrTakeaway: json['solutionOrTakeaway'] as String? ?? '',
      replayTimestamp: json['replayTimestamp'] as String? ?? '00:00:00',
      isExpandedByDefault: json['isExpandedByDefault'] as bool? ?? false,
    );
  }
}

class MilestoneItemData {
  final String title;
  final String badge;
  final String description;
  final String? codeBlock;
  final String? formulaBlock;
  final String? bottomNote;

  const MilestoneItemData({
    required this.title,
    required this.badge,
    required this.description,
    this.codeBlock,
    this.formulaBlock,
    this.bottomNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'badge': badge,
      'description': description,
      'codeBlock': codeBlock,
      'formulaBlock': formulaBlock,
      'bottomNote': bottomNote,
    };
  }

  factory MilestoneItemData.fromJson(Map<String, dynamic> json) {
    return MilestoneItemData(
      title: json['title'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      description: json['description'] as String? ?? '',
      codeBlock: json['codeBlock'] as String?,
      formulaBlock: json['formulaBlock'] as String?,
      bottomNote: json['bottomNote'] as String?,
    );
  }
}

class GeminiExplanationResult {
  final String summary;
  final String highExamProbability;
  final String? blackboardSlideText;
  final List<MilestoneItemData> milestones;
  final List<ExamQuestionData> qa;

  const GeminiExplanationResult({
    required this.summary,
    required this.highExamProbability,
    this.blackboardSlideText,
    required this.milestones,
    required this.qa,
  });

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'highExamProbability': highExamProbability,
      'blackboardSlideText': blackboardSlideText,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'qa': qa.map((q) => q.toJson()).toList(),
    };
  }

  factory GeminiExplanationResult.fromJson(Map<String, dynamic> json) {
    return GeminiExplanationResult(
      summary: json['summary'] as String? ?? '',
      highExamProbability: json['highExamProbability'] as String? ?? '',
      blackboardSlideText: json['blackboardSlideText'] as String?,
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((e) => MilestoneItemData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      qa: (json['qa'] as List<dynamic>?)
              ?.map((e) => ExamQuestionData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
