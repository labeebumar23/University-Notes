import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _keyUserName = 'uninotes_user_name_v1';
  static const String _keyUserMajor = 'uninotes_user_major_v1';
  static const String _keySemesters = 'uninotes_semesters_v1';
  static const String _keySubjects = 'uninotes_subjects_v1';
  static const String _keyPdfsPrefix = 'uninotes_pdfs_v1_';
  static const String _keyLecturesPrefix = 'uninotes_lectures_v1_';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ================= USER PROFILE & ONBOARDING =================

  Future<String?> getUserName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyUserName);
  }

  Future<void> setUserName(String name) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyUserName, name.trim());
  }

  Future<String?> getUserMajor() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyUserMajor) ?? 'Computer Science B.S.';
  }

  Future<void> setUserMajor(String major) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyUserMajor, major.trim());
  }

  Future<bool> isOnboarded() async {
    final name = await getUserName();
    return name != null && name.isNotEmpty;
  }

  // ================= SEMESTERS CRUD =================

  /// C - Create Semester
  Future<void> addSemester(SemesterData semester) async {
    final list = await getSemesters();
    list.add(semester);
    await saveSemesters(list);
  }

  /// R - Read Semesters (Starts 100% empty)
  Future<List<SemesterData>> getSemesters() async {
    final prefs = await _getPrefs();
    final rawString = prefs.getString(_keySemesters);

    if (rawString == null || rawString.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawString) as List<dynamic>;
      return decoded
          .map((item) => SemesterData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists semesters list
  Future<void> saveSemesters(List<SemesterData> semesters) async {
    final prefs = await _getPrefs();
    final encoded = jsonEncode(semesters.map((s) => s.toJson()).toList());
    await prefs.setString(_keySemesters, encoded);
  }

  /// U - Update Semester
  Future<void> updateSemester(SemesterData updatedSemester) async {
    final list = await getSemesters();
    final index = list.indexWhere((s) => s.id == updatedSemester.id);
    if (index != -1) {
      list[index] = updatedSemester;
      await saveSemesters(list);
    }
  }

  /// D - Delete Semester and all nested subjects/files
  Future<void> deleteSemester(String semesterId) async {
    final list = await getSemesters();
    list.removeWhere((s) => s.id == semesterId);
    await saveSemesters(list);

    // Cascade delete associated subjects and files
    final subjects = await getSubjects();
    final toRemove = subjects.where((s) => s.semesterId == semesterId).toList();
    for (final sub in toRemove) {
      await deleteSubject(sub.code);
    }
  }

  // ================= SUBJECTS / COURSES CRUD =================

  /// C - Create Subject
  Future<void> addSubject(SubjectData subject) async {
    final list = await getSubjects();
    list.add(subject);
    await saveSubjects(list);

    // Update parent semester preview and count
    final semesters = await getSemesters();
    final updatedSemesters = semesters.map((sem) {
      if (sem.id == subject.semesterId) {
        final subCount = list.where((s) => s.semesterId == sem.id).length;
        final previewNames = list
            .where((s) => s.semesterId == sem.id)
            .map((s) => '${s.code} ${s.name}')
            .take(3)
            .toList();
        return sem.copyWith(
          subjectCount: subCount,
          subjectsPreview: previewNames,
        );
      }
      return sem;
    }).toList();
    await saveSemesters(updatedSemesters);
  }

  /// R - Read Subjects for a semester (or all)
  Future<List<SubjectData>> getSubjects({String? semesterId}) async {
    final prefs = await _getPrefs();
    final rawString = prefs.getString(_keySubjects);

    List<SubjectData> allSubjects = [];
    if (rawString != null && rawString.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rawString) as List<dynamic>;
        allSubjects = decoded
            .map((item) => SubjectData.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        allSubjects = [];
      }
    }

    if (semesterId != null && semesterId.isNotEmpty) {
      return allSubjects.where((s) => s.semesterId == semesterId).toList();
    }
    return allSubjects;
  }

  /// Persists subjects list
  Future<void> saveSubjects(List<SubjectData> subjects) async {
    final prefs = await _getPrefs();
    final encoded = jsonEncode(subjects.map((s) => s.toJson()).toList());
    await prefs.setString(_keySubjects, encoded);
  }

  /// U - Update Subject
  Future<void> updateSubject(SubjectData updatedSubject) async {
    final list = await getSubjects();
    final index = list.indexWhere((s) => s.code.toUpperCase() == updatedSubject.code.toUpperCase());
    if (index != -1) {
      list[index] = updatedSubject;
      await saveSubjects(list);

      // Refresh semester preview
      final semId = updatedSubject.semesterId;
      final remainingForSem = list.where((s) => s.semesterId == semId).toList();
      final semesters = await getSemesters();
      final updatedSemesters = semesters.map((sem) {
        if (sem.id == semId) {
          return sem.copyWith(
            subjectCount: remainingForSem.length,
            subjectsPreview: remainingForSem
                .map((s) => '${s.code} ${s.name}')
                .take(3)
                .toList(),
          );
        }
        return sem;
      }).toList();
      await saveSemesters(updatedSemesters);
    }
  }

  /// D - Delete Subject, along with all its PDFs and audio files on disk
  Future<void> deleteSubject(String subjectCode) async {
    // Delete all physical PDFs for this subject
    final pdfs = await getPdfsForSubject(subjectCode);
    for (final p in pdfs) {
      if (p.filePath != null && p.filePath!.isNotEmpty) {
        try {
          final f = File(p.filePath!);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
    }

    // Delete all physical Audio Lectures for this subject
    final lectures = await getLecturesForSubject(subjectCode);
    for (final l in lectures) {
      if (l.audioFilePath != null && l.audioFilePath!.isNotEmpty) {
        try {
          final f = File(l.audioFilePath!);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
    }

    final list = await getSubjects();
    SubjectData? removedSubject;
    list.removeWhere((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        removedSubject = s;
        return true;
      }
      return false;
    });
    await saveSubjects(list);

    // Update parent semester if available
    if (removedSubject != null) {
      final semId = removedSubject!.semesterId;
      final remainingForSem = list.where((s) => s.semesterId == semId).toList();
      final semesters = await getSemesters();
      final updatedSemesters = semesters.map((sem) {
        if (sem.id == semId) {
          return sem.copyWith(
            subjectCount: remainingForSem.length,
            subjectsPreview: remainingForSem
                .map((s) => '${s.code} ${s.name}')
                .take(3)
                .toList(),
          );
        }
        return sem;
      }).toList();
      await saveSemesters(updatedSemesters);
    }

    final prefs = await _getPrefs();
    await prefs.remove('$_keyPdfsPrefix$subjectCode');
    await prefs.remove('$_keyLecturesPrefix$subjectCode');
  }

  // ================= PDF NOTES =================

  Future<List<PdfItemData>> getPdfsForSubject(String subjectCode) async {
    final prefs = await _getPrefs();
    final key = '$_keyPdfsPrefix$subjectCode';
    final rawString = prefs.getString(key);

    if (rawString == null || rawString.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawString) as List<dynamic>;
      return decoded
          .map((item) => PdfItemData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePdfsForSubject(
      String subjectCode, List<PdfItemData> pdfs) async {
    final prefs = await _getPrefs();
    final key = '$_keyPdfsPrefix$subjectCode';
    final encoded = jsonEncode(pdfs.map((p) => p.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  Future<void> addPdfToSubject(String subjectCode, PdfItemData pdf) async {
    final pdfs = await getPdfsForSubject(subjectCode);
    pdfs.insert(0, pdf);
    await _savePdfsForSubject(subjectCode, pdfs);

    final subjects = await getSubjects();
    final updatedSubjects = subjects.map((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.copyWith(pdfCount: pdfs.length);
      }
      return s;
    }).toList();
    await saveSubjects(updatedSubjects);
  }

  Future<void> updatePdfInSubject(
      String subjectCode, PdfItemData updatedPdf) async {
    final pdfs = await getPdfsForSubject(subjectCode);
    final index = pdfs.indexWhere((p) => p.title == updatedPdf.title);
    if (index != -1) {
      pdfs[index] = updatedPdf;
    } else {
      pdfs.insert(0, updatedPdf);
    }
    await _savePdfsForSubject(subjectCode, pdfs);
  }

  Future<void> deletePdfFromSubject(String subjectCode, String title) async {
    final pdfs = await getPdfsForSubject(subjectCode);
    final toDelete = pdfs.where((p) => p.title == title).toList();
    for (final p in toDelete) {
      if (p.filePath != null && p.filePath!.isNotEmpty) {
        try {
          final f = File(p.filePath!);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
    }

    pdfs.removeWhere((p) => p.title == title);
    await _savePdfsForSubject(subjectCode, pdfs);

    final subjects = await getSubjects();
    final updatedSubjects = subjects.map((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.copyWith(pdfCount: pdfs.length);
      }
      return s;
    }).toList();
    await saveSubjects(updatedSubjects);
  }

  // ================= AUDIO LECTURES =================

  Future<List<LectureItemData>> getLecturesForSubject(String subjectCode) async {
    final prefs = await _getPrefs();
    final key = '$_keyLecturesPrefix$subjectCode';
    final rawString = prefs.getString(key);

    if (rawString == null || rawString.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawString) as List<dynamic>;
      return decoded
          .map((item) => LectureItemData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLecturesForSubject(
      String subjectCode, List<LectureItemData> lectures) async {
    final prefs = await _getPrefs();
    final key = '$_keyLecturesPrefix$subjectCode';
    final encoded = jsonEncode(lectures.map((l) => l.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  Future<void> addLectureToSubject(
      String subjectCode, LectureItemData lecture) async {
    final lectures = await getLecturesForSubject(subjectCode);
    lectures.insert(0, lecture);
    await _saveLecturesForSubject(subjectCode, lectures);

    final subjects = await getSubjects();
    final updatedSubjects = subjects.map((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.copyWith(
          aiNotesCount: lectures.length,
          recentStatus: 'Recorded ${lecture.title}',
        );
      }
      return s;
    }).toList();
    await saveSubjects(updatedSubjects);
  }

  Future<void> updateLectureInSubject(
      String subjectCode, LectureItemData updatedLecture) async {
    final lectures = await getLecturesForSubject(subjectCode);
    final index = lectures.indexWhere((l) => l.id == updatedLecture.id);
    if (index != -1) {
      lectures[index] = updatedLecture;
    } else {
      lectures.insert(0, updatedLecture);
    }
    await _saveLecturesForSubject(subjectCode, lectures);
  }

  Future<void> deleteLectureFromSubject(
      String subjectCode, String lectureId) async {
    final lectures = await getLecturesForSubject(subjectCode);
    final toDelete = lectures.where((l) => l.id == lectureId).toList();
    for (final lec in toDelete) {
      if (lec.audioFilePath != null && lec.audioFilePath!.isNotEmpty) {
        try {
          final file = File(lec.audioFilePath!);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {}
      }
    }

    lectures.removeWhere((l) => l.id == lectureId);
    await _saveLecturesForSubject(subjectCode, lectures);

    final subjects = await getSubjects();
    final updatedSubjects = subjects.map((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.copyWith(aiNotesCount: lectures.length);
      }
      return s;
    }).toList();
    await saveSubjects(updatedSubjects);
  }

  // ================= STORAGE USAGE & FACTORY RESET =================

  /// Calculates actual on-device disk space consumed by PDFs and Audio Recordings.
  Future<Map<String, int>> getStorageUsageBytes() async {
    int pdfBytes = 0;
    int lectureBytes = 0;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      
      final pdfDir = Directory('${docDir.path}/pdfs');
      if (pdfDir.existsSync()) {
        for (final file in pdfDir.listSync(recursive: true)) {
          if (file is File) {
            pdfBytes += file.lengthSync();
          }
        }
      }

      final lecturesDir = Directory('${docDir.path}/lectures');
      if (lecturesDir.existsSync()) {
        for (final file in lecturesDir.listSync(recursive: true)) {
          if (file is File) {
            lectureBytes += file.lengthSync();
          }
        }
      }
    } catch (_) {}

    return {
      'pdfs': pdfBytes,
      'lectures': lectureBytes,
      'total': pdfBytes + lectureBytes,
    };
  }

  /// Clears all local application storage and deletes all files on disk (Factory Reset).
  Future<void> clearAllData() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${docDir.path}/pdfs');
      if (pdfDir.existsSync()) {
        pdfDir.deleteSync(recursive: true);
      }
      final lecturesDir = Directory('${docDir.path}/lectures');
      if (lecturesDir.existsSync()) {
        lecturesDir.deleteSync(recursive: true);
      }
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        for (final item in cacheDir.listSync()) {
          try {
            item.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}

    final prefs = await _getPrefs();
    await prefs.clear();
  }

  // ================= THEME PERSISTENCE =================
  static const String _keyThemeMode = 'app_theme_mode';

  Future<ThemeMode> getThemeMode() async {
    final prefs = await _getPrefs();
    final modeStr = prefs.getString(_keyThemeMode);
    if (modeStr == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  // ================= QUICK NOTES =================
  static const String _prefixQuickNotes = 'quick_notes_';

  Future<String> getQuickNotes(String subjectCode) async {
    final prefs = await _getPrefs();
    final notes = prefs.getString('$_prefixQuickNotes${subjectCode.toUpperCase()}');
    if (notes != null && notes.isNotEmpty) return notes;
    final subjects = await getSubjects();
    for (final s in subjects) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.quickNotes;
      }
    }
    return '';
  }

  Future<void> saveQuickNotes(String subjectCode, String notes) async {
    final prefs = await _getPrefs();
    await prefs.setString('$_prefixQuickNotes${subjectCode.toUpperCase()}', notes);

    final subjects = await getSubjects();
    final updated = subjects.map((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.copyWith(quickNotes: notes);
      }
      return s;
    }).toList();
    await saveSubjects(updated);
  }

  // ================= ATTENDANCE TRACKER =================
  Future<void> updateAttendance(String subjectCode, int attended, int total) async {
    final subjects = await getSubjects();
    final updated = subjects.map((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.copyWith(
          classesAttended: attended < 0 ? 0 : attended,
          totalClasses: total < 0 ? 0 : total,
        );
      }
      return s;
    }).toList();
    await saveSubjects(updated);
  }

  // ================= SGPA CALCULATOR =================
  Future<void> saveSemesterSgpa(String semesterId, double sgpa) async {
    final semesters = await getSemesters();
    final updated = semesters.map((sem) {
      if (sem.id == semesterId) {
        return sem.copyWith(
          sgpa: sgpa,
          gpa: sgpa.toStringAsFixed(2),
        );
      }
      return sem;
    }).toList();
    await saveSemesters(updated);
  }

  /// Cleans only temporary cache files, keeping offline PDFs and audio recordings intact.
  Future<void> clearCacheOnly() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        for (final item in cacheDir.listSync()) {
          try {
            item.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
