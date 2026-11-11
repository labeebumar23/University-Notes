import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Retrieves the saved user's name. Returns null if not onboarded.
  Future<String?> getUserName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyUserName);
  }

  /// Sets the user's name upon onboarding or profile update.
  Future<void> setUserName(String name) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyUserName, name.trim());
  }

  /// Retrieves the user's major/degree (e.g. 'Computer Science B.S.').
  Future<String?> getUserMajor() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyUserMajor) ?? 'Computer Science B.S.';
  }

  /// Sets the user's major/degree.
  Future<void> setUserMajor(String major) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyUserMajor, major.trim());
  }

  /// Checks if the user has completed onboarding.
  Future<bool> isOnboarded() async {
    final name = await getUserName();
    return name != null && name.isNotEmpty;
  }

  // ================= SEMESTERS =================

  /// Retrieves all semesters. Starts 100% empty with no dummy data.
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

  /// Persists the list of semesters to local storage.
  Future<void> saveSemesters(List<SemesterData> semesters) async {
    final prefs = await _getPrefs();
    final encoded = jsonEncode(semesters.map((s) => s.toJson()).toList());
    await prefs.setString(_keySemesters, encoded);
  }

  /// Appends a new semester and saves permanently.
  Future<void> addSemester(SemesterData semester) async {
    final list = await getSemesters();
    list.add(semester);
    await saveSemesters(list);
  }

  /// Deletes a semester and all associated subjects/files.
  Future<void> deleteSemester(String semesterId) async {
    final list = await getSemesters();
    list.removeWhere((s) => s.id == semesterId);
    await saveSemesters(list);

    // Also delete associated subjects
    final subjects = await getSubjects();
    final toRemove = subjects.where((s) => s.semesterId == semesterId).toList();
    for (final sub in toRemove) {
      await deleteSubject(sub.code);
    }
  }

  // ================= SUBJECTS =================

  /// Retrieves subjects for a semester (or all subjects).
  /// Starts 100% empty with no pre-seeded mock data.
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

  /// Persists subjects list to local storage.
  Future<void> saveSubjects(List<SubjectData> subjects) async {
    final prefs = await _getPrefs();
    final encoded = jsonEncode(subjects.map((s) => s.toJson()).toList());
    await prefs.setString(_keySubjects, encoded);
  }

  /// Adds a new subject to permanent storage and updates semester subject count.
  Future<void> addSubject(SubjectData subject) async {
    final list = await getSubjects();
    list.add(subject);
    await saveSubjects(list);

    // Update semester subject count
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

  /// Deletes a subject and its PDFs/Lectures.
  Future<void> deleteSubject(String subjectCode) async {
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

    // Clean up PDFs and Lectures for this subject
    final prefs = await _getPrefs();
    await prefs.remove('$_keyPdfsPrefix$subjectCode');
    await prefs.remove('$_keyLecturesPrefix$subjectCode');
  }

  // ================= PDF NOTES =================

  /// Retrieves all PDFs for a specific subject. Starts 100% empty.
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

  /// Adds a newly picked PDF to the subject and updates subject's pdfCount.
  Future<void> addPdfToSubject(String subjectCode, PdfItemData pdf) async {
    final pdfs = await getPdfsForSubject(subjectCode);
    pdfs.insert(0, pdf);
    await _savePdfsForSubject(subjectCode, pdfs);

    // Update subject's pdfCount
    final subjects = await getSubjects();
    final updatedSubjects = subjects.map((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.copyWith(pdfCount: pdfs.length);
      }
      return s;
    }).toList();
    await saveSubjects(updatedSubjects);
  }

  /// Updates an existing PDF in the subject (e.g. cloud backup status).
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

  /// Deletes a PDF from the subject.
  Future<void> deletePdfFromSubject(String subjectCode, String title) async {
    final pdfs = await getPdfsForSubject(subjectCode);
    pdfs.removeWhere((p) => p.title == title);
    await _savePdfsForSubject(subjectCode, pdfs);

    // Update subject's pdfCount
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

  /// Retrieves all Audio Lectures for a specific subject. Starts 100% empty.
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

  /// Adds a new Audio Lecture and updates subject's aiNotesCount/recentStatus.
  Future<void> addLectureToSubject(
      String subjectCode, LectureItemData lecture) async {
    final lectures = await getLecturesForSubject(subjectCode);
    lectures.insert(0, lecture);
    await _saveLecturesForSubject(subjectCode, lectures);

    // Update subject's lecture count
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

  /// Updates an existing Audio Lecture (e.g. backup status).
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

  /// Deletes an Audio Lecture and its local audio file.
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

    // Update subject's lecture count
    final subjects = await getSubjects();
    final updatedSubjects = subjects.map((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.copyWith(aiNotesCount: lectures.length);
      }
      return s;
    }).toList();
    await saveSubjects(updatedSubjects);
  }

  /// Clears all local application storage (for fresh resets).
  Future<void> clearAllData() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}
