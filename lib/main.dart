import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_semesters_screen.dart';
import 'screens/semester_subjects_screen.dart';
import 'screens/subject_workspace_screen.dart';
import 'screens/recorder_screen.dart';
import 'screens/gemini_explanation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFAFAEF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const UniNotesApp());
}

class UniNotesApp extends StatelessWidget {
  const UniNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniNotes AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeSemestersScreen(),
        '/subjects': (context) => const SemesterSubjectsScreen(),
        '/workspace': (context) => const SubjectWorkspaceScreen(),
        '/recorder': (context) => const RecorderScreen(),
        '/explanation': (context) => const GeminiExplanationScreen(),
      },
    );
  }
}

