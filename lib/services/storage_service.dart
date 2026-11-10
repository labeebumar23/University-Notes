import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _keySemesters = 'uninotes_semesters_v1';
  static const String _keySubjects = 'uninotes_subjects_v1';
  static const String _keyPdfsPrefix = 'uninotes_pdfs_v1_';
  static const String _keyLecturesPrefix = 'uninotes_lectures_v1_';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ================= SEMESTERS =================

  /// Retrieves all semesters. If empty, seeds with initial MockData.
  Future<List<SemesterData>> getSemesters() async {
    final prefs = await _getPrefs();
    final rawString = prefs.getString(_keySemesters);

    if (rawString == null || rawString.isEmpty) {
      // Seed with default initial data
      final initialList = MockData.semesters;
      await saveSemesters(initialList);
      return initialList;
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawString) as List<dynamic>;
      return decoded
          .map((item) => SemesterData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return MockData.semesters;
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

  // ================= SUBJECTS =================

  /// Retrieves subjects for a semester (or all subjects).
  Future<List<SubjectData>> getSubjects({String? semesterId}) async {
    final prefs = await _getPrefs();
    final rawString = prefs.getString(_keySubjects);

    List<SubjectData> allSubjects;
    if (rawString == null || rawString.isEmpty) {
      allSubjects = MockData.subjects;
      await saveSubjects(allSubjects);
    } else {
      try {
        final List<dynamic> decoded = jsonDecode(rawString) as List<dynamic>;
        allSubjects = decoded
            .map((item) => SubjectData.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        allSubjects = MockData.subjects;
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

  /// Adds a new subject to permanent storage.
  Future<void> addSubject(SubjectData subject) async {
    final list = await getSubjects();
    list.add(subject);
    await saveSubjects(list);
  }

  // ================= PDF NOTES =================

  /// Retrieves all PDFs for a specific subject (e.g. 'CS202').
  Future<List<PdfItemData>> getPdfsForSubject(String subjectCode) async {
    final prefs = await _getPrefs();
    final key = '$_keyPdfsPrefix$subjectCode';
    final rawString = prefs.getString(key);

    if (rawString == null || rawString.isEmpty) {
      // If CS202, seed with initial mock PDFs
      if (subjectCode == 'CS202') {
        final initialPdfs = MockData.pdfs;
        await _savePdfsForSubject(subjectCode, initialPdfs);
        return initialPdfs;
      }
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
    // Add to top of list
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

  /// Updates an existing PDF in the subject (e.g. backup status).
  Future<void> updatePdfInSubject(String subjectCode, PdfItemData updatedPdf) async {
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

  // ================= AI LECTURES =================

  /// Retrieves all AI lectures for a specific subject (e.g. 'CS202').
  Future<List<LectureItemData>> getLecturesForSubject(String subjectCode) async {
    final prefs = await _getPrefs();
    final key = '$_keyLecturesPrefix$subjectCode';
    final rawString = prefs.getString(key);

    if (rawString == null || rawString.isEmpty) {
      if (subjectCode == 'CS202') {
        final initialLectures = MockData.lectures;
        await _saveLecturesForSubject(subjectCode, initialLectures);
        return initialLectures;
      }
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

  /// Adds a new AI Lecture and updates subject's aiNotesCount.
  Future<void> addLectureToSubject(
      String subjectCode, LectureItemData lecture) async {
    final lectures = await getLecturesForSubject(subjectCode);
    lectures.insert(0, lecture);
    await _saveLecturesForSubject(subjectCode, lectures);

    // Update subject's aiNotesCount
    final subjects = await getSubjects();
    final updatedSubjects = subjects.map((s) {
      if (s.code.toUpperCase() == subjectCode.toUpperCase()) {
        return s.copyWith(
          aiNotesCount: lectures.length,
          recentStatus: '${lecture.title} processed by Gemini',
        );
      }
      return s;
    }).toList();
    await saveSubjects(updatedSubjects);
  }

  /// Updates an existing AI Lecture in the subject (e.g. backup status).
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
}

